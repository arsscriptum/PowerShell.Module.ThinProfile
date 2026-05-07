

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   StartExplorer.ps1                                                            |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+

function Start-Explorer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Path to the log file")]
        [alias('p')]
        [string]$Path = (Get-Location).Path,
        [Parameter(Mandatory = $false)]
        [alias('q')]
        [switch]$Quiet

    )

    try {

        $ExpCmd =  Get-Command 'explorer.exe' -CommandType Application -ErrorAction Ignore
        if ($ExpCmd -eq $Null) {
            Write-Error "explorer.exe not in path"
            return
        }
        $ExpExe = $ExpCmd.Path 

        if (-not (Test-Path -Path $ExpExe)) {
            Write-Error "Explorer not found: '$ExpExe'"
            return
        }
        if (-not (Test-Path -Path "$Path")) {
            Write-Error "Path not found: '$Path'"
            return
        }
        [System.Collections.ArrayList]$CmdArguments = [System.Collections.ArrayList]::new()
        [void]$CmdArguments.Add("$Path")
        $AllCmds = $CmdArguments -join ' '

        $ProcessArgs = @{
            FilePath = "$ExpExe"
            ArgumentList = $CmdArguments
            WorkingDirectory = "$Path"
            NoNewWindow = $False
            PassThru = $False
            Wait = $False
        }
        if($Quiet){
            Write-Verbose "[launching $ExpExe] in `"$Path`""
        } else {
            Write-Host -n "[launching $ExpExe]" -f DarkRed 
            Write-Host " in `"$AllCmds`"" -f DarkYellow    
        }
        
        Start-Process @ProcessArgs


    } catch {
        Write-Error "$_"
    }
}


function Start-DownloadBrowser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [alias('x')]
        [switch]$Explorer
    )
    try {

        if( ([string]::IsNullOrEmpty($ENV:DOWNLOAD_PATH)) -Or (-not (Test-Path -Path "$ENV:DOWNLOAD_PATH")) ) {
            $DownloadPath = "C:\DATA\Downloads"
            Write-Verbose "Using default `"$DownloadPath`""
        } else {
            Write-Host "Using ENV:DOWNLOAD_PATH `"$ENV:DOWNLOAD_PATH`""
            $DownloadPath = "$ENV:DOWNLOAD_PATH"
        }
        if($Explorer){
            Write-Verbose "[launching $ExpExe] in `"$DownloadPath`""
            Start-Explorer "$DownloadPath"
        } else {
            Write-Host -n "[Push-Location $DownloadPath]" -f DarkRed  
            Push-Location "$DownloadPath"
        }
    } catch {
        Write-Error "$_"
    }
}

New-alias -Name goto-download -Value Start-DownloadBrowser -Force -ErrorAction Ignore -Scope GLobal -Option AllScope
New-alias -Name downloaddir -Value Start-DownloadBrowser -Force -ErrorAction Ignore -Scope GLobal -Option AllScope
New-alias -Name x -Value Start-Explorer -Force -ErrorAction Ignore -Scope GLobal -Option AllScope