#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ImportIcons.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
# Convert-PngsToIco "C:\Users\gp\Pictures" "C:\Users\gp\Images\icons"
function Convert-PngsToIco {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SourceDir,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DestDir           
    )

    $MagickExe = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"

    if (-not (Test-Path $DestDir)) {
        New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
    }

    $pngFiles = Get-ChildItem -Path $SourceDir -Filter *.png -File

    foreach ($file in $pngFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $safeBase = $baseName -replace ' ', ''
        $icoName = "$safeBase.ico"
        $icoPath = Join-Path $DestDir $icoName

        $args = @("""$($file.FullName)""", "-resize", "256x256", """$icoPath""")
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()

        $proc = Start-Process -FilePath $MagickExe -ArgumentList $args `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr

        if ($proc.ExitCode -ne 0) {
            Write-Warning "Failed to convert $($file.Name): $(Get-Content $stderr -Raw)"
        } else {
            Write-Host "Converted $($file.Name) -> $icoName"
        }

        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}
# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBTH643R4wKPYp4
# Xhnee89GOLC8f3+QYRPHE3c2OKz1j6CCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDN
# /UNvZd091y87IyC7UUdBpOOJ1kahZIolzGMnTsvwSDANBgkqhkiG9w0BAQEFAASC
# AYAHqlLh/+FQnl6z4d1p1E1CfknOmV4LhrQUyx7lXBmbJuL00ZY1faWrRgf/VPGE
# x5xHvc7T8I7eRgVjWZAM48pCKxkROvuigFh1hfi8ADTrjuF5w+et/JxoAaWfXW34
# Aob/ny3nloxsgYWBuCpk1s95Kz8ONdMTsdolMRSn3b/VJhDA2GcvlB770l0CARxD
# 2GHFxiT7EKNvkLEBT7xqcL+dO/OlTa7HgRyaPT4pncX2wI/1pr2sZtJAQ02x4lcI
# FTZgHimiaLiVrc4uHhdUXuPUMs7bz0Mna5c3O0YLL+WLYdL6IOgeIlPzXGqfZNbM
# cFiBLQ1CMFumiFeeB3gpXk7vtgg4FVxQcZ8n3rq3wgub3o/H+1CSfo2gKUT2KlHs
# t8uEDh8GCYR1aLtIHMo9JOXE21DPATOBiLvlgwfunEJIcX/V9jmhXGXRJMtgsjtD
# Ag7c8Y+F0ofZp8TOqR96s4waRxkKwApkazm7lAgVYtsXSNKo1IP08wCi6NtUVVCq
# 41o=
# SIG # End signature block
