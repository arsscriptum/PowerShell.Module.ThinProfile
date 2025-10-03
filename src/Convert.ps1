
#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   convert.ps1                                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

function Out-TimeSpan {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "The TimeSpan to format")]
        [timespan]$TimeSpan
    )
    process {
        $parts = @()
        if ($TimeSpan.Days)         { $DayUnit = if ($TimeSpan.Days -gt 1)    {'days'}  else {'day'}  ; $parts += "$($TimeSpan.Days) $DayUnit"  }
        if ($TimeSpan.Hours)        { $HrsUnit = if ($TimeSpan.Hours -gt 1)   {'hours'} else {'hour'} ; $parts += "$($TimeSpan.Hours) $HrsUnit" }
        if ($TimeSpan.Minutes)      { $MinUnit = if ($TimeSpan.Minutes -gt 1) {'mins'}  else {'min'}  ; $parts += "$($TimeSpan.Minutes) $MinUnit" }
        if ($TimeSpan.Seconds)      { $SecUnit = if ($TimeSpan.Seconds -gt 1) {'secs'}  else {'sec'}  ; $parts += "$($TimeSpan.Seconds) $SecUnit" }
        if ($TimeSpan.Milliseconds) { $parts += "$($TimeSpan.Milliseconds) ms" }
        if (-not $parts) { $parts = "0 sec" }
        $parts -join ', '
    }


}


function Convert-YouTubeShortsUrl {
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )
    begin {
        $ShortsPrefix = 'https://www.youtube.com/shorts/'
        $WatchPrefix = 'https://www.youtube.com/watch?v='
    }
    process {
        if (-not $Url.StartsWith($ShortsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $Url
        }

        $tail = $Url.Substring($ShortsPrefix.Length)
        $videoId = ($tail -split '[/?#&]')[0]

        if ([string]::IsNullOrWhiteSpace($videoId)) {
            throw "Invalid YouTube Shorts URL: missing video id. Url: $Url"
        }
        if ($videoId.Length -ne 11 -or ($videoId -notmatch '^[A-Za-z0-9_]{11}$')) {
            throw "Invalid YouTube video id '$videoId' (must be 11 alphanumeric)."
        }

        '{0}{1}' -f $WatchPrefix, $videoId
    }
}
