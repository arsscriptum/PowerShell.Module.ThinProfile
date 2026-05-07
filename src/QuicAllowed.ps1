#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   QuicAllowed.ps1                                                            |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+

function Set-QuicAllowed {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, position=0)]
        [bool]$Enabled
    )

    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $IsAdmin) {
        Write-Host "[ERROR] This function requires administrative privileges." -ForegroundColor Red
        return
    }
    

    Write-Host "=== Set-QuicAllowed: Starting configuration ===" -ForegroundColor Cyan

    # region --- Registry values ---
    $desiredValue = if ($Enabled) { 1 } else { 0 }
    $state = if ($Enabled) { "ENABLED" } else { "DISABLED" }

    $registryPaths = @(
        # Microsoft Edge QUIC policy
        "HKLM:\SOFTWARE\Policies\Microsoft\Edge",

        # WebView2 QUIC policy (subkey)
        "HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2",

        # Google Chrome QUIC policy
        "HKLM:\SOFTWARE\Policies\Google\Chrome", 
        "HKCU:\SOFTWARE\Policies\Google\Chrome"
    )

    foreach ($path in $registryPaths) {

        # Ensure the key exists
        if (-not (Test-Path $path)) {
            Write-Host "Creating registry path: $path" -ForegroundColor Yellow
            New-Item -Path $path -Force | Out-Null
        }

        Write-Host "Setting QuicAllowed=$desiredValue at $path" -ForegroundColor Green
        New-ItemProperty -Path $path -Name "QuicAllowed" -Value $desiredValue -PropertyType DWORD -Force | Out-Null
    }

    Write-Host "QUIC is now $state via registry policy." -ForegroundColor Cyan
    # endregion

    # region --- Check running processes ---
    Write-Host "`nChecking if browser processes must be restarted..." -ForegroundColor Magenta

    $pslist = @('chrome','msedge','msedgewebview2','ms-teams')

    foreach($ps in $pslist){ 
        $pInfo = Get-Process -Name "$ps" -ErrorAction Ignore
        $alive = if($pInfo -ne $Null) { $True } else { $False }

        if ($alive) {
            Write-Host "Process '$ps' is running — restart required to apply changes." -ForegroundColor Yellow
        } else {
            Write-Host "Process '$ps' is not running." -ForegroundColor DarkGray
        }
    }
    # endregion

    Write-Host "=== Completed Set-QuicAllowed ===" -ForegroundColor Cyan
}
