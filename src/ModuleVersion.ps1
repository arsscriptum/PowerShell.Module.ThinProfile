#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModuleVersion.ps1                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-ThinProfileModuleVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )


    if($Latest){
        Write-Verbose "[Get-ThinProfileModuleVersion] Get Latest (Online) $Latest"

        $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
        $JsonPath = Join-Path $ThinProfileVersionPath "ThinProfile.json"

        if (!(Test-Path $JsonPath)) {
            Write-Error "module not initialized! no file $JsonPath"
            return $Null
        }

        [version]$CurrVersion = Get-ThinProfileModuleVersion
        Write-Verbose "[Get-ThinProfileModuleVersion] CurrVersion $CurrVersion"
        Write-Verbose "[Get-ThinProfileModuleVersion] JsonPath $JsonPath"
        $Data = Get-Content $JsonPath | ConvertFrom-Json
        Write-Verbose "[Get-ThinProfileModuleVersion] JSON DATA`n------`n$Data`n-------`n"
        

        [version]$LatestVersion = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
        Write-Verbose "[Get-ThinProfileModuleVersion] LatestVersion $($LatestVersion.ToString())"
        return $LatestVersion.ToString()
    }else{
        Write-Verbose "[Get-ThinProfileModuleVersion] Get Local Version 1.0.86 "
    }

    $Version = "1.0.86"
    return $Version
}


# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCalTycFJwocBhd
# 5qaKWEc3W0nomUgW8HPW91m73L8z6KCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBB
# 7m2U/GgkLP2ILinVhcE8zM1VqvB+RMRhx7+ARG9LgTANBgkqhkiG9w0BAQEFAASC
# AYDNVyCccI0dpTEV206Nqght07R10076huDra4UQeomlsd8NYzJKWgmnAIBJ83Fi
# Zu/0MxBwFdeO0AVojMD1jshjWAI8FgvPHZl+KOOkvhQR1HeGL4QOgdb/+FRCC1/7
# VmlkuH8grDAWZ6BcTUaavD7/If9JnnrisJ7C5KaJq2W8uycE1Lu9+LyyiKQ3a4HS
# K9L2JHdbiCeWOtI89TeOGqEhkYnLUaIcbl0P9Bg7g6EDCGFmvTfz+eOtY1qis2fR
# Agnb4nhc4C8P3d6oCmLrp/l/IBDtSYuqR/ErNt645kWvxwcNGNnmfPkYCZPdf9mK
# BYNhM7LSfEMWzmflsXFPBsVTwK7K6wRyz9XLp7U0Oqd7yXMhdGgNsFGhDZb+96lh
# KuD2/UKRpW3BVycbHs03O2gZ5BrJFjXM7u3WHu5DzBj1YvyFToEuY5VacsZrqU1d
# nEU2NqP64JnUH+zPCo4Qq65SbI8+zst/TmQrTGFyzxyo4VeSZmfcr3gAEv4ehXUn
# mlM=
# SIG # End signature block
