#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModuleUpdater.ps1                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-ThinProfileModuleVersionPath {
    $ModPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $VersionPath = Join-Path $ModPath 'version'
    return $VersionPath
}

function Test-FileHashMatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "File '$_' does not exist or is not a valid file."
            }
            return $true
        })]
        [string]$File,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript({
            try {
                $null = [uri]$_
                return [uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute)
            } catch {
                return $false
            }
        })]
        [string]$HashUrl
    )
   
    $expected = (Invoke-RestMethod -Uri $HashUrl -TimeoutSec 10).Trim()
    $actual = (Get-FileHash -Path $File -Algorithm SHA256).Hash
    return ($expected -eq $actual)
}

function Get-RemoteText {
    param([string]$Url, [int]$Retries = 3)
    for ($i = 0; $i -lt $Retries; $i++) {
        try { return (Invoke-RestMethod -Uri $Url -TimeoutSec 10) }
        catch {
            if ($i -eq $Retries - 1) { throw }
            Start-Sleep -Seconds ([math]::Pow(2, $i))
        }
    }
}


function New-ThinProfileModuleVersionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$AutoUpdateFlag,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $JsonPath = (Join-Path (Get-ThinProfileModuleVersionPath) "ThinProfile.json")
    Write-Verbose "[Get-ThinProfileModuleVersionPath] JsonPath $JsonPath"
    $CurrDate = Get-Date -UFormat "%s"
    $ModuleName = (Get-ThinProfileModuleInformation).ModuleName.Name
    $ModuleInstallPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $ModulePath = (Get-ThinProfileModuleInformation).ModulePath



    $psm1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psm1'
    $psd1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psd1'

    Write-Verbose "[Get-ThinProfileModuleVersionPath]`n - CurrDate $CurrDate`n - ModuleName $ModuleName`n - ModuleInstallPath $ModuleInstallPath`n - ModulePath $ModulePath`n - psm1path $psm1path`n - psd1path $psd1path"

    $ValidFiles = ((Test-Path "$psm1path") -and (Test-Path "$psd1path"))
    if (!$ValidFiles) {
        Write-Error "Missing Module File"
    }

    $GetUpdateUrlCmd = Get-Command -Name "Get-PowerShellModulesUpdateUrl" -CommandType Function -Module "PowerShell.Module.Core" -ErrorAction Ignore

    $UpdateBaseUrl = "https://arsscriptum.github.io"

    if ($GetUpdateUrlCmd -ne $Null) {
        $UpdateBaseUrl = Get-PowerShellModulesUpdateUrl
        Write-Verbose "[Get-ThinProfileModuleVersionPath] Command Get-PowerShellModulesUpdateUrl found in Core. Overriding UpdateURL with $UpdateBaseUrl"
    }else{
        Write-Verbose "[Get-ThinProfileModuleVersionPath] UpdateURL defaults to $UpdateBaseUrl"
    }

    $UpdateUrl = "{0}/{1}" -f $UpdateBaseUrl, $ModuleName
    $VersionUrl = "{0}/{1}/Version.nfo" -f $UpdateBaseUrl, $ModuleName
    $CurrVersion = Get-ThinProfileModuleVersion
    Write-Verbose "[Get-ThinProfileModuleVersionPath]`n - UpdateUrl $UpdateUrl`n - VersionUrl $VersionUrl`n - CurrVersion $CurrVersion`n"

    $ShouldOverwrite = $False
    $FileExists = (Test-Path "$JsonPath" -PathType Leaf)
    if ($Force) {
        $ShouldOverwrite = $True
    }

    Write-Verbose "[Get-ThinProfileModuleVersionPath] Force $Force . File $JsonPath Exists? $FileExists. ShouldOverwrite $ShouldOverwrite"

    if ((!($FileExists)) -or ($ShouldOverwrite)) {
        [pscustomobject]$o = [pscustomobject]@{
            CurrentVersion = "$CurrVersion"
            LastUpdate = "$CurrDate"
            UpdateUrl = "$UpdateUrl"
            VersionUrl = "$VersionUrl"
            ModuleName = "$ModuleName"
            AutoUpdate = $AutoUpdateFlag
            LocalPSM1 = "$psm1path"
            LocalPSD1 = "$psd1path"
        }
        $NewFileJsonData = $o | ConvertTo-Json
        New-Item -Path "$JsonPath" -ItemType File -Force -EA Stop -Value $NewFileJsonData | Out-Null
        Write-Host "[Get-ThinProfileModuleVersionPath] Wrote $JsonPath"
    }
}



