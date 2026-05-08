#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Config.ps1                                                                ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-ThinProfileUserCredentialID { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [String]$Id
    )

    $DefaultUser = Get-ThinProfileDefaultUsername
    $Credz = "ThinProfile_MODULE_USER_$DefaultUser"

    $DevAccount = Get-ThinProfileDevAccountOverride
    if($DevAccount){ return "ThinProfile_MODULE_USER_$DevAccount" }
    
    return $Credz
}

function Get-ThinProfileAppCredentialID { 
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $DefaultUser = Get-ThinProfileDefaultUsername
    $Credz = "ThinProfile_MODULE_APP_$DefaultUser"

    $DevAccount = Get-ThinProfileDevAccountOverride
    if($DevAccount){ return "ThinProfile_MODULE_APP_$DevAccount" }
    
    return $Credz
}

function Get-ThinProfileDevAccountOverride { 
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegPath = Get-ThinProfileModuleRegistryPath
    if( $RegPath -eq "" ) { throw "not in module"; return ;}
    $DevAccount = ''
    $DevAccountOverride = Test-RegistryValue -Path "$RegPath" -Entry 'override_dev_account'
    if($DevAccountOverride){
        $DevAccount = Get-RegistryValue -Path "$RegPath" -Entry 'override_dev_account'
    }
    
    return $DevAccount
}

function Set-ThinProfileDevAccountOverride { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [String]$Id
    )

    $RegPath = Get-ThinProfileModuleRegistryPath
    if( $RegPath -eq "" ) { throw "not in module"; return ;}
    New-RegistryValue -Path "$RegPath" -Entry 'override_dev_account' -Value "$Id" 'String'
    Set-RegistryValue -Path "$RegPath" -Entry 'override_dev_account' -Value "$Id"
    
    return $DevAccount
}

function Get-ThinProfileModuleUserAgent { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    $ModuleName = ($ExecutionContext.SessionState).Module
    $Agent = "User-Agent $ModuleName. Custom Module."
   
    return $Agent
}


function Set-ThinProfileDefaultUsername {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$User      
    )
    $RegPath = Get-ThinProfileModuleRegistryPath
    $ok = Set-RegistryValue  "$RegPath" "default_username" "$User"
    [environment]::SetEnvironmentVariable('DEFAULT_ThinProfile_USERNAME',"$User",'User')
    return $ok
}

<#
    ThinProfileDefaultUsername
    New-ItemProperty -Path "$ENV:OrganizationHKCU\ThinProfile.com" -Name 'default_username' -Value 'codecastor'
 #>
function Get-ThinProfileDefaultUsername {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    $RegPath = Get-ThinProfileModuleRegistryPath
    $User = (Get-ItemProperty -Path "$RegPath" -Name 'default_username' -ErrorAction Ignore).default_username
    if( $User -ne $null ) { return $User  }
    if( $Env:DEFAULT_ThinProfile_USERNAME -ne $null ) { return $Env:DEFAULT_ThinProfile_USERNAME ; }
    return $null
}


function Set-ThinProfileServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Server")]
        [String]$Hostname      
    )
    $RegPath = Get-ThinProfileModuleRegistryPath
    $ok = Set-RegistryValue  "$RegPath" "hostname" "$Hostname"
    [environment]::SetEnvironmentVariable('DEFAULT_ThinProfile_SERVER',"$Hostname",'User')
    return $ok
}


function Get-ThinProfileServer {      
    [CmdletBinding(SupportsShouldProcess)]
    param ()$Script:MyInvocation.MyCommand.Name
    $RegPath = Get-ThinProfileModuleRegistryPath
    $Server = (Get-ItemProperty -Path "$RegPath" -Name 'hostname' -ErrorAction Ignore).hostname
    if( $Server -ne $null ) { return $Server }
     
    if( $Env:DEFAULT_ThinProfile_SERVER -ne $null ) { return $Env:DEFAULT_ThinProfile_SERVER  }
    return $null
}


