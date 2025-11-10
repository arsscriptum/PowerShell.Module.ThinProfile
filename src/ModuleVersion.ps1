#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModuleVersion.ps1                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
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
        Write-Verbose "[Get-ThinProfileModuleVersion] Get Local Version 1.0.86 "
    }

    $Version = "1.0.86"
    return $Version
}

