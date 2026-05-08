#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   <FILENAME>                                                                   |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|   Copyright © 2025. All rights reserved                                        |
#+--------------------------------------------------------------------------------+


function Start-VsCode {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [alias('p')]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [alias('e')]
        [switch]$Empty

    )
    try {
        $OpenPath = $True
        if([string]::IsNullOrEmpty($Path)){
            if($Empty){
                $OpenPath = $False
                $Path = $Null
            } else {
                $OpenPath = $True   
                $Path = "$($PWD).Path"
            }           
        } else {
            if(-not(Test-Path "$Path")){
                throw "Invalid Path $Path"
            }
            $OpenPath = $True
        }
        $VsCodeExe = "$ENV:VSCODE"
        if(-not(Test-Path "$VsCodeExe")){
            $CodeCmd = Get-Command "Code.exe" -CommandType Application -ErrorAction Ignore
            if ($CodeCmd -eq $null) {
                throw "Code not found"
            }
            $VsCodeExe = $CodeCmd.Path
        }

        if($OpenPath) {
            Write-Host "Launching VSCODE in FOLDER $Path"
            &"$VsCodeExe" "$Path"
        } else {
            Write-Host "Launching VSCODE"
            &"$VsCodeExe"
        }
    } catch {
        Show-ExceptionDetails $_ -ShowStack
    }
}
