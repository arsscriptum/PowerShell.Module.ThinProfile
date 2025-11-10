#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   WinUpdateNotify.ps1                                                       ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-XamlUiContent {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    [xml]$xaml_v1 = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Critical Update" WindowStyle="None" ResizeMode="NoResize"
        WindowState="Maximized" Background="White" Topmost="True"
        ShowInTaskbar="False">
    <Grid>
        <Border Background="#f0f0f0" BorderBrush="#0078D7" BorderThickness="10" CornerRadius="0">
            <Grid>
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock Text="Windows Update" FontSize="48" FontWeight="Bold"
                               Foreground="#0078D7" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                    <TextBlock Text="A critical security update is in progress." FontSize="26"
                               HorizontalAlignment="Center" TextAlignment="Center" Margin="0,0,0,10"/>
                    <TextBlock Text="⚠️ DO NOT RESTART YOUR COMPUTER ⚠️" FontSize="32" FontWeight="Bold"
                               Foreground="Red" HorizontalAlignment="Center" Margin="0,0,0,30"/>
                    <TextBlock Text="Restarting may result in system instability or data loss."
                               FontSize="20" HorizontalAlignment="Center" TextAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    [xml]$xaml_v2 = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Critical Update" WindowStyle="None" ResizeMode="NoResize"
        WindowState="Maximized" Background="White" Topmost="True"
        ShowInTaskbar="False">
    <Grid>
        <Border Background="#f0f0f0" BorderBrush="#0078D7" BorderThickness="10" CornerRadius="0">
            <Grid>
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock x:Name="TitleText" Text="Windows Update" FontSize="48" FontWeight="Bold"
                               Foreground="#0078D7" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                    <TextBlock Text="A critical security update is in progress." FontSize="26"
                               HorizontalAlignment="Center" TextAlignment="Center" Margin="0,0,0,10"/>
                    <TextBlock Text="⚠️ DO NOT RESTART YOUR COMPUTER ⚠️" FontSize="32" FontWeight="Bold"
                               Foreground="Red" HorizontalAlignment="Center" Margin="0,0,0,30"/>
                    <TextBlock Text="Restarting may result in system instability or data loss."
                               FontSize="20" HorizontalAlignment="Center" TextAlignment="Center"/>
                    <TextBlock x:Name="CountdownText" Text="Estimated completion in 05:00"
                               FontSize="22" FontWeight="Normal" Foreground="Black"
                               HorizontalAlignment="Center" Margin="0,40,0,0"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@


    return $xaml_v2
}

