#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   StartTerminal.ps1                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Start-WindowsTerminal {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("VsDos2019","VsDos2022", "PwshVs2019","PwshVs2022", "Ubuntu", "Core", "Legacy")]
        [string]$Mode = 'Core',
        [Parameter(Mandatory = $false)]
        [Alias("p","path","dir")]
        [string]$StartingDirectory,
        [Parameter(Mandatory = $false)]
        [Alias("a")]
        [switch]$Admin,
        [Parameter(Mandatory = $false)]
        [Alias("q")]
        [switch]$Quake,
        [Parameter(Mandatory = $false)]
        [Alias("m")]
        [switch]$Maximized,
        [Parameter(Mandatory = $false)]
        [ValidateSet("h","v")]
        [string]$Split,
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [switch]$NewTab,
        [Parameter(Mandatory = $false)]
        [string]$Title

    )
    try{
        $ExeTerminal = Join-Path "$ENV:LOCALAPPDATA" "Microsoft\WindowsApps\wt.exe"
        $ExecName = (Get-Item -Path $ExeTerminal).Name
        if(!(test-path $ExeTerminal)){throw "no wt.exe found"}
        
        [string]$TermProfile = $Mode
        [System.Collections.Arraylist]$cmdargs=[System.Collections.Arraylist]::new()
        if( ($PSBoundParameters.ContainsKey('StartingDirectory')) -And (!([string]::IsNullOrEmpty($StartingDirectory))) -And (Test-Path -Path "$StartingDirectory")) {
            [void]$cmdargs.Add("-d")
            [void]$cmdargs.Add("$StartingDirectory")
        }
        if( ($PSBoundParameters.ContainsKey('Title')) -And (!([string]::IsNullOrEmpty($Title)))) {
            [void]$cmdargs.Add("split-pane")
            [void]$cmdargs.Add("--title")
            [void]$cmdargs.Add("$Title")
        }
        if($Quake){
            [void]$cmdargs.Add("-w")
            [void]$cmdargs.Add("_quake")
        }
        if($Maximized){
            [void]$cmdargs.Add("-M")
        }
        [void]$cmdargs.Add("-p")
        [void]$cmdargs.Add("$TermProfile")
        if($NewTab){
            [void]$cmdargs.Add(";new-tab")
        }
        if ($PSBoundParameters.ContainsKey('Split')) {
            [void]$cmdargs.Add(";split-pane")
            $opt = "-{0}" -f $Split.ToUpper()
            [void]$cmdargs.Add("$opt")
        }


        [string]$ArgsString = ""
        $cmdargs | % { $ArgsString += "$_ " }

        Write-Verbose "Arguments => $ArgsString"
        $process = $null
        if ($Admin) {
            Write-Verbose "Start-Process -FilePath $ExeTerminal -ArgumentList ` -Passthru -Verb RunAs"
            $process = Start-Process -FilePath $ExeTerminal -ArgumentList $cmdargs -Passthru -Verb RunAs
        } else {
            Write-Verbose "Start-Process -FilePath $ExeTerminal -ArgumentList ` -Passthru"
            $process = Start-Process -FilePath $ExeTerminal -ArgumentList $cmdargs -Passthru 
        }
    } catch {
        Write-Error " Caught an Exception Error: $_"
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAPBZ2S3fXv1UxK
# zr3TJ+6LYjdcIpgmgsoavWN+/G3YN6CCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCB7
# QnoxkgZ1ICxs49hq7pqqIatl7m9ODd8M/42I0/JT8DANBgkqhkiG9w0BAQEFAASC
# AYCZUdJpCkJVnvqoW++4w2ORa1gZ9xjUT3llLa2QFzOiD0y8Of0LVrpoy+cUSa5a
# tx3h4+VHDc0ty93G/i96fH11u0Tfv9Qra2aIFIEe4NA2uei9/nu+ngSVerDJrd7c
# OvJ00XQ9snKAImtaAUL0RX5hIA+sKyETQZOCQwEeuLxaSgNE7E9iS2Bn6/Y3t5EN
# PBBXflZvxouTRPIUKlNGkj5bGkpzpA9ksQB1QHYZmSCn3SmiAy8NPoSEeTmSpblU
# DXHfvkfIslEMQyR3SL+wU5zwBGlgroDH2KGb5AdfXY5g8FWBnulak/yJWe7YAMzC
# lK9dqmkHpFx1IftYqd51j8F6Zkk/nI9UykJ6WO8aneHqMWJeHcRaRPah5K0ATxWt
# mGaQf0Q0qSMd7b7JDe5kG4Kf8ZVXdMcCE6W40W4fmbIsomDxwaUBToeiMuV/J7BP
# H8SS5P4jsi8Dbxy0eVcGIDlVaSt8hwAHSaBhXxgb/vyT6f1yLc6T1NBVaZ4wNctf
# By4=
# SIG # End signature block
