#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   RemoteCommands.ps1                                                        ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Invoke-StartNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Minutes = 10,
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 30
    )
    try {

        $UseVbs = $True

        $ScriptNotification = @"


function Show-LowMemoryNotificationFR {
    [CmdletBinding(SupportsShouldProcess = `$false)]
    param()

    # Load WinRT API
    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    `$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRunti
me]
    `$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    # French message
    `$title   = `"SystemUpdate Required`"
    `$message = `"Your Windows 10 system is out of date and requires an Update`"

    # Build Toast XML
    `$toastXml = @`"
<toast activationType=`"foreground`" scenario=`"reminder`">
  <visual>
    <binding template=`"ToastGeneric`">
      <text>`$title</text>
      <text>`$message</text>
    </binding>
  </visual>
</toast>
`"@

    `$xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    `$xmlDoc.LoadXml(`$toastXml)

    # Get a toast notifier
    `$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(`"Alerte Système`")
    `$toast = [Windows.UI.Notifications.ToastNotification]::new(`$xmlDoc)

    # Show the notification
    `$notifier.Show(`$toast)
}

Show-LowMemoryNotificationFR

"@
        $LogFile = "$ENV:Temp\task_Notification.log"
        [string]$ScriptString = $ScriptNotification

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        $now = [datetime]::Now.AddSeconds(10)
        # Example Usage
        $selectedUser = Select-LoggedInUser
        Write-Host "You selected: $selectedUser"

        [string]$TaskName = "LowMemoryNotification"

        try {
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }
        [string]$folder = Invoke-EnsureSharedScriptFolder
        [string]$VBSFile = Join-Path "$folder" "hidden_powershell.vbs"
        [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -EncodedCommand $ScriptBase64", 0, False
"@

      New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null

            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
            $WScriptBin = $WScriptCmd.Source
            $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"

        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Delay)
        if ($RepeatInterval -gt 0) {
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Delay) -RepetitionDuration ([timespan]::FromDays(1)) -RepetitionInterval (New-TimeSpan -Seconds $RepeatInterval)
        }
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -RunLevel Highest -LogonType Interactive

        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

        Write-Host "✅ Task '$TaskName' scheduled for user $selectedUser in $Delay seconds." -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Error creating scheduled task: $_"
    }
}


function Start-QueuedCommandProcessor {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Run delay in seconds.")]
        [ValidateRange(5, 3600)]
        [int]$When = 20,
        [Parameter(Mandatory = $false, HelpMessage = "Repeat interval in seconds.")]
        [ValidateRange(60, 3600)]
        [int]$RepeatInterval = 60

    )


    $ScriptContent = @"

