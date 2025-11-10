#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   OpenPage.ps1                                                              ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Save-CurrentPidToTempFile {
    [CmdletBinding()]
    param()

    $processIdFile = Join-Path -Path $ENV:TEMP -ChildPath "OpenPage.pid"
    try {
        $PID | Out-File -FilePath $processIdFile -Encoding ASCII -Force
        Write-Host "Saved current PID $PID to '$processIdFile'" -ForegroundColor Green
    } catch {
        Write-Error "Failed to save PID: $_"
    }
}

function Read-OpenCustomPageLogFile {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    $LogFile = "$ENV:Temp\task_OpenCustomPage.log"
    get-content "$LogFile" | Select -Last 10

}

function Stop-PidFromTempFile {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $processIdFile = Join-Path -Path $ENV:TEMP -ChildPath "OpenPage.pid"
    if (!(Test-Path $processIdFile)) {
        Write-Warning "PID file not found: $processIdFile"
        return
    }

    try {
        $processIdToKill = Get-Content -Path $processIdFile -Raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
        if (-not $processIdToKill) {
            Write-Warning "No valid PID found in file"
            return
        }

        $proc = Get-Process -Id $processIdToKill -ErrorAction SilentlyContinue
        if ($proc) {
            if ($PSCmdlet.ShouldProcess("PID $processIdToKill", "Stop-Process")) {
                Stop-Process -Id $processIdToKill -Force
                Write-Host "Process $processIdToKill stopped." -ForegroundColor Yellow
            }
        } else {
            Write-Warning "No process found with PID $processIdToKill"
        }
    } catch {
        Write-Error "Failed to stop process: $_"
    }
}


function New-OpenPageTask {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(position = 0, Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 15,
        [Parameter(Mandatory = $false, HelpMessage = "Repeat interval in seconds.")]
        [switch]$UseVbs
    )
    try {

        $Script = @"

function Open-CustomPage {{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    `$LogFile = "`$ENV:Temp\task_OpenCustomPage.log"
    `$processIdFile = Join-Path -Path `$ENV:TEMP -ChildPath `"OpenPage.pid`"
    try {{
        `$PID | Out-File -FilePath `$processIdFile -Encoding ASCII -Force
        Write-Host `"Saved current PID `$PID to '`$processIdFile'`" -ForegroundColor Green
    }} catch {{
        Write-Verbose `"Failed to save PID: `$_`"
    }}

    `$url = `"{0}`"
    `$chromePath = `"`$ENV:ProgramFiles\Google\Chrome\Application\chrome.exe`"
    if (Test-Path `$chromePath) {{
        Add-Content -Path `"`$LogFile`" -Value `"OPEN CUSTOM PAGE `$url using `$chromePath`"
        Start-Process -FilePath `$chromePath -ArgumentList `"--new-window`", `"`$url`"
    }} else {{
        Add-Content -Path `"`$LogFile`" -Value `"OPEN CUSTOM PAGE `$url using Start-Process`"
        Start-Process `$url
    }}

}}
Open-CustomPage


"@

        $LogFile = "$ENV:Temp\task_OpenCustomPage.log"
        $LogDate = (get-date).GetDateTimeFormats()[20] -as [string]
        if (!(Test-Path "$LogFile")) {
            New-Item -Path "$LogFile" -Force -ItemType File -Value "============ LOG STARTED on $LogDate ============`n" | out-null
        }
        [string]$ScriptString = $Script -f $Url

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        $now = [datetime]::Now.AddSeconds($Delay)
        # Example Usage
        $selectedUser = Select-LoggedInUser
        Write-Host "You selected: $selectedUser"

        #[string]$TaskName = "OpenPage-" + "$(((New-guid).guid).Substring(0,5))"
        [string]$TaskName = "OpenPage"

        try {
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }

        [string]$ar = "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand {0}" -f $ScriptBase64


        if ($UseVbs) {
            [string]$folder = Invoke-EnsureSharedScriptFolder
            [string]$VBSFile = Join-Path "$folder" "OpenPageTask.vbs"
            [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe $ar", 0, False
"@
            New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null
            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
            $WScriptBin = $WScriptCmd.Source
            $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"
        }
        else {
            $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument $ar
        }


        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
        $Trigger = New-ScheduledTaskTrigger -At $now -Once:$false
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -LogonType Interactive -RunLevel Highest
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

        write-host "Register and Run Task"
        Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null
        Add-SchedTasks -TaskName $TaskName
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "In $Delay seconds... $LogFile"

    } catch {
        write-error "$_"
    }

}

function Invoke-OpenPageSecurityAdvisory {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 15,
        [Parameter(Mandatory = $false, HelpMessage = "Repeat interval in seconds.")]
        [switch]$UseVbs
    )
    try {
        $Url = "https://www.cyber.gc.ca/fr/alertes-avis/al25-009-vulnerabilite-touchant-microsoft-sharepoint-server-cve-2025-53770"
        New-OpenPageTask -Url $Url -Delay $Delay -UseVbs:$UseVbs
    } catch {
        write-error "$_"
    }

}

function Invoke-OpenPageDesjardins {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 15,
        [Parameter(Mandatory = $false, HelpMessage = "Repeat interval in seconds.")]
        [switch]$UseVbs
    )
    try {
        $Url = "https://accesdc.mouv.desjardins.com/accueil"
        New-OpenPageTask -Url $Url -Delay $Delay -UseVbs:$UseVbs
    } catch {
        write-error "$_"
    }

}

function Stop-OpenPageTask {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        [string]$TaskName = "OpenPage"
        [int]$NumPowershell = (tasklist | Select-String "powershell" -Raw | measure).Count
        try {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }
        Stop-PidFromTempFile

    } catch {
        write-error "$_"
    }

}

function Stop-PowerShellProcesses {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        [string[]]$Res = & "C:\Windows\system32\taskkill.exe" "/IM" "powershell.exe" "/F" 2> "$ENV:Temp\killres.txt"
        $Killed = $Res.Count
        Write-Host "NumPowershell $NumPowershell Killed $Killed"
    } catch {
        write-error "$_"
    }

}



# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDF6q4HYG2Uevej
# Zf6jCiiDu2xndNq2oriZwxeeBv6QSaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBY
# 5JQHUCLvvSbJg5VdY2P0JalbIwxvR40jmP9SJvTPKTANBgkqhkiG9w0BAQEFAASC
# AYBqExESZTu49kqHb2073M0h5BE8eT+Qo4Yv5a54d9cOx8ys/qh2+oEF/FiFf2Ht
# 04lA63rH8/swkOnXbSGsic+8Rqh1O0B9GRnHqJUI/R5qEyEkcfQ9Rl2YeiswQW9u
# S9vz5JkbU1ZPQBu7E6aTmw7oZGCdBpi4B/NoQlJs2Jg4L5IWC6OYeGoNdq/mn7r2
# AXnVFHtdWqdroreD6Lfku7bwytjO91cXyFOzEPW/xgii2/D1l309BjzqJ/lSO4NJ
# 40peMVUZDNExEy1doIHSuVjMD7d8r3adraDYZoLyA0n1GitHhZl0rTxpmQfIvnJD
# XUy6dM4GMux76bLvS2JFHQ1yz/osutnQweemjV/9+6/piJDew3ltokzzEEtWZd3r
# E2WpGr2Oz5g9jNdpc9RyKcMgHa56dnJfHsmMSYifOqyAuePb1EaR42cEYZYkufO2
# DMOHtsxW5c2GV9AV+xmoLHxuZFA8xiut4FTwa1p2AecQDyQPAWz0wUDmcpXt7TxB
# CTQ=
# SIG # End signature block