function Invoke-WinUpdateTask {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [Alias('v')]
        [switch]$UseVbs
    )
    try {

        $Script = @"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[xml]`$xaml = @`"
<Window xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`"
        xmlns:x=`"http://schemas.microsoft.com/winfx/2006/xaml`"
        Title=`"Critical Update`" WindowStyle=`"None`" ResizeMode=`"NoResize`"
        WindowState=`"Maximized`" Background=`"White`" Topmost=`"True`"
        ShowInTaskbar=`"False`">
    <Grid>
        <Border Background=`"#f0f0f0`" BorderBrush=`"#0078D7`" BorderThickness=`"10`" CornerRadius=`"0`">
            <Grid>
                <StackPanel VerticalAlignment=`"Center`" HorizontalAlignment=`"Center`">
                    <TextBlock x:Name=`"TitleText`" Text=`"Windows Update`" FontSize=`"48`" FontWeight=`"Bold`"
                               Foreground=`"#0078D7`" HorizontalAlignment=`"Center`" Margin=`"0,0,0,20`"/>
                    <TextBlock Text=`"{0}`" FontSize=`"26`"
                               HorizontalAlignment=`"Center`" TextAlignment=`"Center`" Margin=`"0,0,0,10`"/>
                    <TextBlock Text=`"⚠️ DO NOT RESTART YOUR COMPUTER ⚠️`" FontSize=`"32`" FontWeight=`"Bold`"
                               Foreground=`"Red`" HorizontalAlignment=`"Center`" Margin=`"0,0,0,30`"/>
                    <TextBlock Text=`"Restarting may result in system instability or data loss.`"
                               FontSize=`"20`" HorizontalAlignment=`"Center`" TextAlignment=`"Center`"/>
                    <TextBlock x:Name=`"CountdownText`" Text=`"Estimated completion in 05:00`"
                               FontSize=`"22`" FontWeight=`"Normal`" Foreground=`"Black`"
                               HorizontalAlignment=`"Center`" Margin=`"0,40,0,0`"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
`"@


  `$reader = (New-Object System.Xml.XmlNodeReader `$xaml)
        `$window = [Windows.Markup.XamlReader]::Load(`$reader)
        # Get reference to countdown text element
        `$CountdownText = `$window.FindName(`"CountdownText`")

        #`$CountdownText.Foreground = 'Red'  # Named color


        # Register Ctrl+G handler
        `$window.AddHandler([System.Windows.Window]::KeyDownEvent,
            [System.Windows.Input.KeyEventHandler]{{
                param(`$sender, `$e)
                if (`$e.Key -eq `"G`" -and
                    ([System.Windows.Input.Keyboard]::IsKeyDown(`"LeftCtrl`") -or
                        [System.Windows.Input.Keyboard]::IsKeyDown(`"RightCtrl`"))) {{
                    `$sender.Close()
                }}

            }})

        # Timer logic
        `$duration = New-TimeSpan -Hours 3 # or adjust as needed
        `$endTime = (Get-Date).Add(`$duration)

        # Update function
        `$updateAction = {{
            `$remaining = `$endTime - (Get-Date)
            if (`$remaining.TotalSeconds -le 0) {{
                `$CountdownText.Dispatcher.Invoke([action]{{ `$CountdownText.Text = `"Finalizing update...`" }})
                return
            }}
            `$CountdownText.Dispatcher.Invoke([action]{{
                    `$CountdownText.Text = `"Estimated completion in {{0:mm\:ss}}`" -f `$remaining
                }})
        }}

        # Timer to update countdown every second
        `$dispatcherTimer = New-Object System.Windows.Threading.DispatcherTimer
        `$dispatcherTimer.Interval = [timespan]::FromSeconds(1)
        `$dispatcherTimer.Add_Tick(`$updateAction)
        `$dispatcherTimer.Start()


        # Test mode auto-close
        if (`$DryRun) {{
            `$autoCloseTimer = New-Object System.Timers.Timer
            `$autoCloseTimer.Interval = `$WaitFor
            `$autoCloseTimer.AutoReset = `$false
            `$autoCloseTimer.add_Elapsed({{
                    `$window.Dispatcher.Invoke([action]{{ `$window.Close() }})
                }})
            `$autoCloseTimer.Start()
        }}

        # Show UI
        `$null = `$window.ShowDialog()
}}
"@




        [string]$ScriptString = $Script -f "A critical security update is in progress."

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        [bool]$DryRun = $False
        if ($Test) {
            $DryRun = $True
        }
        # Example Usage
        $selectedUser = Select-LoggedInUser
        Write-Host "You selected: $selectedUser"

        [string]$TaskName = "WinUpdateUIMessage"

        try {
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }



        [string]$folder = Invoke-EnsureSharedScriptFolder
        [string]$VBSFile = Join-Path "$folder" "hidden_WinUpdateUIMessage.vbs"
        [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -EncodedCommand $ScriptBase64", 0, False
"@

        if ($UseVbs) {
            New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null

            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
            $WScriptBin = $WScriptCmd.Source
            $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"
        } else {

            [string]$ArgumentString = "-ExecutionPolicy Bypass -EncodedCommand {0}" -f $ScriptBase64
            Write-host "Create Scheduled Task with Base64 Encoded Command"
            $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -EncodedComma
nd $ScriptBase64"
        }
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -LogonType Interactive -RunLevel Highest
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal


    } catch {
        write-error "$_"
    }

}


function Show-LocalWinUpdateNotification {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$GeneralMessage,
        [Parameter(Mandatory = $false)]
        [Alias('m')]
        [string]$SpecificMessage,
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 5000)]
        [Alias('w')]
        [int]$WaitFor = 3000,
        [Parameter(Mandatory = $false)]
        [Alias('v')]
        [switch]$HideTimer,
        [Parameter(Mandatory = $false)]
        [Alias('t')]
        [switch]$TestMode
    )
    try {
        $XamlStaticData = Get-XamlUiContent



        [string]$GeneralMsg = '"A Critical Security Update Is Currently Being Installed"'
        [string]$SpecificMsg = '"IMPORTANT: Do not restart the computer, it will restart automatically after the update."'
        if (![string]::IsNullOrEmpty($GeneralMessage)) {
            $GeneralMsg = "`"$GeneralMessage`""
        }
        if (![string]::IsNullOrEmpty($SpecificMessage)) {
            $SpecificMsg = "`"$SpecificMessage`""
        }
        [string]$ScriptString = $Script -f $GeneralMsg, $SpecificMsg, $Color, $TextColor

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        [bool]$DryRun = $False
        if ($TestMode) {
            $DryRun = $True
        }

        # Load the XAML UI
        $reader = (New-Object System.Xml.XmlNodeReader $XamlStaticData)
        $window = [Windows.Markup.XamlReader]::Load($reader)
        # Get reference to countdown text element
        $CountdownText = $window.FindName("CountdownText")

        #$CountdownText.Foreground = 'Red'  # Named color


        # Register Ctrl+G handler
        $window.AddHandler([System.Windows.Window]::KeyDownEvent,
            [System.Windows.Input.KeyEventHandler]{
                param($sender, $e)
                if ($e.Key -eq "G" -and
                    ([System.Windows.Input.Keyboard]::IsKeyDown("LeftCtrl") -or
                        [System.Windows.Input.Keyboard]::IsKeyDown("RightCtrl"))) {
                    $sender.Close()
                }

            })

        # Timer logic
        $duration = New-TimeSpan -Hours 3 # or adjust as needed
        $endTime = (Get-Date).Add($duration)

        # Update function
        $updateAction = {
            $remaining = $endTime - (Get-Date)
            if ($remaining.TotalSeconds -le 0) {
                $CountdownText.Dispatcher.Invoke([action]{ $CountdownText.Text = "Finalizing update..." })
                return
            }
            $CountdownText.Dispatcher.Invoke([action]{
                    $CountdownText.Text = "Estimated completion in {0:mm\:ss}" -f $remaining
                })
        }

        # Timer to update countdown every second
        $dispatcherTimer = New-Object System.Windows.Threading.DispatcherTimer
        $dispatcherTimer.Interval = [timespan]::FromSeconds(1)
        $dispatcherTimer.Add_Tick($updateAction)
        $dispatcherTimer.Start()


        # Test mode auto-close
        if ($DryRun) {
            $autoCloseTimer = New-Object System.Timers.Timer
            $autoCloseTimer.Interval = $WaitFor
            $autoCloseTimer.AutoReset = $false
            $autoCloseTimer.add_Elapsed({
                    $window.Dispatcher.Invoke([action]{ $window.Close() })
                })
            $autoCloseTimer.Start()
        }
        if ($HideTimer) {
            $CountdownText.Dispatcher.Invoke([action]{
                    $CountdownText.Visibility = [System.Windows.Visibility]::Collapsed
                })
        }

        # Show UI
        $null = $window.ShowDialog()
    } catch {
        write-error "$_"
    }

}


function Show-LowMemoryNotificationFR {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param()

    # Load WinRT API
    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    # French message
    $title   = "Mémoire très faible"
    $message = "La mémoire est très faible et le système pourrait devenir instable."

    # Build Toast XML
    $toastXml = @"
<toast activationType="foreground" scenario="reminder">
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$message</text>
    </binding>
  </visual>
</toast>
"@

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($toastXml)

    # Get a toast notifier
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Alerte Système")
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)

    # Show the notification
    $notifier.Show($toast)
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0snVbt1DsJpRj
# U9h2AkL28Jk/ZOJFVNYTqW13tjlgLKCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# Jm2adS91JTa6q0Z+JiwfmghXiG1HI+SbkfXuFWXjiTANBgkqhkiG9w0BAQEFAASC
# AYCQWF+UBbcLrsGOLlszto0c++fqIxJM4sKkfnfJP6yAKir9FQs2uer0FOHSH+8f
# DftwmysMM2aqZVvFTtZHkcH8fUVp0j7wEGS5Saa6wqyYJX1rBVyeE4JqryhuVs//
# Vm8qv8p+Pvw0FKDNQEMM9uMiWUbPq1zcMnphbP/UcN8exMbECRPJies+B3CJLgHM
# FwellnmTEggHdJjBeD1PVjXGOeEv97TWyMvNewVK0HwfkArFnbi766wkB6EP5JID
# iqS9UYEKM/QwSWw5inKVfNpW8A1lXNCazeSE3KtrupfNv1mkE2yA3RqNptmXUQhf
# xuO5mO+XbNyIFJpN+CECiZxTiYRehqntXbUwPCuoSqFjDtwO6vdCKrT3K2Os6Pw6
# rw4XSZmjIjT0f+fOGi6cnlnU5ara3Ph+SY6GPBtYBGBPSNj8+IQYsNI1GSQh1uuJ
# mpf1P47dU7YKHi26G25jYr444FweI3f/ErDYt9DvhEcdlXIoALBN2fW5h72ybSsN
# wuE=
# SIG # End signature block
