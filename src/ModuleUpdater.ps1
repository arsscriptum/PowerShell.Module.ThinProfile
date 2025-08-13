#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   moduleupdater.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-ThinProfileModuleVersionPath {
    $ModPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $VersionPath = Join-Path $ModPath 'version'
    return $VersionPath
}


function New-ThinProfileModuleVersionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$AutoUpdateFlag,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
    $JsonPath = (Join-Path $ThinProfileVersionPath "clienttools.json")
    $CurrDate = Get-Date -UFormat "%s"
    $ModuleName = (Get-ThinProfileModuleInformation).ModuleName.Name
    $ModuleInstallPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $ModulePath = (Get-ThinProfileModuleInformation).ModulePath

    $psm1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psm1'
    $psd1path =  (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psd1'

    $ValidFiles = ((Test-Path "$psm1path") -And (Test-Path "$psd1path"))
    if(!$ValidFiles){
        Write-Error "Missing Module File"
    }


    $UpdateUrl = "https://arsscriptum.github.io/{0}" -f $ModuleName
    $VersionUrl = "https://arsscriptum.github.io/{0}/{1}" -f $ModuleName, "Version.nfo"
    $CurrVersion = Get-ThinProfileModuleVersion
    if ((!(Test-Path "$JsonPath")) -or ($Force)) {
        [pscustomobject]$o = [pscustomobject]@{
            CurrentVersion = "$CurrVersion"
            LastUpdate = "$CurrDate"
            UpdateUrl = "$UpdateUrl"
            VersionUrl = "$VersionUrl"
            ModuleName = "$ModuleName"
            AutoUpdate = $AutoUpdateFlag
            LocalPSM1 = "$psm1path"
            LocalPSD1 = "$psd1path"
        }
        $NewFileJsonData = $o | ConvertTo-Json
        New-Item -Path "$JsonPath" -ItemType File -Force -EA Stop -Value $NewFileJsonData | Out-Null
    }

}


function Set-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true)]
        [bool]$Enable
    )


    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        New-Item -Path $RegKeyRoot -Force | Out-Null
    }
    $Val = if($Enable){1}else{0}

    # Set the registry key as REG_MULTI_SZ (array of strings)
    Set-ItemProperty -Path $RegKeyRoot -Name "override" -Value $Val -Type DWORD
}


function Get-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        return $False
    }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    $RegVal = Get-ItemProperty -Path $RegKeyRoot -Name "override" -ErrorAction Ignore
    if (-not ($RegVal)) {
        return $False
    }
    if($RegVal.override){
        return $True
    }
    return $False
}

function Invoke-ThinProfileAutoUpdate {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        [Parameter(Mandatory = $false)]
        [switch]$Import
    )

    $ShouldBypass = Get-ThinProfileAutoUpdateOverride
    if($ShouldBypass){
        Write-Host "[Invoke-ThinProfileAutoUpdate] Bypass OVerride" -f DarkRed
        return
    }

    $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
    $JsonPath = Join-Path $ThinProfileVersionPath "clienttools.json"

    if (!(Test-Path $JsonPath)) {
        Write-Verbose "No such file $JsonPath... creating default version file."
        New-ThinProfileModuleVersionFile
    }

    [version]$CurrVersion = Get-ThinProfileModuleVersion

    $Data = Get-Content $JsonPath | ConvertFrom-Json
    if ($Data.AutoUpdate) {
        try {
            [version]$LatestVersionStruct = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
            [string]$LatestVersion = $LatestVersionStruct.ToString()
        } catch {
            Write-Warning "Cannot Update -> No Version found at $($Data.VersionUrl)"
            return
        }

        Write-Host "Current Version    $CurrVersion"
        Write-Host "Latest  Version    $LatestVersion"
        $UpdateRequired = (($LatestVersion -gt $CurrVersion) -or $Force)

        if ($UpdateRequired) {
            Write-Host "[Invoke-ThinProfileAutoUpdate] UpdateRequired" -f DarkRed

            $ModuleInstallPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
            $ModuleInstallPathRoot = (Split-Path -Parent $ModuleInstallPath) 
            Write-Host "[Invoke-ThinProfileAutoUpdate] ModuleInstallPath     $ModuleInstallPath" -f DarkRed
            Write-Host "[Invoke-ThinProfileAutoUpdate] ModuleInstallPathRoot $ModuleInstallPathRoot" -f DarkRed
            $VersionFolder = Join-Path -Path "$ModuleInstallPathRoot" -ChildPath "$LatestVersion"
            if (!(Test-Path $VersionFolder)) {
                Write-Host "[Invoke-ThinProfileAutoUpdate] New Version Folder $VersionFolder" -f DarkRed
                New-Item -ItemType Directory -Path $VersionFolder -Force | Out-Null
            }

            $psd1path = Join-Path $VersionFolder "$($Data.ModuleName).psd1"
            $psm1path = Join-Path $VersionFolder "$($Data.ModuleName).psm1"

            $Psd1Url = "$($Data.UpdateUrl)/$($Data.ModuleName).psd1"
            $Psm1Url = "$($Data.UpdateUrl)/$($Data.ModuleName).psm1"

            Write-Host "Updating Manifest from URL $Psd1Url -> $psd1path" -f Magenta
            Invoke-WebRequest -Uri $Psd1Url -OutFile $psd1path -UseBasicParsing -ErrorAction Stop

            Write-Host "Updating Module from URL $Psm1Url -> $psm1path" -f Blue
            Invoke-WebRequest -Uri $Psm1Url -OutFile $psm1path -UseBasicParsing -ErrorAction Stop

            # Update the json
            $Data.CurrentVersion = $LatestVersion.ToString()
            $Data.LocalPSD1 = $psd1path
            $Data.LocalPSM1 = $psm1path
            $Data | ConvertTo-Json -Depth 4 | Set-Content -Path $JsonPath -Encoding UTF8

            Write-ThinProfileHost "✅ Module successfully updated to version $LatestVersion"
            if($Import){
             import-module "PowerShell.Module.ThinProfile" -MinimumVersion "$LatestVersion" -Force
            }
        }
        else {
            Write-Verbose "Should Update -> No"
            Write-ThinProfileHost "No Update Required. Current Version is $CurrVersion"
            if ($NoUpdate) {
                return $false
            }
        }
    }
}
