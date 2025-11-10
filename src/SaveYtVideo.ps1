#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   SaveYtVideo.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
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
        [Alias('d')]
        [switch]$DumpOutput
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
            if ($DumpOutput) {
                $outstr = Get-Content $stdout -Raw
                Write-Host "$outstr" -f DarkGreen
            }

        } else {
            Write-Host "[$String] Error Occured $ExitCode" -f DarkRed
            if ($DumpOutput) {
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

            $s = Start-YtDlpProcess $ccdefault "$DefaultFormat" -d
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

                $sv = Start-YtDlpProcess $ccv "137 VIDEO ONLY" -d
                $sa = Start-YtDlpProcess $cca "140 AUDIO ONLY" -d
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

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBZUM2RPSt24n2n
# 5NqL/c33Mw862mU+/Q0oUFwqr52QPaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
# p0U/KDSBkGfnMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI0d1aWxsYXVtZSBQ
# bGFudGUgKERldiBDb2RlIFNpZ25pbmcpMB4XDTI1MTExMDAxMzk1MVoXDTI4MTEx
# MDAxNDk1MFowLjEsMCoGA1UEAwwjR3VpbGxhdW1lIFBsYW50ZSAoRGV2IENvZGUg
# U2lnbmluZykwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDNtS5Po9Nh
# zeqSwRPGh7K9cW2vIzSjyQSe+RwMf9uqvtWSgQ1NdYVz2BHaCY2P6+nyaPwj6IqY
# OnWI2NI6iPTSbOZgGot7KI7m7PyLnXlTeLROt77j9uoYqSlFdt0AAIGULpzPBH+a
# L7fp81YQtgEANaAgHx9+DcvyBBnVNirUyL8qgxXrGiERX73FC7Xjp0ZwhPNiE6Qn
# GH62IhZHEhpevLFvHPA049DBoo3J1x1AFzTVRpWEpQiy2PzMiYQzHtjTdggLcEUM
# 4AaK8E8koLvehCs4Su0XetmF3mBExAhKTZe0X9sPzvpn77698N2SPnlPmnal7Evv
# XvN3UVB8I6dwQsSDth52EXWU8dHoBdR/Fr3K6ncj3Tr2Lt2QhRtWFVBL91YiXl8z
# Ki+pGC1URu+3mJgeIv6djB38WFVUOwveI914UKL8834H0xYKnzjRsgcAMI1cu3BA
# 9W1GCEaDOmxL9PX1QzfgpgGyXW9klqMhCFBhtO048hXpgruamHBVER0CAwEAAaNG
# MEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQW
# BBQyHm576+dQI3D2EeTojJF7IUH2eTANBgkqhkiG9w0BAQsFAAOCAYEAMuuH5/Ru
# wEm6w1nNYcixd9yWRgK6I6egsIHmuKJNvZU3sXZKBrDZqW1cTOcgezXgzkInfO7/
# nY54DuG4Y1CP1caL80F8WRouSptwd7RJmKwd9lAUsPjaLDZt+Asa3OjYwIlB3Y5Q
# sbFMs1QXZzLI2TBAJ8hYRnagEx20YLvzvF75Re8SlgzmI/G5tR7fsyz9+xTrJtAo
# H1rXhTMid5rYPNwnJs3htwHesUUY1f+SL4Lx904zut8tFlSjNSPFkDGU2PJzcjNf
# 1zButoZe7rwuIB9NLCBwBEuBzxuqxwRGPwl5Xesa49fPhieUQCYxYcVFs0SZbqul
# wlX8LjhQp10bat3KqzZiYJ5vb5zWXopHbvC22DvOMrUV7dCX5L1jcsXa0FB0SAc5
# pxd+46MarKv3GYjgKhqJ6N1+4YIMkAQ0z4OSXPcMHSDFzAL17EPInDBGXDsaaRmR
# w6eNDXRkW/zBgU0VkROO/IJucQIl8wrwqdMQO4Y+67OIqUJ0VQ216XCQMYICdDCC
# AnACAQEwQjAuMSwwKgYDVQQDDCNHdWlsbGF1bWUgUGxhbnRlIChEZXYgQ29kZSBT
# aWduaW5nKQIQFIjQDRt846dFPyg0gZBn5zANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBo
# zfuS4yvInXDMbfiw3zYEm+dgP+NyVUr3GBhVJoVDrjANBgkqhkiG9w0BAQEFAASC
# AYBJZTfmJFx3P4fCHdCySizhauKce9BSOZmaMFZJ+/hZRkCwq3xta2Dkp5gwNsz7
# d/Hjzp7n/+0qjj87ydUaftBAO8guRVYz6pDISY0vL3Y/xEtSo9v0IQRTplJXL0OT
# vnKhKCpIUl/X8coK3++Mxp/n2nOpwfZdr4OlNpKWTj6axzq9ACUUU4F1/LwglIjF
# vz8SCBw88anSFo01zqhbQJopkbNAYy8rwsGpVQ3fV0VQhjzh4SwrwC9MrFCGB8Yk
# hkr7f9kkzsBnEBQm1zcILjrXEcNm9D06usP+pWisu+XVT5nVcjH/OTsxty1C6Rbs
# FPnRjibyxMmvW2mnJYtbY8xZ7TYYxN2k5Yw7eqcXoYLuCJDvcKJDGikOZ0oc5+Nu
# xhbOfwocHxP3E9dkHziCWvfwTBf3d5zMMT/a4hv6oMDjykJ9Z/V9q/1bxwRwJbtW
# ccmjPwf2DW+uO2Bl2bfyhfPnHc4IqLjgRotrOpkp2NI+p3ss/ljp6C+5lsUPnwPd
# VWw=
# SIG # End signature block
