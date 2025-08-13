




function Read-TaskNotifyLogFile {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $LogFile = "$ENV:Temp\task_notify.log"
    get-content "$LogFile" | Select -Last 10

}

function Invoke-StartNotify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(60, 3600)]
        [int]$RepeatInterval = 60,
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Delay = 30
    )
    try {

        $UseVbs = $True

        $ScriptData = @"

function Show-LowMemoryNotificationFR {{
    [CmdletBinding(SupportsShouldProcess = `$false)]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    `$notify = New-Object System.Windows.Forms.NotifyIcon
    `$notify.Icon = [System.Drawing.SystemIcons]::Warning
    `$notify.Visible = `$true
    `$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
    `$notify.BalloonTipTitle = `"Mémoire très faible`"
    `$notify.BalloonTipText  = `"La mémoire est très faible et le système pourrait devenir instable.`"

    # Show for 10 seconds
    `$notify.ShowBalloonTip(10000)

    # Give time for the notification to display before cleanup
    Start-Sleep -Seconds 12
    `$notify.Dispose()
}}

Show-LowMemoryNotificationFR


"@
        $LogFile = "$ENV:Temp\task_notify.log"
        [string]$ScriptString = $ScriptData -f $Minutes, $Delay

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        $now = [datetime]::Now.AddSeconds(10)
        # Example Usage
        $selectedUser = Select-LoggedInUser
        Write-Host "You selected: $selectedUser"

        [string]$TaskName = "NotifyDelayedRemote"

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

        [string]$ArgumentString = "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand {0}" -f $ScriptBase64
        Write-host "Create Scheduled Task with Base64 Encoded Command"

        if ($UseVbs) {
            New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null

            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
            $WScriptBin = $WScriptCmd.Source
            $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"

        } else {
            $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $ScriptBase64"
        }

        $Trigger = New-ScheduledTaskTrigger -At $now -Once:$false
        if ($RepeatInterval -gt 0) {
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Delay) -RepetitionDuration ([timespan]::FromDays(1)) -RepetitionInterval (New-TimeSpan -Seconds $RepeatInterval)
        }
        
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -LogonType Interactive -RunLevel Highest
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal

        write-host "Register and Run Task"
        Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null
        Add-SchedTasks -TaskName $TaskName
        Start-ScheduledTask -TaskName $TaskName

        Write-Host "In 10 seconds... $LogFile"

    } catch {
        write-error "$_"
    }

}

function Invoke-StopNotify {
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
        [string]$TaskName = "NotifyDelayedRemote"
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
        [string[]]$Res = & "C:\Windows\system32\taskkill.exe" "/IM" "powershell.exe" "/F" 2> "$ENV:Temp\killres.txt"
        $Killed = $Res.Count
        Write-Host "NumPowershell $NumPowershell Killed $Killed"

    } catch {
        write-error "$_"
    }

}