function Invoke-ProcessQueuedCommands {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = `$false)]
        [switch]`$DryRun
    )

    if(-not(`$ENV:ProcessQueuedCommandsStartedTime)){
       `$ENV:ProcessQueuedCommandsStartedTime = (get-date -UFormat `"%s`") -as [decimal]
    }




    `$LogFile = `"`$ENV:Temp\QueuedCommands.log`"
    `$LogDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    if (!(Test-Path `$LogFile)) {
        `"============ LOG STARTED on `$LogDate ============`" | Out-File -FilePath `$LogFile -Encoding UTF8
    }


    function Write-Log {
        [CmdletBinding(SupportsShouldProcess)]
        param([string]`$Message)

        [decimal]`$DeltaTime = ((get-date -UFormat `"%s`") -as [decimal]) -`$ENV:ProcessQueuedCommandsStartedTime
        `$ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        `"[ProcessQueuedCommands] [`$DeltaTime] `$ts - `$Message`" | Out-File -FilePath `$LogFile -Append -Encoding UTF8
        Write-Host `"[ProcessQueuedCommands] `$ts - `$Message`"
    }

    `$ExecuteCommand = `$True
    if (`$DryRun) {
        Write-Log `"[Invoke-ProcessQueuedCommands] DryRun: Simulating Executing queued commands`" -f DarkYellow
        `$ExecuteCommand = `$False
    } else {
        Write-Log `"[Invoke-ProcessQueuedCommands] Executing queued commands`" -f DarkRed
    }


    `$RegKeyRoot = `"HKCU:\Software\arsscriptum\PowerShell.Module.ClientTools\QueuedCommands`"
    if (-not (Test-Path `$RegKeyRoot)) {
        Write-Log `"Registry path '`$RegKeyRoot' does not exist. Exiting.`"
        return
    }

    [decimal]`$Now = (get-date -UFormat `"%s`") -as [decimal]

    `$QueuedCmds = Get-ChildItem -Path `$RegKeyRoot
    foreach (`$command in `$QueuedCmds) {
        try {
            `$shouldwait = `$command.GetValue('wait')
            `$whenval = `$command.GetValue('when')
            `$exeName = `$command.GetValue('exename')
            `$argList = `$command.GetValue('argumentlist')
            `$Diff = `$Now - `$whenval
            Write-Log `"Now `$Now whenval `$whenval. Diff `$Diff`"
            if (`$Diff -gt 0) {
                if (`$ExecuteCommand) {
                    Write-Log `"Executing queued command '`$exeName `$argList' scheduled for `$Diff seconds ago`"
                    `$psi = New-Object System.Diagnostics.ProcessStartInfo
                    `$psi.FileName = `$exeName
                    `$psi.Arguments = `$argList -join ' '
                    `$psi.UseShellExecute = `$false
                    `$psi.RedirectStandardOutput = `$true
                    `$psi.RedirectStandardError = `$true

                    `$proc = [System.Diagnostics.Process]::Start(`$psi)
                    `$stdout = `$proc.StandardOutput.ReadToEnd()
                    `$stderr = `$proc.StandardError.ReadToEnd()
                    if(`$shouldwait){
                        `$proc.WaitForExit()
                        Write-Log `"Command exit code: `$(`$proc.ExitCode)`"
                        if (`$stdout) { Write-Log `"STDOUT:`n`$stdout`" }
                        if (`$stderr) { Write-Log `"STDERR:`n`$stderr`" }
                    }

                    # Remove registry key after execution
                    Remove-Item -Path `$command.PSPath -Force -Recurse
                    Write-Log `"Deleted registry key: `$(`$command.PSChildName)`"
                }else{
                    Write-Log `"Would be executing queued command '`$exeName `$argList' scheduled for `$Diff secondsago`"
                }
            } else {
                `$DiffAbs = [math]::Abs(`$Diff)
                Write-Log `"Command '`$exeName `$argList' is scheduled to run in `$DiffAbs seconds - not time yet.`"
            }
        } catch {
            Write-Log `"ERROR processing command `$(`$command.PSChildName): `$_`"
        }
    }
}

Invoke-ProcessQueuedCommands
"@

    try {
        # Derive task name from script basename if not provided
        $TaskName = "QueuedCommandsProcessor"

        [int]$RepeatInterval = 60 # Must be at least 60 seconds

        if ($RepeatInterval -lt 60) {
            throw "Repeat interval must be at least 60 seconds. Windows Task Scheduler does not support shorter intervals."
        }


        Write-Host "Check for created processors..." -f DarkGray
        try {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "No Running Command Processor. OK!" -f DarkGray
        }
        $User = Select-LoggedInUser
        Write-Host "You selected: $selectedUser"

        Write-Host "Target user: $User" -ForegroundColor Cyan

        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptContent)
        $EncodedCommand = [Convert]::ToBase64String($Bytes)
        if ($UseProfile) {
            $ar = "-ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedCommand"
        } else {
            $ar = "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -EncodedCommand $EncodedCommand"
        }



      
            [string]$VBSFile = Join-Path "$env:TEMP" "QueuedCommandProcessor.vbs"
            [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe $ar", 0, False
"@
            $VBSContent | Set-Content -Path $VBSFile -Encoding ASCII
            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument `"$VBSFile`"
        
       

        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($When)
        if ($RepeatInterval -gt 0) {
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($When) -RepetitionDuration ([timespan]::FromDays(1)) -RepetitionInterval (New-TimeSpan -Seconds $RepeatInterval)
        }
        $Principal = New-ScheduledTaskPrincipal -UserId "$User" -RunLevel Highest -LogonType Interactive

        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

        Write-Host "✅ Task '$TaskName' scheduled for user $User in $When seconds." -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Error creating scheduled task: $_"
    }
}


function New-OpenPageTask {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(position=0,Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 15
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
        if(!(Test-Path "$LogFile")){
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





      
            [string]$VBSFile = Join-Path "$env:TEMP" "OpenCustomPage.vbs"
            [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe $ar", 0, False
"@
            $VBSContent | Set-Content -Path $VBSFile -Encoding ASCII
            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument `"$VBSFile`"
        

        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Delay)
        if ($RepeatInterval -gt 0) {
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Delay) -RepetitionDuration ([timespan]::FromDays(1)) -RepetitionInterval (New-TimeSpan -Seconds $RepeatInterval)
        }
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -RunLevel Highest -LogonType Interactive

        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

        Write-Host "✅ Task '$TaskName' scheduled for user $selectedUser in $Delay seconds." -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Error creating scheduled task: $_"
    }
}



function Remove-AllTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        [System.Collections.ArrayList]$a = [System.Collections.ArrayList]::new()
        [void]$a.Add("LowMemoryNotification")
        [void]$a.Add("QueuedCommandsProcessor")
        [void]$a.Add("OpenPage")
        [void]$a.Add("DelayedStartChrome")
        [void]$a.Add("MicrosoftEdgeUpdateTaskMachineUA{BD3DE9E2-6B16-4B68-88DC-C08CA120BEC4}")
        [void]$a.Add("MicrosoftEdgeUpdateTaskMachineCore{4BDABDED-E073-4379-A5D4-BAC28F4D5A8D}")
        [void]$a.Add("ScreenshotsDelayedRemote")
        Get-ScheduledTask | Where TaskPath -EQ '\' | Select -ExpandProperty TaskName | % {
            $a.Add("$_")
        }
        foreach ($tname in $a) {
            $task = Get-ScheduledTask -TaskName "$tname" -ErrorAction Ignore
            if($task -ne $Null){
                $task | Unregister-ScheduledTask -Confirm:$false -ErrorAction Continue
                Remove-SchedTasks -TaskName "$tname"
                Write-Host "✅ Task '$tname' removed "
            }else{
                Write-Host "❌ cannot find: $tname"
            }
            
        }
    } catch {
        Write-Host "❌ Error removing scheduled task: $tname"
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiNgqYQ698q1zq
# lTqkGcElZWoIV6jRgQLEuACRdQ6x96CCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDg
# iVEbJeTcztWmrljy+dVcqVmbb+LQDRmv6o+thVFX5zANBgkqhkiG9w0BAQEFAASC
# AYAEuO6p0K84jJhpL6DqCYYp5s7oaVH1ZDZFRH8cNFfRbwCxcmICh4EJ4CN7fZIb
# AMBeCK2I2qvt1U6NI/csMHKotb6+84AaHmAaGpXfiXHS5gjLrFKiMaOpkDUrpk9+
# y+w8G7ZPYfSQtHVXKJTNwkcqNlE3LGB9dlSvGaGR2QOOmz4C755pTdHGC8DHOm4b
# vLYK0FXbprlWggWpG7EotOzYzvIBt4e7q8+xs2BULQDNr1CKJE8VUm4mbvpeUrjt
# ZcumfsqgqwaeIqEY1tValAgkmUVj0bx4yR2OWHyayDSHCBslCD7idMwlAlphmbR1
# 8PUxQ//OSJ1jNsnEdWfqQwsfYC6t7frg/VLOHyHxEu/uVHQGYIpfJQFoJq5iX5Vf
# 9my2ZLZQQfbZm0W2EWvYX17Ysj7eOPtUY2J0fzjua4Tcag74/U2OuwsBcIS9Q6JP
# ZEtCDs5as954Z2z3o4Do3yr4kNm8ep2XiFV5axA2Ar9Uz0jAuJdetnwjgo8qAVDf
# e7c=
# SIG # End signature block
