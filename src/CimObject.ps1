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
