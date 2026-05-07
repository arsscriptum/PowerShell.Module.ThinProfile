

function Add-EnvPath2 {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Path to add.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory = $false, HelpMessage = "Scope")]
        [ValidateSet('Machine', 'User', 'Session')]
        [Alias('scope')]
        [string] $Container = 'Session',
        [Parameter(Mandatory = $false, HelpMessage = "PrintsOnly")]
        [switch]$PrintsOnly
    )

    try {
        $normalizedPath = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\')
    } catch {
        $normalizedPath = $Path.TrimEnd('\')
    }

    if ($Container -ne 'Session') {
        $containerMapping = @{
            Machine = [EnvironmentVariableTarget]::Machine
            User    = [EnvironmentVariableTarget]::User
        }
        $containerType = $containerMapping[$Container]

        $persistedPaths = [Environment]::GetEnvironmentVariable('Path', $containerType) -split ';'
        if (-not ($persistedPaths | Where-Object { $_ -ieq $normalizedPath })) {
            $persistedPaths = ($persistedPaths + $normalizedPath) | Where-Object { $_ -ne '' }
            if ($PSCmdlet.ShouldProcess("$Container PATH", "Add $normalizedPath")) {
                if($PrintsOnly){
                    Write-Host "[PRINTS ONLY] " -n -f DarkRed
                    Write-Host "Would Add $normalizedPath to $Container environment PATH.`n===========" -f DarkYellow
                    Write-Host "$persistedPaths" -f DarkCyan
                    Write-Host "===========" -f DarkYellow
                } else {
                    [Environment]::SetEnvironmentVariable('Path', ($persistedPaths -join ';'), $containerType)    
                    Write-Host "Added $normalizedPath to $Container environment PATH."
                }
            }
        } else {
            Write-Host "$normalizedPath already exists in $Container PATH."
        }
    }

    $envPaths = $env:Path -split ';'
    if (-not ($envPaths | Where-Object { $_ -ieq $normalizedPath })) {
        $envPaths = ($envPaths + $normalizedPath) | Where-Object { $_ -ne '' }
        if ($PSCmdlet.ShouldProcess("Session PATH", "Add $normalizedPath")) {
            if($PrintsOnly){
                Write-Host "[PRINTS ONLY] " -n -f DarkRed
                Write-Host "Would Add $normalizedPath to Session PATH.`n===========" -f DarkYellow
                Write-Host "$persistedPaths" -f MAgenta
                Write-Host "===========" -f DarkYellow
            } else {
                $env:Path = $envPaths -join ';'  
                Write-Host "Added $normalizedPath to $Container environment PATH."
            }
        }
    } else {
        Write-Host "$normalizedPath already exists in current session PATH."
    }
}

function Install-ProcessExplorer {
     [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Path to add.")]
        [string] $Path='C:\Programs\ProcessExplorer'
    )

    $InstallDir  = "$Path"
    $ZipUrl      = 'https://download.sysinternals.com/files/ProcessExplorer.zip'
    $ZipTemp     = Join-Path $env:TEMP 'ProcessExplorer.zip'
    $RegKey      = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
    $DebuggerVal = "$InstallDir\procexp64.exe"

    # Download
    Write-Host "Downloading Process Explorer..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipTemp -UseBasicParsing

    # Expand
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    Write-Host "Extracting to $InstallDir..."
    Expand-Archive -Path $ZipTemp -DestinationPath $InstallDir -Force
    Remove-Item $ZipTemp -Force

    # PATH via Add-EnvPath if available
    if (Get-Command Add-EnvPath2 -ErrorAction SilentlyContinue) {
        Write-Host "Adding to PATH via Add-EnvPath..."
        Add-EnvPath2 -Path $InstallDir -Container Machine
        Add-EnvPath2 -Path $InstallDir -Container Session
    } else {
        Write-Warning "Add-EnvPath not found — skipping PATH update."
    }

    # Registry IFEO hijack
    Write-Host "Writing IFEO registry entry..."
    if (-not (Test-Path $RegKey)) {
        New-Item -Path $RegKey -Force | Out-Null
    }
    Set-ItemProperty -Path $RegKey -Name 'Debugger' -Value $DebuggerVal -Type String

    Write-Host "Done. taskmgr.exe -> $DebuggerVal"
}