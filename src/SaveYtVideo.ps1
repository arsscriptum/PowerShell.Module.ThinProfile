#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   SaveYtVideo.ps1                                                              ║
#║   Function to save Video Media                                                 ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-FilenameFromUrl {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )
    process {
        # YouTube video: https://www.youtube.com/watch?v=xxxxxxx
        if ($Url -match '^https?://(www\.)?youtube\.com/watch\?v=([A-Za-z0-9_-]{11})') {
            return "youtube-$($matches[2])"
        }
        # YouTube short: https://www.youtube.com/shorts/xxxxxxx
        if ($Url -match '^https?://(www\.)?youtube\.com/shorts/([A-Za-z0-9_-]{11})') {
            return "youtube-$($matches[2])"
        }
        # Generic - use last path segment, no trailing slash or query
        try {
            $uri = [System.Uri]$Url
            $seg = $uri.Segments[-1].TrimEnd('/')
            if ([string]::IsNullOrWhiteSpace($seg)) { $seg = 'file' }
            return $seg
        } catch {
            # fallback: just take last part after /
            $Url -split '/' | Select-Object -Last 1
        }
    }
}

function Get-UniqueFileName {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "File path")]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    process {
        $dir = [System.IO.Path]::GetDirectoryName($Path)
        $base = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $ext = [System.IO.Path]::GetExtension($Path)
        $n = 1
        $test = $Path

        while (Test-Path -LiteralPath $test) {
            $test = if ($n -eq 1) {
                [System.IO.Path]::Combine($dir, "$base-01$ext")
            } else {
                [System.IO.Path]::Combine($dir, "{0}-{1:D2}{2}" -f $base, $n, $ext)
            }
            $n++
        }
        return $test
    }
}

function Start-YtDlpProcess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Url")]
        [string[]]$Arguments,
        [Parameter(Position = 1, Mandatory = $False)]
        [string]$String,
        [Parameter(Mandatory = $False)]
        [switch]$WriteOutput
    )
    try {
        $TmpDir = (New-TemporaryDirectory).FullName
        Push-Location "$TmpDir" | Out-Null

        $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()

        [System.Collections.ArrayList]$ca = [System.Collections.ArrayList]::new()
        $Arguments | % {
            [void]$ca.Add("$_")
        }

        $argstring = $ca -join " "
        Write-Host "Command => `"$ytDlpPath $argstring`""

        $ProgramArgsSet = @{
            FilePath = $ytDlpPath
            ArgumentList = $ca
            PassThru = $True
            Wait = $False
            NoNewWindow = $True
            RedirectStandardOutput = $stdout
            RedirectStandardError = $stderr
        }

        Write-Host "[$String] Starting to Download " -f DarkGray -n
        Write-Host "$goodUrl" -f DarkYellow
        $cmdres = Start-Process @ProgramArgsSet
        Write-Host "[$String] Download in progress" -f DarkCyan -n

        $IsDone = $False
        while (!$IsDone) {
            Start-Sleep -Milliseconds 200
            Write-Host "." -f DarkGray -n
            $IsDone = $cmdres.HasExited
        }

        $ExitCode = $cmdres.ExitCode
        $ts = [datetime]::Now - $cmdres.StartTime
        $tsstr = Out-TimeSpan $ts
        $Success = ($ExitCode -eq 0)
        Write-Host "`nProcess Terminated after " -f DarkYellow -n
        Write-Host "$tsstr" -f White
        if ($Success) {
            Write-Host "[$String] Done Successfully!" -f DarkGreen
            if ($WriteOutput) {
                $outstr = Get-Content $stdout -Raw
                Write-Host "$outstr" -f DarkGreen
            }

        } else {
            Write-Host "[$String] Error Occured $ExitCode" -f DarkRed
            if ($WriteOutput) {
                $outstr = Get-Content $stdout -Raw
                Write-Host "$outstr" -f DarkGreen
                $outstr = Get-Content $stderr -Raw
                Write-Host "$outstr" -f DarkRed
            }
        }
    } catch {
        throw "$_"
    } finally {
        Pop-Location | Out-Null

    }
    return $Success


}

