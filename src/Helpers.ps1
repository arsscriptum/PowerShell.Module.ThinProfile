#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   helpers.ps1                                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Invoke-EnsureSharedScriptFolder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = 'C:\ProgramData\arsscriptum\scripts'
    )

    [string]$SharedPath = $Path

    # Create folder if it doesn't exist
    if (-not (Test-Path $SharedPath)) {
        New-Item -Path $SharedPath -ItemType Directory -Force | Out-Null
    }

    # Set access rights to allow all users to read/execute files
    $acl = Get-Acl $SharedPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule (
        "Users", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow"
    )

    if (-not $acl.Access | Where-Object { $_.IdentityReference -eq "Users" -and $_.FileSystemRights -match "ReadAndExecute" }) {
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $SharedPath -AclObject $acl
    }

    return $SharedPath
}




function Wait-ThinProfileModuleUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Online,
        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of seconds to wait.")]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 300,

        [Parameter(Mandatory = $false, HelpMessage = "Check interval in seconds.")]
        [ValidateRange(1, 300)]
        [int]$CheckIntervalSeconds = 1
    )

    $Local = $True
    if ($Online) {
        $Local = $false

    }

    $StartTime = Get-Date
    $TimeoutTime = $StartTime.AddSeconds($TimeoutSeconds)

    try {

        if ($Local) {
            [version]$InitialVersion = Get-ThinProfileModuleVersion
            [version]$LatestVersion = Get-ThinProfileModuleVersion -Latest
            if ($InitialVersion -eq $LatestVersion) {
                Write-Host "🔄 Waiting for version to update from $InitialVersion..." -ForegroundColor Yellow
            } else {

                Write-Host "✅ Already updated: $InitialVersion -> $LatestVersion" -ForegroundColor Green
                return $true
            }
        } else {
            [version]$InitialVersion = Get-ThinProfileModuleVersion -Latest
            [version]$LatestVersion = Get-ThinProfileModuleVersion -Latest
        }

        while ((Get-Date) -lt $TimeoutTime) {
            Start-Sleep -Seconds $CheckIntervalSeconds
            if ($Local) {
                [version]$CurrentVersion = Get-ThinProfileModuleVersion
            } else {
                [version]$CurrentVersion = Get-ThinProfileModuleVersion -Latest
            }
            if ($CurrentVersion -gt $InitialVersion) {
                Write-Host "✅ Module updated: $InitialVersion → $CurrentVersion" -ForegroundColor Green
                return $true
            }

            Write-Host "⏳ Still waiting... Current: $CurrentVersion (Latest: $LatestVersion)" -ForegroundColor DarkGray
        }

        Write-Warning "⏰ Timeout reached. Module version is still $InitialVersion"
        return $false
    }
    catch {
        Write-Error "❌ Error during update check: $_"
        return $false
    }
}


function Show-ModuleInstallPaths {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $paths = $env:PSModulePath -split ';'
    $found = @()

    foreach ($base in $paths) {
        if (-not (Test-Path $base)) { continue }

        $matches = Get-ChildItem -Path $base -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq $ModuleName }

        foreach ($match in $matches) {
            Write-Host "Found: $($match.FullName)" -ForegroundColor Green
            Start-Process "explorer.exe" -ArgumentList "`"$($match.FullName)`""
            $found += $match.FullName
        }
    }

    if (-not $found) {
        Write-Warning "No directories found for module '$ModuleName' in PSModulePath."
    }
}


function Write-ProgressHelper {
    [CmdletBinding()]
    param()
    try {
        if ($Script:TotalSteps -eq 0) { return }
        Write-Progress -Activity $Script:ProgressTitle -Status $Script:ProgressMessage -PercentComplete (($Script:StepNumber / $Script:TotalSteps) * 100)
    } catch {
        Write-Host "⌛ StepNumber $Script:StepNumber" -f DarkYellow
        Write-Host "⌛ ScriptSteps $Script:TotalSteps" -f DarkYellow
        $val = (($Script:StepNumber / $Script:TotalSteps) * 100)
        Write-Host "⌛ PercentComplete $val" -f DarkYellow
        Show-ExceptionDetails $_ -ShowStack
    }
}

function Write-ThinProfileHost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)][Alias('m')]
        [string]$Message
    )
    Write-Host "[PowerShell.Module.ThinProfile] " -f DarkRed -n
    Write-Host "$Message" -f DarkYellow
}



function Test-Function { ############### NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)][Alias('n')] [string]$Name,
        [Parameter(Mandatory = $true, Position = 1)][Alias('m')] [string]$Module
    )
    $Res = $True
    try {
        Write-Verbose "Test $Name [$Module]"
        if (-not (Get-Command "$Name" -ErrorAction Ignore)) { throw "missing function $Name, from module $Module" }
    } catch {
        Write-Host "[Missing Dependency] " -n -f DarkRed
        Write-Host "$_" -f DarkYellow
        $Res = $False
    }
    return $Res
}

function Test-Dependencies { ############### NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Res = $True
    try {
        $CoreFuncs = @('Set-RegistryValue', 'New-RegistryValue', 'Register-AppCredentials', 'Decrypt-String')
        foreach ($f in $CoreFuncs) {
            if (-not (Test-Function -n "$f" -m "PowerShell.Module.OpenAI")) { $Res = $False; break; }
        }
    } catch {
        Write-Error "$_"
        $Res = $False
    }
    return $Res
}


<#
    .SYNOPSIS
        FROM C-time converter function
    .DESCRIPTION
        Simple function to convert FROM Unix/Ctime into EPOCH / "friendly" time
#>
function ConvertFrom-Ctime {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "ctime")]
        [int64]$Ctime
    )

    [datetime]$epoch = '1970-01-01 00:00:00'
    [datetime]$result = $epoch.AddSeconds($Ctime)
    return $result
}

<#
    .SYNOPSIS
        INTO C-time converter function
    .DESCRIPTION
        Simple function to convert into FROM EPOCH / "friendly" into Unix/Ctime, which the Inventory Service uses.
#>
function ConvertTo-CTime {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "InputEpoch")]
        [datetime]$InputEpoch
    )

    [datetime]$Epoch = '1970-01-01 00:00:00'
    [int64]$Ctime = 0

    $Ctime = (New-TimeSpan -Start $Epoch -End $InputEpoch).TotalSeconds
    return $Ctime
}

function ConvertFrom-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [int64]$UnixTime
    )
    begin {
        $epoch = [datetime]::SpecifyKind('1970-01-01', 'Local')
    }
    process {
        $epoch.AddSeconds($UnixTime)
    }
}

function ConvertTo-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [datetime]$DateTime
    )
    begin {
        $epoch = [datetime]::SpecifyKind('1970-01-01', 'Local')
    }
    process {
        [int64]($DateTime - $epoch).TotalSeconds
    }
}

function Get-UnixTime {
    $Now = Get-Date
    return ConvertTo-UnixTime $Now
}


function Get-DateString ([switch]$Verbose) {

    if ($Verbose) {
        return ((Get-Date).GetDateTimeFormats()[8]).Replace(' ', '_').ToString()
    }

    $curdate = $(get-date -Format "yyyy-MM-dd_\hhh-\mmmm-\sss")
    return $curdate
}


function Get-DateForFileName ([switch]$Minimal) {
    $sd = (Get-Date).GetDateTimeFormats()[14]
    $sd = $sd.Split('.')[0]
    $sd = $sd.Replace(':', '-');
    if ($Minimal) {
        $sd = $sd.Replace('-', '');
    }
    return $sd
}
