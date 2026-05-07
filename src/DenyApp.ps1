

function Disable-ExeAccess {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    $AppExe = $Null
    $AppItem = Get-Item $Path -ErrorAction Ignore
    if($AppItem -eq $Null){
        # --- Resolve full command path ---
        $AppCmd = Get-Command -Name "$Path" -ErrorAction Ignore 
        if ($AppCmd -eq $null) {
            throw "Executable was not found by Get-Command. Path: $Path"
        }
        $AppExe = $AppCmd.Path
        $AppItem = Get-Item $AppExe -ErrorAction Ignore
        $Base   = $AppItem.BaseName
    } else {
        $AppExe = $AppItem.FullName
        $Base   = $AppItem.BaseName
    }

    # --- Validate Path ---
    if ([string]::IsNullOrWhiteSpace($AppExe) -or
        -not [System.IO.File]::Exists($AppExe) -or
        (Get-Item -LiteralPath $AppExe).Extension -ne '.exe') {

        throw "Path must exist and be an .exe file."
    }

    # --- Check Administrator ---
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
               [Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Disable-ExeAccess must be run as Administrator."
    }



    # --- Stop Running Processes ---
    $running = Get-Process -Name $Base -ErrorAction SilentlyContinue

    if ($running) {
        Write-Host "Stopping $($running.Count) running process(es) of $Base ..."
        Stop-Process -Name $Base -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "No running processes for $Base"
    }

    # --- Backup ACL ---
    $acl = Get-Acl -LiteralPath $AppExe

    $backup = [PSCustomObject]@{
        Path            = $AppExe
        Timestamp       = (Get-Date)
        SDDL            = $acl.Sddl
        AccessToString  = $acl.AccessToString
    }

    $desktop   = [Environment]::GetFolderPath("Desktop")
    $backupDir = Join-Path $desktop "ExeAccessBackup"

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    $backupFile = Join-Path $backupDir "$Base`_Access.json"
    $backup | ConvertTo-Json -Depth 5 | Out-File -FilePath $backupFile -Encoding UTF8

    Write-Host "Backup saved to: $backupFile"

    # --- Apply Deny Access (Everyone) ---
    $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "Everyone",
                    "ExecuteFile,ReadAndExecute",
                    "Deny"
                )

    $acl.SetAccessRule($denyRule)
    Set-Acl -LiteralPath $AppExe -AclObject $acl

    Write-Host "`nAccess for $AppExe has been restricted (Everyone = Deny Execute)."
}

function Restore-ExeAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # --- Validate Path ---
    if ([string]::IsNullOrWhiteSpace($Path) -or
        -not [System.IO.File]::Exists($Path) -or
        (Get-Item -LiteralPath $Path).Extension -ne '.exe') {

        throw "Path must exist and be an .exe file."
    }

    # --- Check Administrator ---
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
               [Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Restore-ExeAccess must be run as Administrator."
    }

    # --- Determine backup path ---
    $exeItem = Get-Item -LiteralPath $Path
    $base    = $exeItem.BaseName

    $desktop   = [Environment]::GetFolderPath("Desktop")
    $backupDir = Join-Path $desktop "ExeAccessBackup"
    $backupFile = Join-Path $backupDir "$base`_Access.json"

    if (-not (Test-Path -LiteralPath $backupFile)) {
        throw "Backup file not found: $backupFile"
    }

    # --- Load Backup ---
    $backup = Get-Content -LiteralPath $backupFile -Raw | ConvertFrom-Json

    if (-not $backup.SDDL) {
        throw "Backup file is missing required SDDL field."
    }

    # --- Restore ACL ---
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetSecurityDescriptorSddlForm($backup.SDDL)

        Set-Acl -LiteralPath $exeItem.FullName -AclObject $acl

        Write-Host "ACL successfully restored for $($exeItem.FullName)"
    }
    catch {
        throw "Failed to restore ACL: $_"
    }
}