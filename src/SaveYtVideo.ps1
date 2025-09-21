#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   SaveYtVideo.ps1                                                              ║
#║   Function to save Video Media                                                 ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Start-YtDlpProcess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Url")]
        [string[]]$Arguments
    )

    $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()

    [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()
    $Arguments | % {
        [void]$cmdargs.Add("$_")
    }



    $ProgramArgsSet = @{
        FilePath = $ytDlpPath
        ArgumentList = $cmdargs
        PassThru = $True
        Wait = $False
        NoNewWindow = $True
        RedirectStandardOutput = $stdout
        RedirectStandardError = $stderr
    }

    Write-Host "Starting to Download " -f DarkGray -n
    Write-Host "$goodUrl" -f DarkYellow
    $cmdres = Start-Process @ProgramArgsSet
    Write-Host "Download in progress" -f DarkCyan -n

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
        Write-Host "Done Successfully!" -f DarkGreen
    } else {
        Write-Host "Error Occured $ExitCode" -f DarkRed
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
    }
    process {
        foreach ($url in $Urls) {
            $goodUrl = Convert-YouTubeShortsUrl $url
            [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()
            [void]$cmdargs.Add("-f")
            [void]$cmdargs.Add("bv*+ba/best")
            [void]$cmdargs.Add($goodUrl)

            $s = Start-YtDlpProcess $cmdargs
            if (!$s) {

            }
        }
    }
}


function Get-YtVideoFormats {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory = $False, HelpMessage = "YtDlpPath")]
        [ValidateNotNullOrEmpty()]
        [string]$YtDlpPath = "C:\Python314\Scripts\yt-dlp.exe",

        [Parameter(Mandatory = $False, HelpMessage = "TimeoutSec")]
        [ValidateScript({ $_ -gt 0 })]
        [int]$TimeoutSec = 120
    )
    begin {
          $ytDlpPath = "C:\Python314\Scripts\yt-dlp.exe"
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()

    }
    process {
        # Build process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exe
        $psi.Arguments = '-J --no-warnings -- "' + $Url.Replace('"', '\"') + '"'
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi

        if (-not $p.Start()) { throw "Failed to start yt-dlp process." }

        if (-not $p.WaitForExit($TimeoutSec * 1000)) {
            try { $p.Kill() } catch {}
            throw "yt-dlp timed out after $TimeoutSec seconds."
        }

        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $exit = $p.ExitCode

        if ($exit -ne 0 -or [string]::IsNullOrWhiteSpace($stdout)) {
            $msg = if ($stderr) { $stderr.Trim() } else { "yt-dlp exited with code $exit." }
            throw "yt-dlp error: $msg"
        }

        # Parse JSON and project a clean object set
        $json = $null
        try { $json = $stdout | ConvertFrom-Json -Depth 20 -ErrorAction Stop }
        catch { throw "Failed to parse yt-dlp JSON. Raw length: $($stdout.Length). $_" }

        if (-not $json.formats) { return @() }

        $objs =
        $json.formats |
        ForEach-Object {
            $fs = $_.filesize
            if (-not $fs -and $_.filesize_approx) { $fs = $_.filesize_approx }
            [pscustomobject]@{
                FormatId = $_.format_id
                Container = $_.ext
                Protocol = $_.Protocol
                Note = $_.format_note
                Width = $_.Width
                Height = $_.Height
                Fps = $_.Fps
                VCodec = $_.VCodec
                ACodec = $_.ACodec
                TbrKbps = if ($_.tbr) { [double]$_.tbr * 1000 } else { $null } # yt-dlp tbr is in kbps
                VbrKbps = if ($_.vbr) { [double]$_.vbr * 1000 } else { $null }
                AbrKbps = if ($_.abr) { [double]$_.abr * 1000 } else { $null }
                filesize = $fs
                DynamicRange = $_.dynamic_range
                IsVideoOnly = ($_.ACodec -eq 'none' -and $_.VCodec -ne 'none')
                IsAudioOnly = ($_.VCodec -eq 'none' -and $_.ACodec -ne 'none')
                URL = $Url
            }
        } |
        Sort-Object @{ E = { ($_.Height, $_.Fps, $_.TbrKbps -as [double]) }; Descending = $true }, FormatId

        return , $objs
    }
}



function Get-YtVideoFormats {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Url")]
        [string]$Url,
        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Url")]
        [string]$DebugSavePath
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

    Write-Host "Starting  " -f DarkGray -n
    Write-Host "$goodUrl" -f DarkYellow
    $cmdres = Start-Process @ProgramArgsSet
    Write-Host "in progress" -f DarkCyan -n

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
        Write-Host "Done Successfully!" -f DarkGreen
        $JsonData = Get-Content -Path $stdout | ConvertFrom-Json -Depth 99
        if($DebugSavePath){
            Copy-Item $stdout $DebugSavePath -Force
            Write-Host "Write $DebugSavePath"
        }
        return $JsonData.formats
    } else {
        Write-Host "Error Occured $ExitCode" -f DarkRed
    }
    return $Null

}