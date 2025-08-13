#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Robocopy.ps1                                                                 ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Write-RoboLog {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Msg,
        [Parameter(Mandatory = $false)]
        [Alias('f', 'Foreground')]
        [string]$Color = "Gray"
    )

    Write-Host "[ROBOCOPY] " -n -f DarkCyan
    Write-Host "$Msg" -f $Color
}

function Add-RobocopyPrivileges {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        if (-not (Invoke-IsAdministrator)) { throw "Backup mode requires Admin privileges to change user rights" }

        if (!("TokenManipulator" -as [type])) {
            Write-Verbose "Registering TokenManipulator"
            Register-TokenManipulator
        } else {
            Write-Verbose "TokenManipulator already registered "
        }

        Write-RoboLog "Enabling Privilege SeBackupPrivilege"
        [void][TokenManipulator]::AddPrivilege("SeBackupPrivilege")

        Write-RoboLog "Enabling Privilege SeRestorePrivilege"
        [void][TokenManipulator]::AddPrivilege("SeRestorePrivilege")

    } catch {
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Remove-RobocopyPrivileges {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        if (-not (Invoke-IsAdministrator)) { throw "Backup mode requires Admin privileges to change user rights" }

        if (!("TokenManipulator" -as [type])) {
            Write-Verbose "Registering TokenManipulator"
            Register-TokenManipulator
        } else {
            Write-Verbose "TokenManipulator already registered "
        }

        Write-RoboLog "Disabling Privilege SeBackupPrivilege"
        [void][TokenManipulator]::RemovePrivilege("SeBackupPrivilege")

        Write-RoboLog "Disabling Privilege SeRestorePrivilege"
        [void][TokenManipulator]::RemovePrivilege("SeRestorePrivilege")

    } catch {
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Invoke-Robocopy {
    <#
    .SYNOPSIS
        Copy a directory to a destination directory using ROBOCOPY.
    .DESCRIPTION
        Backup a directory will copy all te files from the source directory but will not remove missing files
        on a second iteration, like a MIRROR/SYNC would   
    .DESCRIPTION
        Invoke ROBOCOPY to copy files, a wrapper.
    .PARAMETER Source
        Source Directory (drive:\path or \\server\share\path).
    .PARAMETER Destination
        Destination Dir  (drive:\path or \\server\share\path).
    .PARAMETER SyncType 
        One of the following operating procedures:
        'MIR'    ==> MIRror a directory tree (equivalent to /E plus /PURGE), delete dest files/dirs that no longer exist in source.
        'COPY'   ==> It will leave everything in destination, but will add new files fro source, usefull to merge 2 folders
        'NOCOPY' ==> delete dest files/dirs that no longer exist in source. do not copy new, keep same.
        Default  ==> MIRROR
    .PARAMETER Log
        Log File name
    .PARAMETER BackupMode
        copy files in restartable mode.; if access denied use Backup mode.
        Requires Admin privileges to add user rights.        
    .PARAMETER Test
        Simulation: dont copy (like what if, but will call Start-Process)        
    .EXAMPLE 
       Sync-Directories $dst $src -SyncType 'NOCOPY'
       Sync-Directories $src $dst -SyncType 'MIRROR' -Verbose
       Sync-Directories $src $dst -Test
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
                if (-not ($_ | Test-Path)) {
                    throw "File or folder does not exist"
                }
                if (-not ($_ | Test-Path -PathType Container)) {
                    throw "The Path argument must be a Directory. Files paths are not allowed."
                }
                return $true
            })]
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('s', 'src')]
        [string]$Source,
        [Parameter(Mandatory = $true, Position = 1)]
        [Alias('d', 'dst')]
        [string]$Destination,
        [Parameter(Mandatory = $false)]
        [Alias('t', 'type')]
        [ValidateSet('MIRROR', 'COPY', 'NOCOPY')]
        [string]$SyncType,
        [Parameter(Mandatory = $false)]
        [Alias('l')]
        [string]$Log = "",
        [Parameter(Mandatory = $false)]
        [Alias('xf')]
        [String[]]$ExcludedFiles,
        [Parameter(Mandatory = $false)]
        [Alias('xd')]
        [String[]]$ExcludedDirectories,
        [Parameter(Mandatory = $false, HelpMessage = "Num threads in multi-threaded copies with n threads (default 8)")]
        [ValidateRange(1, 128)]
        [int]$Threads = 8,
        [Parameter(Mandatory = $false, HelpMessage = "Retries")]
        [int]$Retries = 1,
        [Parameter(Mandatory = $false, HelpMessage = "WaitOnError seconds")]
        [int]$WaitOnError = 1,
        [Parameter(Mandatory = $false, HelpMessage = "COPY ALL file info (equivalent to /COPY:DATSOU)")]
        [Alias('all')]
        [switch]$CopyAll,
        [Parameter(Mandatory = $false, HelpMessage = "use Backup mode. Privilege SeRestorePrivilege/SeBackupPrivilege")]
        [Alias('b')]
        [switch]$BackupMode,
        [Parameter(Mandatory = $false, HelpMessage = "use restartable mode")]
        [Alias('z')]
        [switch]$Restartable,
        [Parameter(Mandatory = $false, HelpMessage = "list only")]
        [switch]$ListOnly
    )

    try {

        # throw errors on undefined variables
        Set-StrictMode -Version 1

        if ($BackupMode)
        {
            Add-RobocopyPrivileges
        }
        # make sure the given parameters are valid paths

        if (-not (Test-Path $Destination)) {
            if ((ShouldCreateFolder $Destination) -eq $True) {
                New-Item -Path $Destination -ItemType Directory -Force -ErrorAction Ignore | Out-null

                Write-RoboLog "creating $Destination " -f Gray
            } else {
                throw "Destination Path $Destination Non-Existent"
            }
        }
        $Source = Resolve-Path $Source
        $Destination = Resolve-Path $Destination
        $ROBOCOPY = (Get-Command 'robocopy.exe').Source
        Write-RoboLog "start sync '$Source' ==> '$Destination'"

        if ($Log -ne "") {
            New-Item -Path $Log -ItemType File -Force -ErrorAction ignore | Out-Null
        }

        if (-not (Test-Path -Type Container $Source)) { throw "not a container: $Source" }
        if (-not (Test-Path -Type Container $Destination)) { throw "not a container: $Destination" }
        if (-not (Test-Path -Type Leaf $ROBOCOPY)) { throw "cannot find ROBOCOPY: $ROBOCOPY" }


        Write-RoboLog "/MT:$Threads /R:$Retries /W:$WaitOnError"

        $ArgumentList = "$Source $Destination /MT:$Threads /R:$Retries /W:$WaitOnError /BYTES /FP /X"

        if ($PSBoundParameters.ContainsKey('Verbose')) {

            Write-RoboLog "Verbose OUTPUT"
            $ArgumentList += " /V"
        }

        if ($ListOnly) {

            Write-RoboLog "WhatIf : Simulation; List only - don't copy, timestamp or delete any files."
            $ArgumentList += " /L"
        }


        if ($PSBoundParameters.ContainsKey('SyncType')) {
            if ($SyncType -eq 'MIRROR') {
                $ArgumentList += " /MIR" -f "Yellow"
                Write-RoboLog "MIRRORING : FILES WILL BE REMOVED OR ADDED TO BE N SYNC"
            } elseif ($SyncType -eq 'COPY') {
                $ArgumentList += " /COPY:DAT /E"
                Write-RoboLog "COPY ALL file info. copy subdirectories, including Empty ones." -f "Yellow"
            } elseif ($SyncType -eq 'NOCOPY') {
                $ArgumentList += " /PURGE /NOCOPY "
                Write-RoboLog "NOCOPY" -f "Yellow"
            } else {
                throw "INVALID COPY TYPE"
            }

        } else {
            $ArgumentList += " /MIR "
        }

        # Instantiate and start a new stopwatch
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        #  COPY ALL file info (equivalent to /COPY:DATSOU)
        if ($CopyAll) {
            Write-RoboLog "+ COPYALL (DATSOU)"
            $ArgumentList += " /COPYALL"
        }
        if ($BackupMode) {
            Write-RoboLog "+ BackupMode"
            $ArgumentList += " /B"
        }
        if ($Restartable) {
            Write-RoboLog "+ Restartable"
            $ArgumentList += " /Z"
        }
        if ($Log -ne "") {
            Write-RoboLog "+ LOG:$Log"
            $ArgumentList += " /LOG:$Log"
        }
        if (($ExcludedDirectories -ne $Null) -and ($ExcludedDirectories.Count -gt 0)) {
            Write-RoboLog "ExcludedDirectories"
            foreach ($xd in $ExcludedDirectories) {
                $ArgumentList += " /XD $xd"
                Write-RoboLog "  `"$xd`" "
            }
        }
        if (($ExcludedFiles -ne $Null) -and ($ExcludedFiles.Count -gt 0)) {
            Write-RoboLog "ExcludedFiles"
            foreach ($xf in $ExcludedFiles) {
                $ArgumentList += " /XF $xf"
                Write-RoboLog "  `"$xf`" "
            }
        }
        $ArgumentList
        Write-RoboLog "start sync $Source ==> $Destination`n`Multi-Threaded ($Threads threads)`n`t1 FAILURE ALLOWED`n`tCREATE DIRECTORY STRUCTURE`n"
        $FNameOut = Join-Path "$ENV:TEMP" "$(New-Guid).log"
        $FNameErr = Join-Path "$ENV:TEMP" "$(New-Guid).log"
        $ProcessArguments = @{
            FilePath = $ROBOCOPY
            ArgumentList = $ArgumentList
            Wait = $true
            NoNewWindow = $true
            PassThru = $true
            RedirectStandardError = $FNameErr
            RedirectStandardOutput = $FNameOut
        }
        Write-Verbose "Start-Process $ProcessArguments"

        $awnser = 'y' #Read-Host "Press `'y`' to go"

        $process = Start-Process @ProcessArguments
        $ProcessExitCode = 0
        if ($process -ne $Null) {
            $handle = $process.Handle # cache proc.Handle
            $null = $process.WaitForExit();

            # This will print out False/True depending on if the process has ended yet or not
            # Needs to be called for the command below to work correctly
            $null = $process.HasExited
            $ProcessExitCode = $process.ExitCode
        }


        [int]$elapsedSeconds = $stopwatch.Elapsed.Seconds
        $stopwatch.Stop()

        $stdOut = Get-Content -Path $FNameOut -Raw
        $stdErr = Get-Content -Path $FNameErr -Raw
        if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
            $stdOut = $stdOut.Trim()
        }
        if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
            $stdErr = $stdErr.Trim()
        }

        Write-RoboLog "stdout`n$stdOut`n" -f DarkGray
        if ($stdErr.Length -gt 0) {
            Write-RoboLog "stdErr`n$stdErr`n" -f DarkRed
        }

        Write-RoboLog "COMPLETED IN $elapsedSeconds seconds"
        if ($Log -ne "") {
            $LogStr = Get-Content $Log -Raw

            Write-Verbose "$LogStr"
            Write-RoboLog "Log written to $Log"
            Add-Content -Path $Log -Value $stdOut
        }
        $returnCodeMessage = @{
            0x00 = "[INFO]: No errors occurred, and no copying was done. The source and destination directory trees are completely synchronized."
            0x01 = "[INFO]: One or more files were copied successfully (that is, new files have arrived)."
            0x02 = "[INFO]: Some Extra files or directories were detected. Examine the output log for details."
            0x04 = "[WARN]: Some Mismatched files or directories were detected. Examine the output log. Some housekeeping may be needed."
            0x08 = "[ERROR]: Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded). Check these errors further."
            0x10 = "[ERROR]: Usage error or an error due to insufficient access privileges on the source or destination directories."
        }
        $returnCodeColor = @{
            0x00 = "DarkCyan"
            0x01 = "DarkCyan"
            0x02 = "DarkCyan"
            0x04 = "DarkYellow"
            0x08 = "DarkRed"
            0x10 = "DarkRed"
        }
        if ($returnCodeMessage.ContainsKey($ProcessExitCode)) {
            $Message = $returnCodeMessage[$ProcessExitCode]

            Write-RoboLog "$Message" -f $returnCodeColor[$ProcessExitCode]

        }
        else {
            for ($flag = 1; $flag -le 0x10; $flag *= 2) {
                if ($ProcessExitCode -band $flag) {
                    $returnCodeMessage[$flag]
                    $Message = $returnCodeMessage[$flag]

                    if (($ProcessExitCode -band 0x08) -or ($ProcessExitCode -band 0x10)) {
                        Write-RoboLog "$Message" -f DarkRed
                    } else {
                        Write-RoboLog "$Message" -f Blue
                    }

                }
            }
        }

        if ($BackupMode) {
            Remove-RobocopyPrivileges
        }

    } catch {
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Invoke-UserHomeClone {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [switch]$DryRun
    )

    Add-RobocopyPrivileges


    $logfile = (New-TemporaryFile).FullName

    $dst = "C:\Users\john"
    $src = "C:\Users\guillaumep"

    #$dst = "C:\Users\guillaume"
    #$src = "C:\Users\radic"
    [System.Collections.ArrayList]$DirectoryFiltersList = [System.Collections.ArrayList]::new()
    [void]$DirectoryFiltersList.AddRange(@("Application Data","Local Settings","AppData", "Saved Games", ".git", "temp", "Downloads", "Games", "Searches", "Contacts"))

    [System.Collections.ArrayList]$FilenameFiltersList = [System.Collections.ArrayList]::new()
    [void]$FilenameFiltersList.AddRange(@("test.ps1", ".gitconfig"))
    Sync-Directories $dst $src -SyncType 'COPY' -xf $FilenameFiltersList -xd $DirectoryFiltersList -Log $logfile -b -z -ListOnly:$DryRun

 
    Remove-RobocopyPrivileges
    $LogData = Get-Content "$logfile" -Raw
    Write-Host "$LogData"
    $logfile


}


