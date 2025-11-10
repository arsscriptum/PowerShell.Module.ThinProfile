#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ControlMouse.ps1                                                          ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-RegistryInstanceId {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        [string]$RegPath = Get-PSControlsRegistryRoot
        if (-not (Test-Path -Path $RegPath)) {
            Write-Warning "Registry path does not exist: $RegPath"
            return $null
        }

        $value = Get-ItemProperty -Path $RegPath -Name "InstanceId" -ErrorAction Stop
        return $value.InstanceId
    }
    catch {
        Write-Warning "InstanceId not found in $RegPath"
        return $null
    }
}



function Set-RegistryInstanceId {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "InstanceId string to store")]
        [ValidateNotNullOrEmpty()]
        [string]$InstId
    )

    try {
        [string]$RegPath = Get-PSControlsRegistryRoot
        if (-not (Test-Path -Path $RegPath)) {
            if ($PSCmdlet.ShouldProcess($RegPath, "Create registry key")) {
                New-Item -Path $RegPath -Force | Out-Null
            }
        }

        if ($PSCmdlet.ShouldProcess("$RegPath\InstanceId", "Set registry value")) {
            Set-ItemProperty -Path $RegPath -Name "InstanceId" -Value $InstId -Force
        }

        Write-Host "InstanceId successfully written to registry." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to write registry value: $_"
    }
}



function Get-PSControlsRegistryRoot {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\PowerShellInterfacesControls\Mouse"
    if (!(Test-Path "$RegKeyRoot")) {
        New-Item -Path "$RegKeyRoot" -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    $RegKeyRoot
}


function Disable-LocalMouse {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $NumberOfMouse = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Measure-Object | Select -ExpandProperty Count
    if ($NumberOfMouse -eq 0) {
        Write-Host "No Mouse to Disable!" -f DarkRed
        return
    }
    $FilePath = "$ENV:LOCALAPPDATA\PowerShellInterfacesControls\Mouse.uid"
    [string[]]$InstIds = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Select -ExpandProperty InstanceId
    $InstId = $InstIds[0]
    Disable-PnpDevice -InstanceId "$InstId" -Confirm:$false
    Remove-Item -Path "$FilePath" -Force -ErrorAction Ignore | Out-Null
    New-Item -Path "$FilePath" -ItemType File -Force -ErrorAction Ignore -Value "$InstId"
    Set-RegistryInstanceId "$InstId"
}


function Get-LocalMouseStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $NumberOfMouse = Get-PnpDevice -Class Mouse | Where Status -EQ OK | Measure-Object | Select -ExpandProperty Count
    Write-Host "Number of Enabled Mouse $NumberOfMouse" -f DarkGreen
    Get-PnpDevice -Class Mouse
}

function Enable-LocalMouse {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $FilePath = "$ENV:LOCALAPPDATA\PowerShellInterfacesControls\Mouse.uid"
    if (-not (Test-Path -Path $FilePath)) {
        $InstId = Get-RegistryInstanceId
    }
    else {
        $InstId = Get-Content -Path "$FilePath" -Raw
    }

    if (Get-PnpDevice -InstanceId "$InstId" -ErrorAction Ignore) {
        Enable-PnpDevice -InstanceId "$InstId" -Confirm:$false
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCd67OlisfB7Ijw
# TUTepnfnPkeNui+xECg6Eb2l9UzhZqCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBN
# SKyb5Yili+YFTjXH6jOBolhFUu0GZsk3gjFW0tB8FjANBgkqhkiG9w0BAQEFAASC
# AYDI8mLrS0DU70mZl5xpCJbk6JkAGW5Yp9YYzPot6xDJC9sgcfqHT8+pmBeO9n6M
# PPutrdmPD3R1txssVo9f88qi4tgRaaiEbIDZdg1M/zLGjBoZArEyU5KWDVOVlSq9
# cSgrqkXjhc37Pj94N1n9wGQ7GHWQ6HolCUMvP2cN6Rf1AD+26SsmMzL2biRF9viu
# 95Skw3MVPt67dL87saWrjQ4lDQ70N7hkfBVyu23x9/r/yPdZfbC68F/+UONNXp3D
# PchghuFZktlpqhLYuRKE7uPle16SWkMQRh8lZTzsAQnsalNlerS2S2kDq3Jtl7Z8
# laoFK0OayS+ZIohIxueDJZ/xfKcSMrl/87efH+FeBRBeN8jLc5YaG8swa3W7301F
# r0Cv8CdLUF2w/6ga3vcuofvN+clrak2esKDdNNh338qVcYCd+R2UBbhvZaztUgUT
# AZ9WGcwQiwuJbugMKCH0+dzybM5ZvI7qVBXgtq6DfaT47jTF8tGoecG2OXe41nGg
# N8Y=
# SIG # End signature block
