#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   config.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
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
