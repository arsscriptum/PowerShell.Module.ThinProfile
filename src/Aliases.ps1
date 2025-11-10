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


# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC5rdzAGLqdJ4kf
# IckN99Ze4DQikhNjHQG9vU6y19XlCKCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCH
# AzcIGFt62wJRow7FOtKO2E/jqTelIVT+eIDt02h6MjANBgkqhkiG9w0BAQEFAASC
# AYAeSJZZvTig0k4hJyZ5sgplqDYw5OQBSInrHTcCcY9g2mbjrR0ctRQJZrmje7rU
# qKQO7tQ19aXN3BNX6BK9X4Up6I9VKVOmyk8fKUqaNPAkJ6O4NQsSJFTxSCcxmC9t
# 7zh6riNZM8rbAzMbVpPfdoM68H49XMiWUN2ceGP1VEKV2eM6KJFeCoOpecuIkvPE
# PDD9Y5ajfL/PR9EE6UcKLvqS4fFnu4SKF7O6if8babstNTRv96qohrRR/qollME3
# /p7D9K4IOGkQ52P21xIaD8396H6m8fzBdspme8KFUJ5KNukvzPAhJbcS666d+yCB
# vssRRpdQLHlEf8qSRQXoWEG46rQqIib9IM5aW8y7C8F46uZ/pqU7zDMj6fxE849O
# 0pOehF18pLORa1JJ4bIDTkybpNZQvzFJeVTISmOkcniKihoZC7GknKTxAfct3LhD
# fAmcikOin2D8cmZLnOod3Lwpf5P/IMcM6EJapGmYQ3U5SK9ARFScEIdVRJWiB9bR
# JCc=
# SIG # End signature block
