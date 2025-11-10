#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Convert.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Out-TimeSpan {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "The TimeSpan to format")]
        [timespan]$TimeSpan
    )
    process {
        $parts = @()
        if ($TimeSpan.Days)         { $DayUnit = if ($TimeSpan.Days -gt 1)    {'days'}  else {'day'}  ; $parts += "$($TimeSpan.Days) $DayUnit"  }
        if ($TimeSpan.Hours)        { $HrsUnit = if ($TimeSpan.Hours -gt 1)   {'hours'} else {'hour'} ; $parts += "$($TimeSpan.Hours) $HrsUnit" }
        if ($TimeSpan.Minutes)      { $MinUnit = if ($TimeSpan.Minutes -gt 1) {'mins'}  else {'min'}  ; $parts += "$($TimeSpan.Minutes) $MinUnit" }
        if ($TimeSpan.Seconds)      { $SecUnit = if ($TimeSpan.Seconds -gt 1) {'secs'}  else {'sec'}  ; $parts += "$($TimeSpan.Seconds) $SecUnit" }
        if ($TimeSpan.Milliseconds) { $parts += "$($TimeSpan.Milliseconds) ms" }
        if (-not $parts) { $parts = "0 sec" }
        $parts -join ', '
    }


}


function Convert-YouTubeShortsUrl {
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, HelpMessage = "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )
    begin {
        $ShortsPrefix = 'https://www.youtube.com/shorts/'
        $WatchPrefix = 'https://www.youtube.com/watch?v='
    }
    process {
        if (-not $Url.StartsWith($ShortsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $Url
        }

        $tail = $Url.Substring($ShortsPrefix.Length)
        $videoId = ($tail -split '[/?#&]')[0]

        if ([string]::IsNullOrWhiteSpace($videoId)) {
            throw "Invalid YouTube Shorts URL: missing video id. Url: $Url"
        }
        if ($videoId.Length -ne 11 -or ($videoId -notmatch '^[A-Za-z0-9_]{11}$')) {
            throw "Invalid YouTube video id '$videoId' (must be 11 alphanumeric)."
        }

        '{0}{1}' -f $WatchPrefix, $videoId
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZqMsEfPthRRoU
# /+2vcLnSlywfEFp1z3dYIKRmemo2g6CCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAK
# Gq0OnWMPhLAV2+dY9WBbu3WFqkG0tvSWo8YFSZnJTzANBgkqhkiG9w0BAQEFAASC
# AYCkrNl3WQYUBXKlauW7ZDJq1gk3QdXqSat4k7GX5R7M7bUzc/f7NKRf52f0CpcS
# o6FWF+UmNRvhmkG3DEPZH8GQoNy0DkKt0JThqlrRKgWxkoYen5MU42J/cTqiHNaN
# EpJD6FqfeG5oTu0yOZd/Uhtjhsy0clqmUxy7TKH+HY8Z3NEppFrEd/JButsnMLk7
# eRsXLWiwSF+eGwBetV9UyU/fj4J+8O/BXt6JXN11pgjiaWNY+kiTnzoaeB6jdE4a
# f5ayEoYyJz7FZ7w60JbXiG0WdJ7FmGGfPqCI6Gz4PryTb9KCONhCDIssBxjX4vkk
# GoY8WhklVBnnpCUwVQcLEZXzvLa9XdSHztsxGdBLZa5tRKo3hC9DhOdEYzGVIzJm
# 5L0ONk7lOcb8K6pnkZ0RRZVmZKbeBGMwkBmZOAilFbYhArK5kRwGrA5faxZjfN+m
# apS+rA19Lyv2H8ja4d7CZHuRovH556RMzQb0QaMJMpNWTsrhNQynrgMCJMnggeDs
# WOw=
# SIG # End signature block
