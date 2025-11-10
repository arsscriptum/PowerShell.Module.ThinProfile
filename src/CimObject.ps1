#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   CimObject.ps1                                                             ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-CompatWmiObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Class,
        [Parameter(Position = 1)]
        [string]$Namespace,
        [Parameter(Position = 2)]
        [string]$ComputerName
    )

    # Build splat for compatibility
    $splat = @{ }
    if ($Class)       { $splat['ClassName'] = $Class }
    if ($Namespace)   { $splat['Namespace'] = $Namespace }
    if ($ComputerName){ $splat['ComputerName'] = $ComputerName }

    if ($PSVersionTable.PSEdition -eq 'Core') {
        # PowerShell Core/7+ only has Get-CimInstance
        Get-CimInstance @splat
    } elseif (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        # Windows PowerShell 5.x
        # Slightly different parameter names
        $wsplat = @{ }
        if ($Class)       { $wsplat['Class']       = $Class }
        if ($Namespace)   { $wsplat['Namespace']   = $Namespace }
        if ($ComputerName){ $wsplat['ComputerName'] = $ComputerName }
        Get-WmiObject @wsplat
    } else {
        throw "Neither Get-CimInstance nor Get-WmiObject is available."
    }
}

# Remove existing Get-WmiObject if present
if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
    Remove-Item Function:\Get-WmiObject -ErrorAction SilentlyContinue
}

# Define Get-CompatWmiObject if not already present
if (-not (Get-Command Get-CompatWmiObject -ErrorAction SilentlyContinue)) {
    function Get-CompatWmiObject {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string]$Class,
            [Parameter(Position = 1)]
            [string]$Namespace,
            [Parameter(Position = 2)]
            [string]$ComputerName
        )

        $splat = @{ }
        if ($Class)        { $splat['ClassName']    = $Class }
        if ($Namespace)    { $splat['Namespace']    = $Namespace }
        if ($ComputerName) { $splat['ComputerName'] = $ComputerName }

        if ($PSVersionTable.PSEdition -eq 'Core') {
            Get-CimInstance @splat
        } elseif (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
            $wsplat = @{ }
            if ($Class)        { $wsplat['Class']        = $Class }
            if ($Namespace)    { $wsplat['Namespace']    = $Namespace }
            if ($ComputerName) { $wsplat['ComputerName'] = $ComputerName }
            Microsoft.PowerShell.Management\Get-WmiObject @wsplat
        } else {
            throw "Neither Get-CimInstance nor Get-WmiObject is available."
        }
    }
}

# Redefine Get-WmiObject to alias Get-CompatWmiObject
function Get-WmiObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Class,
        [Parameter(Position = 1)]
        [string]$Namespace,
        [Parameter(Position = 2)]
        [string]$ComputerName
    )
    Get-CompatWmiObject -Class $Class -Namespace $Namespace -ComputerName $ComputerName
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChZFWK3d+s4ch1
# Aa6p66oz/9XHRAZAodoGB3/IAuczjaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCE
# VIow+q2/6Uau/MX/mDdrJc5MkZ3VZk49UPZTw5UwOzANBgkqhkiG9w0BAQEFAASC
# AYBvpJpfnZiTvmFH39OcPoN/AvEenboqf2W/ZuUyjeK4+o6l8lqn/c9Xf8/EZcTS
# WTaDv9ongvB1iQ/nbNBLHYBX6V+aiUzeOjjmJVv8jznhYnaWd51om7GavhRCPBfd
# Hwk1LWWQm+HWG0seflhY9JnqBi71cVWij2zocuJpuka+rraDENYDf83uy+aDIh3G
# eOKzGqtCVTA8jjX8UqXeErRsDR827dIrlwp7EyQeUsNTHv28DjciYH1ZK7jszzjc
# WwU48B2uI3BIzGkvfuLVjQ5ijmKeqkibisQDzh7c4RwOjuIqqMXH6m0C5agRR6l6
# Q6UsW37fk5Y8hrNir0T1yv6MdNuT1/YyyZsJOebfk7w2QR19lXWxpA794eFMdtOO
# Hf2Zx97TT0elH1gWmJWw3oEVB3U7JvxrtEZXZxR96h4KuyRct+XfUeE09dI0GHVI
# 8CDbFUjzEwgwX+IBefGan8eliplA8ffbeg9i1dNwzK4/182clJgV+iHCX7PUG6Jx
# xhM=
# SIG # End signature block
