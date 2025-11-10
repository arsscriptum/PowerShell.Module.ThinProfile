#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   StartYawCam.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Start-YawcamJavaProcess {
    [CmdletBinding()]
    param()

    [string]$JavaExePath = "C:\Program Files (x86)\Common Files\Oracle\Java\javapath\javaw.exe"
    [string]$WorkingDirectory = "C:\Programs\Yawcam"
    [System.Collections.ArrayList]$classPaths = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$cmdArgs = [System.Collections.ArrayList]::new()
    [void]$classPaths.Add(".")
    [void]$classPaths.Add("lib/activation.jar")
    [void]$classPaths.Add("lib/commons-jxpath-1.1.jar")
    [void]$classPaths.Add("lib/commons-logging.jar")
    [void]$classPaths.Add("lib/commons-logging-api.jar")
    [void]$classPaths.Add("lib/dsj.jar")
    [void]$classPaths.Add("lib/monte-cc.jar")
    [void]$classPaths.Add("lib/mail.jar")
    [void]$classPaths.Add("lib/mx4j-impl.jar")
    [void]$classPaths.Add("lib/mx4j-jmx.jar")
    [void]$classPaths.Add("lib/mx4j-remote.jar")
    [void]$classPaths.Add("lib/mx4j-tools.jar")
    [void]$classPaths.Add("lib/sbbi-jmx-1.0.jar")
    [void]$classPaths.Add("lib/sbbi-upnplib-1.0.4.jar")
    [void]$classPaths.Add("lib/ftp4j.jar")
    [void]$classPaths.Add("lib/commons-codec-1.4.jar")
    [void]$classPaths.Add("lib/turbojpeg.jar")
    [void]$classPaths.Add("lib/system-event.jar")
    $classpathStrArgs = $classPaths -join ";"

    [void]$cmdArgs.Add("-cp")
    [void]$cmdArgs.Add("$classpathStrArgs")
    [void]$cmdArgs.Add("-Djava.net.preferIPv4Stack=true")
    [void]$cmdArgs.Add("-splash:img/splash.gif")
    [void]$cmdArgs.Add("yawcam.Main")
    $argumentsStr = $cmdArgs -join " "
     #Write-HOst "$JavaExePath $argumentsStr" -f Magenta
    $ProgramArgsSet = @{
        FilePath = $JavaExePath
        ArgumentList = $cmdArgs
        PassThru = $False
        Wait = $False
        WindowStyle = 'Hidden'
        WorkingDirectory = $WorkingDirectory
    }
    Start-Process @ProgramArgsSet

}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCClGF2B+fH2nkIY
# weEUGbkz12/MhyY1iCbEl7Kf3mptSqCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD+
# LtCqnflP9RZ4NOB/Y3YG/mHAsyF3k4X0G26v74fHPDANBgkqhkiG9w0BAQEFAASC
# AYAOJOvzhhXEcyt6+mw60eBrsDwL/CxdmBwdU4+0Zguhc1Zq5J75ZwM+AEoVKRo8
# tm8dqyb4FRyYi7DW/cIBF5/8V1xnu7SUSiCHJfJg/DkEZkLp+mpoj0pIgAsYtqIn
# j8h1d+Pk4WxOs/njcWQTIN+4jHls6wJa0sghHBCE4a87tnYlhz4wI+QOhinqiFep
# EhRSbWhYiT79w6s5lC7JyQ3BdG3Ge47zTj/ZjTQt1YY0TcoUa1ajMFQlMAUHC7AT
# XnGnVSiK4CE2TPayLxGLpAYDXq3lo436H7S38L+v6FOKfR0LwnWe24YwDLz6ZNEI
# uNrkBu0bytByQsV0HfwTDa2yek+G8b4c5waPVdbGwYJDbpLGybLBGLu9yrbJdQQG
# PFl9f4oeVUAyjKOHflvEoJdN9nUwBEF6Mnypm0xm19N3K3qhpYaMgxlsQdSHL5kZ
# 46bpWxYFJ2DfhWqmQIezauKbF1cUo6lhFUoZiF1xQ1NbiDdMUCKez5le+papQ59V
# pwM=
# SIG # End signature block
