

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   StartWinDbg.ps1                                                              |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+ 

function Start-WinDbg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Version")]
        [ValidateSet("x64","arm64","x86")]
        [string]$Version="x64"
    )

    try {
        $WinDbgName = "windbg.exe"
        $WindowsKitPath = Join-Path "${ENV:ProgramFiles(x86)}" "Windows Kits\10\Debuggers"
        $BasePath = Join-Path "$WindowsKitPath" "$Version"
        $DefaultPath = Join-Path "$BasePath" "$WinDbgName"
        $FilePath = $DefaultPath
        if ( -not ( Test-Path "$FilePath" ) ) {
            $FilePath = switch($Version){
                "x64"           { "$ENV:WINDBG_EXE_X64" }
                "x86"           { "$ENV:WINDBG_EXE_X86" }
                "arm64"         { "$ENV:WINDBG_EXE_ARM64" }
                default         { "$DefaultPath" }
            }
        }
        if ( -not ( Test-Path "$FilePath" ) ) {
            Write-Error "Cannot find windbg.exe"
            return
        }

        $windbgPS = get-process "windbg" -ErrorAction Ignore
        if( ($windbgPS -ne $Null) -And ($($windbgPS.Path) -eq $FilePath)){
            Write-Host "[Start-WinDbg]" -f DarkRed -n
            Write-Host " $WinDbgName v $Version already running!" -f DarkYellow
            Write-Host "Type 'y' to start another Instance " -n -f White
            $a = Read-Host "-> "
            if($a -ne 'y'){
                return;
            }
        }
        
        $ProcessArgs = @{
            FilePath = "$FilePath"
            WorkingDirectory = "$($PWD.Path)"
            NoNewWindow = $False
            PassThru = $False
            Wait = $False
        }
        
        Start-Process @ProcessArgs

    } catch {
        Write-Error "$_"
    }
}

New-alias -Name windbg-start -Value Start-WinDbg -Force -ErrorAction Ignore -Scope GLobal -Option AllScope