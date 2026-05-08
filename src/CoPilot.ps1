#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   CoPilot.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Open-CoPilotDashboard {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'DashboardUrl')]
        [string]$DashboardUrl = "https://cloud.copilotkit.ai/dashboard"
    )

    $BraveExe = Join-Path "$ENV:LOCALAPPDATA" "BraveSoftware\Brave-Browser\Application\brave.exe"
    if (-not (Test-Path $BraveExe)) {
        Write-Error "Brave browser not found at $BraveExe"
        return
    }
    Start-Process -FilePath $BraveExe -ArgumentList "--new-tab", $DashboardUrl
}