function ConvertFrom-AclDirectorySec {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "acl object")]
        [System.Security.AccessControl.DirectorySecurity]$AclPtr,
        [Parameter(Mandatory = $false, HelpMessage = "show acl report")]
        [switch]$ShowPolicy
    )

    process {
        [regex]$Pattern = '^(?<Domain>^[\w-\.\ ]+)\\(?<Username>([\w-]+)+)(?<space>[\s+])(?<Policy>([Alllow|Deny]+)+)(?<space>[\s+]+)(?<Rights>([\w-]+)+)$'
        [string[]]$AclList = $($beforeAcl.AccessToString).Split("`n")
        [string[]]$ParsedAclList = $AclList | % {
            $l = $_.Trim()
            if ($l -match $Pattern) {
                [string]$aclline = ''
                if ($ShowPolicy) {
                    [string]$aclline = "{0,-25} {1, -16} {2}" -f $($Matches.Username), $($Matches.Policy), $($Matches.Rights)
                } else {
                    [string]$aclline = "{0,-25} {1}" -f $($Matches.Username), $($Matches.Rights)
                }

                $aclline
            }
        }
        return $ParsedAclList
    }
}


function Grant-DirectoryPermission {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path "$_" -PathType Container })]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Username = "$ENV:USERNAME",
        [Parameter(Mandatory = $false, HelpMessage = "show acl report")]
        [switch]$ShowAcl
    )

    # Ensure admin
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator."
        return
    }

    $User = Get-LocalUser -Name $Username -ErrorAction Ignore
    if ($null -eq $User) {
        Write-Error "No such user '$Username'"
        return
    }

    if ($ShowAcl) {
        $BeforeAcl = Get-Acl -Path $Path
        $BeforeOwner = $BeforeAcl.Owner
        [string[]]$PersStrings = @(" Permissions`n")
        ($beforeAcl | ConvertFrom-AclDirectorySec) | % { $PersStrings += "    $_`n" }
        Write-Host "==================== ShowAcl Before ====================" -ForegroundColor Gray
        [string]$OwnerLine = " {0,-28}  {1}" -f "Owner", $BeforeOwner
        Write-Host "$OwnerLine" -ForegroundColor Yellow
        Write-Host "$PersStrings" -ForegroundColor Yellow

    }

    try {
        # Take ownership and give full control to user
        Write-Host "Setting ownership and permissions for '$Username' on '$Path'" -ForegroundColor Cyan
        $icaclsexe = (get-command -Name "icacls.exe" -CommandType Application).Source
        $takeownexe = (get-command -Name "takeown.exe" -CommandType Application).Source

        Write-Host "Running icacls.exe for $Path" -ForegroundColor Cyan

        $outfile_std = (New-TemporaryFile).FullName
        $outfile_err = (New-TemporaryFile).FullName
        $UserRightsArg = '"{0}:(OI)(CI)F"' -f $Username

        $cmdres = Start-Process -FilePath "$icaclsexe" -ArgumentList "$Path", "/grant", "$UserRightsArg", "/T", "/C" -NoNewWindow -Wait -Passthru -RedirectStandardError $outfile_err -RedirectStandardOutput $outfile_std
        $ecode = $cmdres.ExitCode
        $pcpu = $cmdres.CPU -as [string]
        if ($ecode -eq 0) {
            Write-Host "SUCCESS after $pcpu" -f DarkGreen
            $StdOutStrings = Get-Content -Path "$outfile_std" -Raw
            Write-Host "$StdOutStrings" -f DarkYellow
        } else {
            Write-Host "FAILED. ExitCode: $ecode" -f DarkRed

            $ErrStrings = Get-Content -Path "$outfile_err" -Raw
            Write-Host "$ErrStrings" -f DarkYellow
        }
        $outfile_std = (New-TemporaryFile).FullName
        $outfile_err = (New-TemporaryFile).FullName

        write-Host "Running takeown.exe for $Path" -ForegroundColor Cyan
        $cmdres = Start-Process -FilePath "$takeownexe" -ArgumentList "/f", "$Path", "/r", "/d", "y" -NoNewWindow -Wait -Passthru -RedirectStandardError $outfile_err -RedirectStandardOutput $outfile_std
        $ecode = $cmdres.ExitCode
        $pcpu = $cmdres.CPU -as [string]
        if ($ecode -eq 0) {
            Write-Host "SUCCESS after $pcpu" -f DarkGreen
            $StdOutStrings = Get-Content -Path "$outfile_std" -Raw
            Write-Host "$StdOutStrings" -f DarkYellow
        } else {
            Write-Host "FAILED. ExitCode: $ecode" -f DarkRed

            $ErrStrings = Get-Content -Path "$outfile_err" -Raw
            Write-Host "$ErrStrings" -f DarkYellow
        }
        Remove-Item $outfile_std, $outfile_err -Force -ErrorAction SilentlyContinue

        if ($ShowAcl) {
            $AfterAcl = Get-Acl -Path $Path
            $AfterOwner = $AfterAcl.Owner
            [string[]]$PersStrings = @(" Permissions`n")
            ($AfterAcl | ConvertFrom-AclDirectorySec) | % { $PersStrings += "    $_`n" }
            Write-Host "==================== ShowAcl After ====================" -ForegroundColor Gray
            [string]$OwnerLine = " {0,-28}  {1}" -f "Owner", $AfterOwner
            Write-Host "$OwnerLine" -ForegroundColor Yellow
            Write-Host "$PersStrings" -ForegroundColor Yellow
        }

    } catch {
        Write-Error "$_"
    }
}

