#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   moduleupdater.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-ThinProfileModuleVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )

    if($Latest){
        $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
        $JsonPath = Join-Path $ThinProfileVersionPath "clienttools.json"

        if (!(Test-Path $JsonPath)) {
            Write-Error "module not initialized! no file $JsonPath"
            return $Null
        }

        [version]$CurrVersion = Get-ThinProfileModuleVersion

        $Data = Get-Content $JsonPath | ConvertFrom-Json
        [version]$LatestVersion = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
        return $LatestVersion.ToString()
    }

    $Version = "___MODULE_VERSION_STRING____"
    return $Version
}
