#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModulesPathFunctions.ps1                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Push-ModAssert {  Write-Host "Pushd => $env:ModAssert" ; Push-location $env:ModAssert; }
function Push-ModClientTools {  Write-Host "Pushd => $env:ModClientTools" ; Push-location $env:ModClientTools; }
function Push-ModCompiler {  Write-Host "Pushd => $env:ModCompiler" ; Push-location $env:ModCompiler; }
function Push-ModCore {  Write-Host "Pushd => $env:ModCore" ; Push-location $env:ModCore; }
function Push-ModCryptography {  Write-Host "Pushd => $env:ModCryptography" ; Push-location $env:ModCryptography; }
function Push-ModDocker {  Write-Host "Pushd => $env:ModDocker" ; Push-location $env:ModDocker; }
function Push-ModDownloader {  Write-Host "Pushd => $env:ModDownloader" ; Push-location $env:ModDownloader; }
function Push-ModGithub {  Write-Host "Pushd => $env:ModGithub" ; Push-location $env:ModGithub; }
function Push-ModIniConfig {  Write-Host "Pushd => $env:ModIniConfig" ; Push-location $env:ModIniConfig; }
function Push-ModManageMini {  Write-Host "Pushd => $env:ModManageMini" ; Push-location $env:ModManageMini; }
function Push-ModMiniPc {  Write-Host "Pushd => $env:ModMiniPc" ; Push-location $env:ModMiniPc; }
function Push-ModNtRights {  Write-Host "Pushd => $env:ModNtRights" ; Push-location $env:ModNtRights; }
function Push-ModOpenHwdMon {  Write-Host "Pushd => $env:ModOpenHwdMon" ; Push-location $env:ModOpenHwdMon; }
function Push-ModPackageDownloader {  Write-Host "Pushd => $env:ModPackageDownloader" ; Push-location $env:ModPackageDownloader; }
function Push-ModProfileUtils {  Write-Host "Pushd => $env:ModProfileUtils" ; Push-location $env:ModProfileUtils; }
function Push-ModReddit {  Write-Host "Pushd => $env:ModReddit" ; Push-location $env:ModReddit; }
function Push-ModShellGPT {  Write-Host "Pushd => $env:ModShellGPT" ; Push-location $env:ModShellGPT; }
function Push-ModShim {  Write-Host "Pushd => $env:ModShim" ; Push-location $env:ModShim; }
function Push-ModTakeOwnership {  Write-Host "Pushd => $env:ModTakeOwnership" ; Push-location $env:ModTakeOwnership; }
function Push-ModTerminal {  Write-Host "Pushd => $env:ModTerminal" ; Push-location $env:ModTerminal; }
function Push-ModThinProfile {  Write-Host "Pushd => $env:ModThinProfile" ; Push-location $env:ModThinProfile; }
function Push-ModTools {  Write-Host "Pushd => $env:ModTools" ; Push-location $env:ModTools; }
function Push-ModWindowsHost {  Write-Host "Pushd => $env:ModWindowsHost" ; Push-location $env:ModWindowsHost; }
function Push-ModZBookHardware {  Write-Host "Pushd => $env:ModZBookHardware" ; Push-location $env:ModZBookHardware; }
function Push-Modter2K {  Write-Host "Pushd => $env:Modter2K" ; Push-location $env:Modter2K; }
function Push-VideoPath {  Write-Host "Pushd => $env:Modter2K" ; Push-location $env:Modter2K; }
# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDy4amO1Vnzeu0G
# Hbnx15pXk/g+tI9ESkeNmX33/d2LXaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDh
# v/2LixJ9qIOBiVK8XI/CgSVYUwxOqZqd707v8jhgSzANBgkqhkiG9w0BAQEFAASC
# AYCqNDc1Zxpbgd7Zj1X1mKELNaMo6aPCFuudi1+SM+J/bhsAEt3tnfNUV4Yw7giG
# xSvTAJmxrtyDCidDjvLul9A2MPJvVRmYgY+XwoIUy6HV3dCJIxRwSmdHhdzJkcdS
# a0TfW+9Q+kKzv/PB1gdxFMOf/x4TBYozmv1iLLYMW2vLFwO/YV9W0fk1NbDHt8jC
# NYSNmmzSqPBI/bbqhVxHsxqA/lMsJyrlM8Xs5q2MGtks8KRWYOqFSHHSla3Paii1
# H7s239cM7KGSbeYfOMCuJ1m7+8GpA6OhfQ35FFpSXUJyAaoggwDoBxqnQGfZMu/D
# iE/xfyOWqfeev8XLbIkIPrDP3iXGSBbaoeUG3j6Oyju3jinsERAlmApeJeGD1cNh
# BHK2WEsWSvD40yFMKfaSrKqb867abUp/EMc6moYuxOGLZ9i0Ym0HcocPOQkmwSGz
# hiSTYJUANB2EYLMyLpaPmR12G5z7Kikcurt7pAcX64SdIOpLIB6XUiHOO0av/2sc
# RD4=
# SIG # End signature block
