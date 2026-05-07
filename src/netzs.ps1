# ==========================================
# Firewall Rule: Block outbound traffic to IP:Port
# ==========================================



function Enable-FirewallLogging {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    <#
        Enables firewall logging for dropped packets.
    #>
    $NumKb = 10Mb / 1024

    Write-Host "Enabling Windows Firewall logging for dropped traffic..."
    $LogFileNameDomain = "c:\tmp\firewall\pfirewallDomain.log"
    $LogFileNamePrivate = "c:\tmp\firewall\pfirewallPrivate.log"
    $LogFileNamePublic = "c:\tmp\firewall\pfirewallPublic.log"
    
    if(-not(Test-Path "$LogFileNameDomain")){
        New-Item -Path "$LogFileNameDomain" -ItemType File -Force -EA Ignore | Out-Null
        Remove-Item -Path "$LogFileNameDomain" -Force -EA Ignore | Out-Null
    }
    
    Set-NetFirewallProfile -Profile Domain -LogBlocked True -LogFileName "$LogFileNameDomain" -LogMaxSizeKilobytes $NumKb 
    Write-Host "Firewall logging enabled $LogFileNameDomain "
    Set-NetFirewallProfile -Profile Private -LogBlocked True -LogFileName "$LogFileNamePrivate" -LogMaxSizeKilobytes $NumKb 
    Write-Host "Firewall logging enabled $LogFileNamePrivate "
    Set-NetFirewallProfile -Profile Public -LogBlocked True -LogFileName "$LogFileNamePublic" -LogMaxSizeKilobytes $NumKb 
    Write-Host "Firewall logging enabled $LogFileNamePublic "

    
}

function Add-BlockZScalerFwRule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$IpAddress = "165.225.212.22",
        [Parameter(Position = 1, Mandatory = $true)]
        [int]$Port = 443,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateSet('Inbound','Outbound')]
        [string]$RuleDirection
    )
    $RuleAction = 'Block'
    $RuleProtocol = 'TCP'
    $RuleProfile = 'Any'
    
    $RuleName = '{0}-{1}-{2}-{3}p{4}-{5}' -f "$RuleAction", "$($RuleDirection.SubString(0,3))", "$RuleProtocol", "$($IpAddress.Replace('.','x'))", $Port, $RuleProfile
    $RuleDisplayName = "{0} {1} {2} to {3} on port {4}, {5}" -f "$RuleAction", "$RuleDirection", "$RuleProtocol", "$IpAddress", $Port, $RuleProfile
    # 1. Check if rule exists
    $existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Firewall rule already exists: $RuleName"
        return
    }

    Write-Host "Creating firewall rule: $RuleName"

    # Enable logging first
    Enable-FirewallLogging

    # 2. Create the rule
    New-NetFirewallRule `
        -Name "$RuleName" `
        -DisplayName "$RuleDisplayName" `
        -Direction $RuleDirection `
        -Action $RuleAction `
        -Protocol $RuleProtocol `
        -RemoteAddress $IpAddress `
        -RemotePort $Port `
        -Profile $RuleProfile `
        -Verbose

    Write-Host "Rule $RuleName created successfully."
}


function Remove-BlockZScalerFwRule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$IpAddress = "165.225.212.22",
        [Parameter(Position = 1, Mandatory = $true)]
        [int]$Port = 443,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateSet('Inbound','Outbound')]
        [string]$RuleDirection
    )
    $RuleAction = 'Block'
    $RuleProtocol = 'TCP'
    $RuleProfile = 'Any'
    
    $RuleName = '{0}-{1}-{2}-{3}p{4}-{5}' -f "$RuleAction", "$($RuleDirection.SubString(0,3))", "$RuleProtocol", "$($IpAddress.Replace('.','x'))", $Port, $RuleProfile
    $RuleDisplayName = "{0} {1} {2} to {3} on port {4}, {5}" -f "$RuleAction", "$RuleDirection", "$RuleProtocol", "$IpAddress", $Port, $RuleProfile
    $existing = Get-NetFirewallRule -Name "$RuleName" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing firewall rule: $RuleName"
        Remove-NetFirewallRule -Name "$RuleName"
        Write-Host "Rule removed."
    } else {
        Write-Host "Rule does not exist. Nothing to remove."
    }
}

function Add-ZScalerRule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$IpAddress = "165.225.212.22",
        [int]$Port = 443
    )

    Add-BlockZScalerFwRule $IpAddress $Port 'Outbound'
    Add-BlockZScalerFwRule $IpAddress $Port 'Inbound'
}


function Remove-ZScalerRule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$IpAddress = "165.225.212.22",
        [int]$Port = 443
    )

    Remove-BlockZScalerFwRule $IpAddress $Port 'Outbound'
    Remove-BlockZScalerFwRule $IpAddress $Port 'Inbound'
}