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
        Write-Verbose "[Get-ThinProfileModuleVersion] Get Latest (Online) $Latest"

        $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
        $JsonPath = Join-Path $ThinProfileVersionPath "ThinProfile.json"

        if (!(Test-Path $JsonPath)) {
            Write-Error "module not initialized! no file $JsonPath"
            return $Null
        }

        [version]$CurrVersion = Get-ThinProfileModuleVersion
        Write-Verbose "[Get-ThinProfileModuleVersion] CurrVersion $CurrVersion"
        Write-Verbose "[Get-ThinProfileModuleVersion] JsonPath $JsonPath"
        $Data = Get-Content $JsonPath | ConvertFrom-Json
        Write-Verbose "[Get-ThinProfileModuleVersion] JSON DATA`n------`n$Data`n-------`n"
        

        [version]$LatestVersion = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
        Write-Verbose "[Get-ThinProfileModuleVersion] LatestVersion $($LatestVersion.ToString())"
        return $LatestVersion.ToString()
    }else{
        Write-Verbose "[Get-ThinProfileModuleVersion] Get Local Version 1.0.63 "
    }

    $Version = "1.0.63"
    return $Version
}

