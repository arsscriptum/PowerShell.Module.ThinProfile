#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ManageScreenshots.ps1                                                     ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Invoke-ManageScreenshotArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'Maximum archive size in MB')]
        [ValidateRange(1, 1024)]
        [int]$MaxArchiveSizeMB = 25,

        [Parameter(Mandatory = $false, HelpMessage = 'Maximum file age in days')]
        [ValidateRange(1, 365)]
        [int]$MaxFileAgeDays = 7,

        [Parameter(Mandatory = $false, HelpMessage = 'Screenshots source folder')]
        [string]$SourcePath = "C:\ProgramData\Screenshots",

        [Parameter(Mandatory = $false, HelpMessage = 'Archive folder')]
        [string]$ArchivePath = "C:\ProgramData\Screenshots\Archives",
        [Parameter(Mandatory = $false, HelpMessage = 'Maximum file age in days')]
        [switch]$Clean
    )

    try {
        # Ensure archive folder exists
        if (-not (Test-Path $ArchivePath)) {
            New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
        }



        # Move all .png files to the archive
        $filesToMove = Get-ChildItem -Path $SourcePath -Filter "*.png" -File -ErrorAction SilentlyContinue
        if($Clean){
            Remove-Item -Path "$SourcePath\*.png" -Force | Out-Null
            Remove-Item -Path $ArchivePath -Force -Recurse | Out-Null
            New-Item -Path $ArchivePath -Force -ItemType Directory | Out-Null
            Write-Host "Removed All Files..." -f DarkRed
            return
        }elseif ($filesToMove) {
            Write-Verbose "Moving $($filesToMove.Count) file(s) to archive..."
            Move-Item -Path $filesToMove.FullName -Destination $ArchivePath -Force
        }


        # Delete files older than MaxFileAgeDays
        $cutOffDate = (Get-Date).AddDays(-$MaxFileAgeDays)
        $oldFiles = Get-ChildItem -Path $ArchivePath -File | Where-Object { $_.LastWriteTime -lt $cutOffDate }
        foreach ($file in $oldFiles) {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Delete old file")) {
                Remove-Item -Path $file.FullName -Force
            }
        }

        # Check total size and reduce until < MaxArchiveSizeMB
        $sizeLimitBytes = $MaxArchiveSizeMB * 1MB
        $archiveFiles = Get-ChildItem -Path $ArchivePath -File | Sort-Object LastWriteTime
        $totalSize = ($archiveFiles | Measure-Object Length -Sum).Sum

        while ($totalSize -gt $sizeLimitBytes -and $archiveFiles.Count -gt 0) {
            $oldestFile = $archiveFiles[0]
            if ($PSCmdlet.ShouldProcess($oldestFile.FullName, "Delete to maintain size limit")) {
                Remove-Item -Path $oldestFile.FullName -Force
                Write-Verbose "Deleted: $($oldestFile.Name) to maintain archive size."
            }

            # Update file list and total size
            $archiveFiles = Get-ChildItem -Path $ArchivePath -File | Sort-Object LastWriteTime
            $totalSize = ($archiveFiles | Measure-Object Length -Sum).Sum
        }

        $Log = "Archive maintenance complete. Current archive size: {0:N2} MB" -f ($totalSize / 1MB)
        Write-Host "$Log"
    }
    catch {
        Write-Error "Error managing screenshot archive: $_"
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBXclCTS4yebQLj
# XXKTVlXlVNTY97/fxhC9YG5yCrHLsKCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD6
# cYRnKQY5eQGkqiHhSdUzvemj4+OcgOcoYPh8sJZ1vTANBgkqhkiG9w0BAQEFAASC
# AYDD9Jm8qhLn1EDF5wnP86RH2n4WUCMMXa6QZpJTA+pePgQDjsA27knC3ULX5F8L
# eNU3ZQ6Gmq4KyXXdHNH/HgRXiG3VZAcdcvAqq9dyuGyV+NXvOFQAAWDfJy0Hfo0E
# ddPA2sbbNsDV7HI01Z2SZ7flTWARMnho3UP3cTQO01hDbTbXNY4NCJN766PO+cMW
# W7A4uXX6Jr0MIqsXnHqe2+PPvhKASwWxxA0Sy1K+OTcQlS8h/YOC29Stip62bAeO
# fFkWj2LaFUHr187kHDn20GZa7IK/vk2LoGGj38qX+YH6g+y/hvrw6tDdnA9MNN2v
# BAbIOlGaRXt4Juqsj+vWHFcLJr3ziS440gQQm9B9+AKBaye6AoJboMgA3ADTtaHp
# 5FytQmPZ0McFc3DVAtkwSPb/UKGuI6qTL5CxcfLQFsZLrts8YHvx2eP0sQwsjvY/
# fedt/ETyujorqXPq7qgdJgEBpj25UV06TrhDzDr/Q4CVPnxvLGYc4k5EooTWrOF5
# T7s=
# SIG # End signature block
