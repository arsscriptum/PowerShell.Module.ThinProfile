#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   alias.ps1                                                                    ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

New-Alias -Name x -Value Start-Explorer -Force -ErrorAction Ignore | Out-Null
new-alias -Name hist_search -Value Search-PsHistory -Force -ErrorAction Ignore | Out-Null
New-alias -Name DoScriptsCheck -Value Invoke-ValidateScriptsVersion -Force -ErrorAction Ignore | Out-Null
New-alias -Name touch -Value Invoke-TouchFile -Force -ErrorAction Ignore | Out-Null
New-alias -Name onlogin -Value Invoke-OnLoginFuncs -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_no -Value Disable-LocalMouse -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_go -Value Enable-LocalMouse -Force -ErrorAction Ignore | Out-Null
New-alias -Name mouse_check -Value Get-LocalMouseStatus -Force -ErrorAction Ignore | Out-Null