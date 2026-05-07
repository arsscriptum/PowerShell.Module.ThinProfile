#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   NetAdapterManager.ps1                                                        |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+



function Reset-EthNetAdapter {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('ETH0','ETH1')]
        [Alias('InterfaceAlias')]
        [string]$Name = "ETH1",
        [Parameter(Mandatory = $false)]
        [Alias('d')]
        [ValidateRange(100,30000)]
        [int]$DelayMs = 1000,
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [int]$Count = 1
    )

    try {
        if(($DelayMs -ge 100) -And ($DelayMs -le 30000)){
            Write-Host "[Reset-EthNetAdapter] " -f DarkRed -n
            Write-Host "Delay of $DelayMs milliseconds" -f DarkYellow
        } else {
            throw "invalid delay"
        }

        $imadmin    = isadmin
        if(-not($imadmin)){
            throw "not admin"
        }
        $Steps = $DelayMs/10
        $ToDoNum = $Count
        do {
            $ToDoNum = $ToDoNum - 1
            Write-Host "`n[Reset-EthNetAdapter] " -f DarkRed -n
            Write-Host "Disabling NetAdapter ETH1..." -f DarkYellow -n 
            Disable-NetAdapter ETH1 -Confirm:$False
            Write-Host " $Name Disabled!`n" -f DarkGreen
            Write-Host "Waiting a bit... " -f DarkGray
            For($x = 0 ; $x -le 10 ; $x++){
                Start-Sleep -Milliseconds $Steps     
                Write-Host ". " -n -f DarkGray
            }
            
            Write-Host "`n[Reset-EthNetAdapter] " -f DarkCyan -n
            Write-Host "Enabling NetAdapter ETH1..." -f White -n 
            Enable-NetAdapter ETH1 -Confirm:$False
            Write-Host " $Name Enabled!`n" -f DarkGreen
            Write-Host "Waiting a bit... " -f DarkGray
            For($x = 0 ; $x -le 10 ; $x++){
                Start-Sleep -Milliseconds $Steps     
                Write-Host ". " -n -f DarkGray
            }
        } while ($ToDoNum -gt 0)

    } catch {
        Write-Error "$_"
    }
}


function Reset-LocalMac {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$NewMac = "$ENV:MAC_ADDR_CUSTOM_01",
        [Parameter(Mandatory = $false)]
        [string]$InterfaceAlias = "ETH0",
        [Parameter(Mandatory = $false)]
        [Alias('d')]
        [switch]$Default,
        [Parameter(Mandatory = $false)]
        [Alias('r')]
        [switch]$Reset
    )

    $DefaultMac = "$ENV:MAC_ADDR_ORIGINAL"

    try {
        $imadmin    = isadmin

        $IfState    = (Get-NetAdapter -Name $InterfaceAlias | Select MacAddress,Status).Status
        $MyMac      = (Get-NetAdapter -Name $InterfaceAlias | Select MacAddress,Status).MacAddress
        Write-Host "Current mac $MyMac"
        $DisplayName="Locally Administered Address" 
        $ResetValue="$ENV:MAC_ADDR_RESET"
        Write-Host "[CURRENT MAC ADDRESS]  " -f Blue -n 
        Write-Host " New Mac $MyMac (iface is $IfState)" -f White
        if($Reset){
            try{
                Write-Host "[RESETTING MAC ADDRESS]  " -f DarkYellow -n 
                Write-Host " Reset to --" -f Gray
                Set-NetAdapterAdvancedProperty -Name "$InterfaceAlias" -DisplayName $DisplayName -DisplayValue $ResetValue -ErrorAction Stop
                Reset-EthNetAdapter -Name $InterfaceAlias -DelayMs 1000 -Count 1
            } catch {
                Write-Host "Failed " -f DarkRed -n 
                Write-Host "The Error is $_" -f DarkYellow 
                return
            }
        } elseif($Default) {
           try{
                Write-Host "[RESETTING MAC ADDRESS]  " -f DarkYellow -n 
                Write-Host " Reset to $DefaultMac" -f Gray
                Set-NetAdapterAdvancedProperty -Name "$InterfaceAlias" -DisplayName $DisplayName -DisplayValue $DefaultMac -ErrorAction Stop
                Reset-EthNetAdapter -Name $InterfaceAlias -DelayMs 1000 -Count 1
            } catch {
                Write-Host "Failed " -f DarkRed -n 
                Write-Host "The Error is $_" -f DarkYellow 
                return
            }
        }

        try{
            $NewVal = $NewMac -replace "-",""
            Write-Host "[SETTING MAC ADDRESS]  " -f Blue -n 
            Write-Host " New Mac $NewMac ($NewVal)" -f White
            Set-NetAdapterAdvancedProperty -Name "$InterfaceAlias" -DisplayName $DisplayName -DisplayValue $NewVal  -ErrorAction Stop
            Reset-EthNetAdapter -Name $InterfaceAlias -DelayMs 1000 -Count 1
        } catch {
            Write-Host "Failed " -f DarkRed -n 
            Write-Host "The Error is $_" -f DarkYellow 
            return
        }
    } catch {
        Write-Error "$_"
    }
}


function Set-LocalIp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$NewIp = "10.106.181.86",
        [Parameter(Mandatory = $false)]
        [string]$InterfaceAlias = 'ETH1',
        [Parameter(Mandatory = $false)]
        [string[]]$NewDns = ("176.103.130.130", "176.103.130.131")
        #[string[]]$NewDns = ("1.1.1.1", "1.0.0.1")
        
    )



    try {
     
        # Get interface index from ETH1
        $IfIndex = (Get-NetAdapter -Name "$InterfaceAlias").IfIndex

        $PrefixLength = 24

        # Extract base network from NewIp and build gateway
        $Octets = $NewIp.Split('.')
        if ($Octets.Count -ne 4) {
            throw "Invalid IP address format: $NewIp"
        }

        # Replace last octet with 1 → gateway
        $Gateway = "$($Octets[0]).$($Octets[1]).$($Octets[2]).1"

        if ($PSCmdlet.ShouldProcess("$InterfaceAlias", "Configure IPv4 settings")) {

            #
            # Remove any existing DHCP or static config before setting new one
            #
            Get-NetIPAddress -InterfaceIndex $IfIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Remove-NetIPAddress -Confirm:$false

            #
            # Set the new static IPv4 address
            #
            Set-NetIPAddress -InterfaceIndex $IfIndex -IPAddress $NewIp -PrefixLength $PrefixLength -DefaultGateway $Gateway -AddressFamily IPv4 -ErrorAction Stop

            #
            # Set DNS servers
            #
            Set-DnsClientServerAddress -InterfaceIndex $IfIndex -ServerAddresses $NewDns
        }
    }
    catch {
        Write-Error "$_"
    }
}
