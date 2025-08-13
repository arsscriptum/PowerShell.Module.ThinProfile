#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   controlmouse.ps1                                                             ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Get-RegistryInstanceId {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        [string]$RegPath = Get-PSControlsRegistryRoot
        if (-not (Test-Path -Path $RegPath)) {
            Write-Warning "Registry path does not exist: $RegPath"
            return $null
        }

        $value = Get-ItemProperty -Path $RegPath -Name "InstanceId" -ErrorAction Stop
        return $value.InstanceId
    }
    catch {
        Write-Warning "InstanceId not found in $RegPath"
        return $null
    }
}



function Set-RegistryInstanceId {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "InstanceId string to store")]
        [ValidateNotNullOrEmpty()]
        [string]$InstId
    )

    try {
        [string]$RegPath = Get-PSControlsRegistryRoot
        if (-not (Test-Path -Path $RegPath)) {
            if ($PSCmdlet.ShouldProcess($RegPath, "Create registry key")) {
                New-Item -Path $RegPath -Force | Out-Null
            }
        }

        if ($PSCmdlet.ShouldProcess("$RegPath\InstanceId", "Set registry value")) {
            Set-ItemProperty -Path $RegPath -Name "InstanceId" -Value $InstId -Force
        }

        Write-Host "InstanceId successfully written to registry." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to write registry value: $_"
    }
}



function Get-PSControlsRegistryRoot {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\PowerShellInterfacesControls\Mouse"
    if (!(Test-Path "$RegKeyRoot")) {
        New-Item -Path "$RegKeyRoot" -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    $RegKeyRoot
}


function Disable-LocalMouse {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $NumberOfMouse = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Measure-Object | Select -ExpandProperty Count
    if ($NumberOfMouse -eq 0) {
        Write-Host "No Mouse to Disable!" -f DarkRed
        return
    }
    $FilePath = "$ENV:LOCALAPPDATA\PowerShellInterfacesControls\Mouse.uid"
    [string[]]$InstIds = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Select -ExpandProperty InstanceId
    $InstId = $InstIds[0]
    Disable-PnpDevice -InstanceId "$InstId" -Confirm:$false
    Remove-Item -Path "$FilePath" -Force -ErrorAction Ignore | Out-Null
    New-Item -Path "$FilePath" -ItemType File -Force -ErrorAction Ignore -Value "$InstId"
    Set-RegistryInstanceId "$InstId"
}


function Get-LocalMouseStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $NumberOfMouse = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Measure-Object | Select -ExpandProperty Count
    Write-Host "Number of Enabled Mouse $NumberOfMouse" -f DarkGreen
    Get-PnpDevice -Class Mouse
}

function Enable-LocalMouse {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $FilePath = "$ENV:LOCALAPPDATA\PowerShellInterfacesControls\Mouse.uid"
    if (-not (Test-Path -Path $FilePath)) {
        $InstId = Get-RegistryInstanceId
    }
    else {
        $InstId = Get-Content -Path "$FilePath" -Raw
    }

    if (Get-PnpDevice -InstanceId "$InstId" -ErrorAction Ignore) {
        Enable-PnpDevice -InstanceId "$InstId" -Confirm:$false
    }
}
