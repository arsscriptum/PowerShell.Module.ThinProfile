

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

function Open-HexEdit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the log file")]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try {

        $FilePath = "$ENV:HxD"
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "HxD not found at '$bareTailPath'."
            return
        }

        if (-not (Test-Path -Path $Path)) {
            Write-Error "Log file not found: '$Path'"
            return
        }

        [System.Collections.ArrayList]$GrepArguments = [System.Collections.ArrayList]::new()
        [void]$GrepArguments.Add("$Path")
        $AllCmds = $GrepArguments -join ' '

        $ProcessArgs = @{
            FilePath = "$FilePath"
            ArgumentList = $GrepArguments
            WorkingDirectory = "$($PWD.Path)"
            NoNewWindow = $True
            PassThru = $False
            Wait = $False
        }
        Write-Host "$AllCmds" -f DarkCyan
        Start-Process @ProcessArgs


    } catch {
        Write-Error "$_"
    }
}
New-alias -Name hex -Value Open-HexEdit -Force -ErrorAction Ignore -Scope GLobal -Option AllScope