function Save-YtVideo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Url")]
        [string[]]$Urls
    )
    begin {
        $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()
        $DefaultFormat = "bv*+ba/best"

    }
    process {
        foreach ($url in $Urls) {

            $goodUrl = Convert-YouTubeShortsUrl $url
            [uri]$uri_u = $goodUrl
            $filename = Get-FilenameFromUrl $goodUrl
            [System.Collections.ArrayList]$ccdefault = [System.Collections.ArrayList]::new()
            [void]$ccdefault.Add("-P")
            [void]$ccdefault.Add("`"$ENV:YouTubeVideos`"")
            [void]$ccdefault.Add("--print")
            [void]$ccdefault.Add("after_move:filepath")
            [void]$ccdefault.Add("-f")
            [void]$ccdefault.Add("$DefaultFormat")
            [void]$ccdefault.Add($goodUrl)

            $s = Start-YtDlpProcess $ccdefault "$DefaultFormat"
            if ($s -eq $False) {
                $Basename = Join-Path "$ENV:YouTubeVideos" "$filename"
                $AudioPath = "$Basename" + ".m4a"
                $AudioPath = Get-UniqueFileName $AudioPath
                $VideoPath = "$Basename" + ".mp4"
                $VideoPath = Get-UniqueFileName $VideoPath
                $MergedVideoPath = "$Basename-final" + ".mp4"
                $MergedVideoPath = Get-UniqueFileName $MergedVideoPath
                $Json = Get-YtVideoJsonData "$goodUrl"
                $res = Select-Mp4FormatIds $Json
                $vfmt = $res.VideoFormat
                $afmt = $res.AudioFormat
                [System.Collections.ArrayList]$ccv = [System.Collections.ArrayList]::new()
                [void]$ccv.Add("--print")
                [void]$ccv.Add("after_move:filepath")
                [void]$ccv.Add("-f")
                [void]$ccv.Add("$vfmt")
                [void]$ccv.Add("-o")
                [void]$ccv.Add("$VideoPath")
                [void]$ccv.Add($goodUrl)

                [System.Collections.ArrayList]$cca = [System.Collections.ArrayList]::new()
                [void]$cca.Add("--print")
                [void]$cca.Add("after_move:filepath")
                [void]$cca.Add("-f")
                [void]$cca.Add("$afmt")
                [void]$cca.Add("-o")
                [void]$cca.Add("$AudioPath")
                [void]$cca.Add($goodUrl)

                $sv = Start-YtDlpProcess $ccv "137 VIDEO ONLY"
                $sa = Start-YtDlpProcess $cca "140 AUDIO ONLY"
                if ($sv -and $sa) {
                    Merge-VideoAudio "$VideoPath" "$AudioPath" -OutPath "$MergedVideoPath"

                }


            }
        }
    }
}


function Select-Mp4FormatIds {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True)]
        [pscustomobject]$Json
    )

    $all = @($Json.formats) + @($Json.requested_formats) | Where-Object { $_ }
    if (-not $all) { return $null }

    # Filter for MP4 video, no audio (pure video stream)
    $videos = $all | Where-Object {
        $_.vcodec -and $_.vcodec -ne 'none' -and
        ($_.acodec -eq $null -or $_.acodec -eq 'none') -and
        ($_.ext -eq 'mp4')
    }

    # Filter for M4A audio, English or US
    $audios = $all | Where-Object {
        $_.acodec -and $_.acodec -ne 'none' -and
        ($_.vcodec -eq $null -or $_.vcodec -eq 'none') -and
        ($_.ext -eq 'm4a') -and
        ($_.language -match '^en(-us)?$' -or $_.language -eq $null)
    }

    if (-not $videos -or -not $audios) { return $null }

    # Choose best (highest resolution) video
    $bestV = $videos | Sort-Object `
         @{ E = { [int]($_.height ?? 0) }; Descending = $true },
    @{ E = { [int]($_.fps ?? 0) }; Descending = $true },
    @{ E = { [double]($_.tbr ?? 0) }; Descending = $true } |
    Select-Object -First 1

    # Match audio by language (en-us first, then en, then fallback to highest bitrate)
    $bestA = $audios | Sort-Object `
         @{ E = { if ($_.language -eq 'en-us') { 3 } elseif ($_.language -eq 'en') { 2 } else { 1 } }; Descending = $true },
    @{ E = { [double]($_.abr ?? $_.tbr ?? 0) }; Descending = $true } |
    Select-Object -First 1

    if ($bestV -and $bestA) {
        [pscustomobject]@{
            FormatExpr = "$($bestV.format_id)+$($bestA.format_id)"
            VideoFormat = $bestV.format_id
            AudioFormat = $bestA.format_id
            VideoHeight = $bestV.height
            VideoFps = $bestV.fps
            AudioLang = $bestA.language
            AudioAbrKbps = $bestA.abr
        }
    } else {
        $null
    }
}



function Get-YtVideoJsonData {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Url")]
        [string]$Url
    )

    $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()

    [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()
    [void]$cmdargs.Add("--no-progress")
    [void]$cmdargs.Add("--dump-single-json")
    [void]$cmdargs.Add("--skip-download")
    [void]$cmdargs.Add($Url)



    $ProgramArgsSet = @{
        FilePath = $ytDlpPath
        ArgumentList = $cmdargs
        PassThru = $True
        Wait = $False
        NoNewWindow = $True
        RedirectStandardOutput = $stdout
        RedirectStandardError = $stderr
    }

    Write-Host "Getting Video Information for  " -f DarkGray -n
    Write-Host "$goodUrl" -f DarkYellow
    $cmdres = Start-Process @ProgramArgsSet
    Write-Host "please wait..." -f DarkCyan -n

    $IsDone = $False
    while (!$IsDone) {
        Start-Sleep -Milliseconds 200
        Write-Host "." -f DarkGray -n
        $IsDone = $cmdres.HasExited
    }

    $ExitCode = $cmdres.ExitCode
    $ts = [datetime]::Now - $cmdres.StartTime
    $tsstr = Out-TimeSpan $ts
    $Success = ($ExitCode -eq 0)
    Write-Host "`nProcess Terminated after " -f DarkYellow -n
    Write-Host "$tsstr" -f White
    if ($Success) {
        $JsonData = Get-Content -Path $stdout | ConvertFrom-Json -Depth 99
        if ($DebugSavePath) {
            Copy-Item $stdout $DebugSavePath -Force
            Write-Host "Write $DebugSavePath"
        }
        return $JsonData
    } else {
        Write-Host "Error Occured $ExitCode" -f DarkRed
    }
    return $Null

}
function Merge-VideoAudio {
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "VideoPath")]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [string]$VideoPath,

        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "AudioPath")]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [string]$AudioPath,

        [Parameter(Mandatory = $False, HelpMessage = "Output file path (optional)")]
        [string]$OutPath,


        [Parameter(Mandatory = $False, HelpMessage = "Container")]
        [ValidateSet('auto', 'mp4', 'mkv', 'webm')]
        [string]$Container = 'auto',

        [Parameter(Mandatory = $False, HelpMessage = "Force re-encode (H.264 + AAC)")]
        [switch]$Reencode
    )
    [string]$FFmpegPath = "C:\Programs\ffmpeg\ffmpeg.exe"
    # pick container if auto
    if ($Container -eq 'auto') {
        $vext = ([IO.Path]::GetExtension($VideoPath)).TrimStart('.').ToLowerInvariant()
        $aext = ([IO.Path]::GetExtension($AudioPath)).TrimStart('.').ToLowerInvariant()
        if ($vext -eq 'mp4' -and ($aext -in @('m4a', 'aac', 'mp4'))) { $Container = 'mp4' }
        elseif ($vext -eq 'webm' -and $aext -eq 'webm') { $Container = 'webm' }
        else { $Container = 'mkv' } # safest mux for mixed codecs
    }

    if (-not $OutPath) {
        $base = [IO.Path]::GetFileNameWithoutExtension($VideoPath)
        $dir = [IO.Path]::GetDirectoryName($VideoPath)
        $OutPath = Join-Path $dir "$base.merged.$Container"
    } else {
        $OutPath = Join-Path $dir "$OutPath.$Container"
    }

    $args = @('-y',
        '-i', $VideoPath,
        '-i', $AudioPath,
        '-map', '0:v:0',
        '-map', '1:a:0')

    if ($Reencode) {
        $args += @('-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18',
            '-c:a', 'aac', '-b:a', '192k')
    } else {
        $args += @('-c', 'copy')
    }

    $args += $OutPath

    if ($PSCmdlet.ShouldProcess($OutPath, "ffmpeg merge")) {
        & $FFmpegPath @args
        if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed with code $LASTEXITCODE" }
    }

    return $OutPath
}