function Set-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [bool]$Enable
    )


    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        New-Item -Path $RegKeyRoot -Force | Out-Null
    }
    $Val = if ($Enable) { 1 } else { 0 }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    Set-ItemProperty -Path $RegKeyRoot -Name "override" -Value $Val -Type DWORD
}


function Get-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        return $False
    }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    $RegVal = Get-ItemProperty -Path $RegKeyRoot -Name "override" -ErrorAction Ignore
    if (-not ($RegVal)) {
        return $False
    }
    if ($RegVal.override) {
        return $True
    }
    return $False
}


function Invoke-ThinProfileAutoUpdate {
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $False, HelpMessage = 'Force')]
        [switch]$Force,
        [Parameter(Mandatory = $False, HelpMessage = 'Import')]
        [switch]$Import
    )
    try {
        $TestFileHashMatch = $True
        $TestFileHashMatchSignature = $False
        
        if (Get-ThinProfileAutoUpdateOverride) {
            Write-Host "[Invoke-ThinProfileAutoUpdate] Bypass Override" -ForegroundColor DarkRed
            return
        }

        $verDir = Get-ThinProfileModuleVersionPath
        $json = Join-Path $verDir "ThinProfile.json"
        if (-not (Test-Path $json)) { New-ThinProfileModuleVersionFile }

        $data = Get-Content $json -Raw | ConvertFrom-Json
        [version]$curr = Get-ThinProfileModuleVersion

        try {
            [version]$remote = [version](Get-RemoteText -Url $data.VersionUrl)
        } catch {
            Write-Verbose "Version check failed: $_"
            return
        }

        if (-not ($Force -or ($remote -gt $curr))) {
            Write-Verbose "No update required ($curr)"
            return
        }

        $info = Get-ThinProfileModuleInformation
        $root = Split-Path -Parent $info.ModuleInstallPath
        $target = Join-Path $root "$remote"
        if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }

        $psd1 = Join-Path $target "$($data.ModuleName).psd1"
        $psm1 = Join-Path $target "$($data.ModuleName).psm1"
        
        $psd1hash = Join-Path $target "$($data.ModuleName).psd1.sha256"
        $psm1hash = Join-Path $target "$($data.ModuleName).psm1.sha256"

        $tmp1 = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
        $tmp2 = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())

        $urlPsd1 = "$($data.UpdateUrl)/$($data.ModuleName).psd1"
        $urlPsm1 = "$($data.UpdateUrl)/$($data.ModuleName).psm1"

        $urlPsd1Hash = "$($data.UpdateUrl)/$($data.ModuleName).psd1.sha256"
        $urlPsm1Hash = "$($data.UpdateUrl)/$($data.ModuleName).psm1.sha256"

        Write-Verbose "psm1 ($psm1)"
        Write-Verbose "psd1 ($psd1)"
        Write-Verbose "urlPsm1 ($urlPsm1)"
        Write-Verbose "urlPsd1 ($urlPsd1)"

        try {
            Invoke-WebRequest $urlPsm1 -OutFile $tmp2 -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            Invoke-WebRequest $urlPsm1Hash -OutFile $psm1hash -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Host "Failed to get data file from `"$urlPsm1`" -> $tmp2" -f DarkRed
            throw "Failed to get data file from `"$urlPsm1`" -> $tmp2`n$_"
        }

        try {
            Invoke-WebRequest $urlPsd1 -OutFile $tmp1 -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            Invoke-WebRequest $urlPsd1Hash -OutFile $psd1hash -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Host "Failed to get data file from `"$urlPsd1`" -> $tmp1" -f DarkRed
            throw "Failed to get data file from `"$urlPsd1`" -> $tmp1`n$_"
        }

        # After download:
        
        if ($TestFileHashMatch) {
            $ChecksumUrl = "{0}/{1}.psm1.sha256" -f "$($Data.UpdateUrl)","$($Data.ModuleName)"
            $psm1HackCheck = Test-FileHashMatch $tmp2 $ChecksumUrl 
            if (-not ($psm1HackCheck)) {
                throw "Hash mismatch for PSM1."
            }
            Write-Host "✅ psm1 File Hash $tmp2 is GOOD"

            $ChecksumUrl = "{0}/{1}.psd1.sha256" -f "$($Data.UpdateUrl)","$($Data.ModuleName)"
            $psd1HackCheck = Test-FileHashMatch $tmp1 $ChecksumUrl 
            if (-not ($ChecksumUrl)) {
                throw "Hash mismatch for PSD1."
            }
            Write-Host "✅ psd1 File Hash $tmp1 is GOOD"

            # (Optional) signature
            if ($TestFileHashMatchSignature) {
                $sig = Get-AuthenticodeSignature -FilePath "$tmp2" -ErrorAction Ignore
                if ( ($sig -eq $Null) -Or ($sig.Status -ne 'Valid') ) { throw "Invalid signature on PSM1: $($sig.Status)" }

                $man = Test-ModuleManifest -Path $tmp1
                if ([version]$man.ModuleVersion -ne $remote) {
                    throw "Manifest version $($man.ModuleVersion) != announced $remote"
                }
            }
        }

        Move-Item $tmp1 $psd1 -Force
        Move-Item $tmp2 $psm1 -Force

        $data.CurrentVersion = $remote.ToString()
        $data.LocalPSD1 = $psd1
        $data.LocalPSM1 = $psm1
        $data | ConvertTo-Json -Depth 4 | Set-Content -Path $json -Encoding UTF8

        Write-ThinProfileHost "✅ Updated to $remote"

        if ($Import) {
            # optional safe reload
            Remove-Module $info.ModuleName -Force -ErrorAction SilentlyContinue
            Import-Module $info.ModuleName -MinimumVersion $remote -Force
        }
    } catch {
        Write-Verbose "Version update failed: $_"
        return
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAd1tlRB9BZiMDN
# FWdj4Jz6hfMY03df+dIXZ2YJHfFrAaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBi
# XlglF8k5J9rJnGzsZWmFzrSbBVnQItibvvoGM+sV1DANBgkqhkiG9w0BAQEFAASC
# AYBuGzNIyeKcCeBIiR6aRYzsJzacM4oTslgHQhk6ygaKT9wXuJbitkTKK6pGOSPk
# ZjmH4Mb+98pcaWgqZbWDYRGbExHsBSacxKWxHUfeya41JCaQGMSTS7dHgJQS0Pt4
# RaT56j1fStJ3OsCT62cxCPYLJifEn8fnaNyXB1tI2tG+koeazZLfnFXGFz6xykOZ
# Fkuwmn6Oa/SdBN8bMJCNs1Y0DyuTTMmk73uwz/l+LcQBYzos+bfWBUBjiWe7vmFF
# 4Ljc7JHwAELTPbknjLHgnWrW8iad8mWVNHOyilQzNYR8uM7Rg0hs46bb1Rxudm7C
# YELv0+eHKY1TMI0ds8i8n5CCmSTbm4ehtZjDyiGKwRRNqNsna6r1X9FvfizsPalt
# XOeDtaHuHjhjJXX0nqOVthyxj5JkSeDcq6XgXFkJvva/VQUjT5I4HkmXd+yvEd6F
# Wv5qLsCbKAbDaPz4apuOOcapJBwlFL28Z834rU/fmHnu2SP7oDj3Gbk1LIu8pjtF
# iv8=
# SIG # End signature block
