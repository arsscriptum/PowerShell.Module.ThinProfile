#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Aliases.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
New-Alias -Name x -Value Start-Explorer -Force -ErrorAction Ignore | Out-Null
new-alias -Name hist_search -Value Search-PsHistory -Force -ErrorAction Ignore | Out-Null
New-alias -Name DoScriptsCheck -Value Invoke-ValidateScriptsVersion -Force -ErrorAction Ignore | Out-Null
New-alias -Name touch -Value Invoke-TouchFile -Force -ErrorAction Ignore | Out-Null
New-alias -Name onlogin -Value Invoke-OnLoginFuncs -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_no -Value Disable-LocalMouse -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_go -Value Enable-LocalMouse -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_check -Value Get-LocalMouseStatus -Force -ErrorAction Ignore | Out-Null
New-alias -Name ytsave -Value Save-YtVideo -Force -ErrorAction Ignore | Out-Null

New-alias -Name zbookmount -Value Invoke-MountAllZbookShares -Force -ErrorAction Ignore | Out-Null

New-alias -Name wterm -Value Start-WindowsTerminal -Force -ErrorAction Ignore | Out-Null
New-alias -Name ycam -Value Start-YawcamJavaProcess -Force -ErrorAction Ignore | Out-Null

New-alias -Name copilot -Value Open-CoPilotDashboard -Force -ErrorAction Ignore | Out-Null

