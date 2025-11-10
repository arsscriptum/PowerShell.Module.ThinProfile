#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModulesPathAliases.ps1                                                    ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
New-Alias ModAssert -Value "Push-ModAssert" -Description "Push-location $env:ModAssert" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModClientTools -Value "Push-ModClientTools" -Description "Push-location $env:ModClientTools" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCompiler -Value "Push-ModCompiler" -Description "Push-location $env:ModCompiler" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCore -Value "Push-ModCore" -Description "Push-location $env:ModCore" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCryptography -Value "Push-ModCryptography" -Description "Push-location $env:ModCryptography" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModDocker -Value "Push-ModDocker" -Description "Push-location $env:ModDocker" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModDownloader -Value "Push-ModDownloader" -Description "Push-location $env:ModDownloader" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModGithub -Value "Push-ModGithub" -Description "Push-location $env:ModGithub" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModIniConfig -Value "Push-ModIniConfig" -Description "Push-location $env:ModIniConfig" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModManageMini -Value "Push-ModManageMini" -Description "Push-location $env:ModManageMini" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModMiniPc -Value "Push-ModMiniPc" -Description "Push-location $env:ModMiniPc" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModNtRights -Value "Push-ModNtRights" -Description "Push-location $env:ModNtRights" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModOpenHwdMon -Value "Push-ModOpenHwdMon" -Description "Push-location $env:ModOpenHwdMon" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModPackageDownloader -Value "Push-ModPackageDownloader" -Description "Push-location $env:ModPackageDownloader" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModProfileUtils -Value "Push-ModProfileUtils" -Description "Push-location $env:ModProfileUtils" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModReddit -Value "Push-ModReddit" -Description "Push-location $env:ModReddit" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModShellGPT -Value "Push-ModShellGPT" -Description "Push-location $env:ModShellGPT" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModShim -Value "Push-ModShim" -Description "Push-location $env:ModShim" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTakeOwnership -Value "Push-ModTakeOwnership" -Description "Push-location $env:ModTakeOwnership" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTerminal -Value "Push-ModTerminal" -Description "Push-location $env:ModTerminal" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModThinProfile -Value "Push-ModThinProfile" -Description "Push-location $env:ModThinProfile" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTools -Value "Push-ModTools" -Description "Push-location $env:ModTools" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModWindowsHost -Value "Push-ModWindowsHost" -Description "Push-location $env:ModWindowsHost" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModZBookHardware -Value "Push-ModZBookHardware" -Description "Push-location $env:ModZBookHardware" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias Modter2K -Value "Push-Modter2K" -Description "Push-location $env:Modter2K" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBoNyXzUEHjh9Jn
# xU6N9BwP79tWBmAyEhZXwmdo4qVryKCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDT
# 3FlfYFVT8bHr6Y0VChicOHNq3BOWVSaPXYNvnGYauzANBgkqhkiG9w0BAQEFAASC
# AYCvpYN0I3qazN0nNM5DbIFJDBfz1eG4L7FaGZGBhkCpc/9bFyv14SDUJoj1BcSM
# xNJVpuA9XYBgiVnsdhNcwyr5Eg3uil3+j/8zidQ7cSO1hn6tr3UbLI/3kZFyXxSQ
# YOcKbfS5cHNYkl5tTVvqBZOp6pYkmGwbH/S69Hkl+m5OUHcICXfIRnjD/2UMEsUY
# Rlwqp158lPtHm4o5xW84tuzZD9AV2mHQ7yLM77w4z2bN+JmSEa7ALSQjORw08XyS
# 6eZavBGTR8dEO2up5v4G16dOAfYa7+m/O3s5FcrIyRMUPON2T4YLkflx9ZiOGXLb
# x0FaKibOhc6SkfJLGs+NG7tM7/rApFYrd+lr3F9zoztrBzM7qxSVD0elGEt5LoBG
# 5YAltDp8Qlq1OQssKCbVVTNXsBjTSNC9W4eS8UyyGEzviZllZjgRMWhCE2+xEBPF
# zpg5j1AN8PWqNNHgh2m7UhEwcDlST65uZmQjUsiDoleZcdxAJaOoK2QlAX8q2eyd
# uZ0=
# SIG # End signature block