function Test-ThinProfileModuleConfig { 
    $ThinProfileModuleInformation    = Get-ThinProfileModuleInformation;
    $hash = @{ ThinProfileServer               = Get-ThinProfileServer;
    ThinProfileDefaultUsername      = Get-ThinProfileDefaultUsername;
    ThinProfileModuleUserAgent      = Get-ThinProfileModuleUserAgent;
    ThinProfileDevAccountOverride   = Get-ThinProfileDevAccountOverride;
    ThinProfileUserCredentialID     = Get-ThinProfileUserCredentialID;
    ThinProfileAppCredentialID      = Get-ThinProfileAppCredentialID;
    RegistryRoot               = $ThinProfileModuleInformation.RegistryRoot;
    ModuleSystemPath           = $ThinProfileModuleInformation.ModuleSystemPath;
    ModuleInstallPath          = $ThinProfileModuleInformation.ModuleInstallPath;
    ModuleName                 = $ThinProfileModuleInformation.ModuleName;
    ScriptName                 = $ThinProfileModuleInformation.ScriptName;
    ModulePath                 = $ThinProfileModuleInformation.ModulePath; } 

    Write-Host "---------------------------------------------------------------------" -f DarkRed
    $hash.GetEnumerator() | ForEach-Object {
        $k = $($_.Key) ; $kl = $k.Length ; if($kl -lt 30){ $diff =30 - $kl ; for($i=0;$i -lt $diff ; $i++) { $k += ' '; }}
        Write-Host "$k" -n -f DarkRed
        Write-Host "$($_.Value)" -f DarkYellow
    }
    Write-Host "---------------------------------------------------------------------" -f DarkRed
}

function Get-ExportsPath { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
   
    $ExportsPath = Join-Path "$((Get-ThinProfileModuleInformation).ModuleInstallPath)" "exports"

    return $ExportsPath
}


function Get-ThinProfileModuleRegistryPath { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    if(-not($ModuleName)){$ModuleName = "PowerShell.Module.ThinProfile"}
    $Path = "$ENV:OrganizationHKCU\$ModuleName"
   
    return $Path
}

function Get-ThinProfileModuleInformation {
    [CmdletBinding()]
    param ()
    try{
        if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
        $ModuleName = $ExecutionContext.SessionState.Module
        $ModuleScriptPath = $Script:MyInvocation.MyCommand.Path
        $ModuleInstallPath = (Get-Item "$ModuleScriptPath").DirectoryName
        $CurrentScriptName = $MyInvocation.MyCommand.Name
        $RegistryPath = "$ENV:OrganizationHKCU\$ModuleName"
        $ModuleSystemPath = (Resolve-Path "$ModuleInstallPath\..").Path
        $ModuleInformation = @{
            ModuleName        = $ModuleName
            ModulePath        = $ModuleScriptPath
            ScriptName        = $CurrentScriptName
            RegistryRoot      = $RegistryPath
            ModuleSystemPath  = $ModuleSystemPath
            ModuleInstallPath = $ModuleInstallPath
        }
        return $ModuleInformation        
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCR0IOrgX3GbyLj
# R3taplnYxQBdbQPJQJejUqjxM1N9FaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDG
# V9rH6RgWODzlBXwbw4ATunC2eO9URG8+5Qi4PPAjbzANBgkqhkiG9w0BAQEFAASC
# AYAXI9TlMs0PxbnFIhyuyQ4dKzWMUL7gRLK9sIf7wSXTTtciY6H2i8wvpF2D+XoC
# NRH2Waith6vvQMdBPi6517laZFrXzsgUTKWjXQAcYLqC+uI9ZBptHv6Pyj+7rJov
# F6KW2FJXVPmyXM4oXx9BTd5G8wlpPThWnNQpzIdaCsiGCxuQLvYPoWa5c7mhUsZX
# kpdWugQSnv6t8P2a2DVlEo7pS0XUVSCYBymv0UfG1AsQLPrb0OcUTo8O8SZwOGCH
# dZx46od6qJx9+9SPeE5AXCc46ICehcGceU0ForwW8zngPWqMAhaE2WGAjTBpBhYh
# ISOHLP49OuZ0Vz29fnIRhFYba2xYuTK5Bk7V2MwKXw5aF9Qmyt40adq4M05NPzpD
# FL5L2IQ7P0PzaychpYmXGARcKNfSPn+IWhh/7BDuVtHmDbO8ncbozZvW4WOBgdPI
# diT50Nz9/ntNQ7QmfLihUcEWS3hymnPDZW1I2b14NOrqlfSbF5t3qFNXWExGjl1I
# SfA=
# SIG # End signature block
