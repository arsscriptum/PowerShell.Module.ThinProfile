#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   QuickSyupport.ps1                                                                   |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+

function Start-QuickSupport {
    param (
        [switch]$Admin
    )
    $exePath = 'C:\Programs\TeamViewer\QuickSupport.exe'

    if (-not (Test-Path $exePath)) {
        Write-Error "Executable not found at $exePath"
        return
    }

    if ($Admin) {
        Start-Process -FilePath $exePath -Verb RunAs
    } else {
        Start-Process -FilePath $exePath
    }
}

New-Alias -Name 'qsupport' -Value Start-QuickSupport -Scope 'Global' -ErrorAction 'Ignore'