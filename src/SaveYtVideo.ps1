#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   SaveYtVideo.ps1                                                              ║
#║   Function to save Video Media                                                 ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



# Sample Code For Example Only 
function Save-YtVideo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Urls")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Urls
    )

    $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"

    foreach ($url in $Urls) {
        if ($PSCmdlet.ShouldProcess($url, "Download YouTube video")) {
            & $ytDlpPath -f "bv*+ba/best" $url
        }
    }
}
