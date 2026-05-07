

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   HexEdit.ps1                                                                  |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+

function Enable-RdpConnections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [switch]$DisableFirewall
    )

    try {

		# Active RDP
		Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

		# Désactive NLA (optionnel mais évite friction)
		Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

		# Désactive firewall
		if($DisableFirewall){
		    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
		}
		
		# Met réseau en Private
		Set-NetConnectionProfile -NetworkCategory Private

		# Ajoute user local
		# Remplace TON_USER
		Add-LocalGroupMember -Group "Remote Desktop Users" -Member "$env:USERNAME"

    } catch {
        Write-Error "$_"
    }
}


function Disable-RdpConnections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [switch]$EnableFirewall
    )

    try {

		# Active RDP
		Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1

		# Désactive NLA (optionnel mais évite friction)
		Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1

		# Désactive firewall
		if($EnableFirewall){
		    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
		}

    } catch {
        Write-Error "$_"
    }
}
