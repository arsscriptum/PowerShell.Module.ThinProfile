#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   copilot.ps1                                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
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



