

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

function Get-MsBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Path to the log file")]
        [ValidateSet('16','17')]
        [int]$MajorVersion=17
    )

    try {
        $VsWhere = "$ENV:VSWHERE_PATH"
       
        if (-not (Test-Path -Path $VsWhere)) {
            Write-Error "VsWhere.exe not found at '$VsWhere'."
            return
        }
        $VsVersions = New-GenericDictionary 
        $msbuild = New-GenericDictionary 
        $dataJson = &"$VsWhere" '-format' 'json' '-all' | ConvertFrom-json
        ForEach($instance in $dataJson){
            [Version]$v = $instance.installationVersion
            $p = $instance.installationPath
            $VsVersions[$v.Major] = $v
            $msbuildPath = Join-Path "$p" "MSBuild\Current\Bin\MSBuild.exe"
            if(Test-Path "$msbuildPath"){
               $msbuild[$v.Major] = $msbuildPath    
            }
        }            
        
        return $msbuild[$MajorVersion]
    
    } catch {
        Write-Error "$_"
    }
}


function Start-Vs2022Shell {
    [CmdletBinding()]
    param()

    try {

        $Vs2022PsShell = "$ENV:VS2022_PS_SHELL"
       
        if (-not (Test-Path -Path $Vs2022PsShell)) {
            Write-Error "Vs2022PsShell script not found at '$Vs2022PsShell'."
            return
        }

        Write-Host "Running `"$Vs2022PsShell`"" -f DarkCyan
        . "$Vs2022PsShell"


    } catch {
        Write-Error "$_"
    }
}

function Start-Vs2019Shell {
    [CmdletBinding()]
    param()

    try {

        $Vs2019PsShell = "$ENV:VS2019_PS_SHELL"
       
        if (-not (Test-Path -Path $Vs2019PsShell)) {
            Write-Error "Vs2019PsShell script not found at '$Vs2019PsShell'."
            return
        }

        Write-Host "Running `"$Vs2019PsShell`"" -f DarkCyan
        . "$Vs2019PsShell"


    } catch {
        Write-Error "$_"
    }
}


function Show-MsBuildOutput {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory = $False)]
        [switch]$OnlyFailed  
    )
    $PrintAll = if($OnlyFailed){ $False }else{ $True }
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    Get-Content $Path | ForEach-Object {

        $line = $_

        # 1️⃣ Line ends with "-- FAILED."
        if ($line.TrimEnd().EndsWith('-- FAILED.')) {
            Write-Host $line -ForegroundColor DarkRed
            return
        }

        # 2️⃣ Line starts with "Done Building Project" (but NOT failed)
        if ($line.StartsWith('Done Building Project')) {
            if($PrintAll){ 
                Write-Host $line -ForegroundColor DarkCyan
            }            
            
            return
        }

        # 3️⃣ Warning(s)
        if ($line -match 'Warning\(s\)') {
            if($PrintAll){ 
                Write-Host $line -ForegroundColor DarkYellow
            }
            
            return
        }

        # 4️⃣ Error(s)
        if ($line -match 'Error\(s\)') {
            Write-Host $line -ForegroundColor Red
            return
        }
        if($PrintAll){ 
            Write-Host $line -DarkGray
        }
        
        
    }
}

function Build-Sln {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the log file")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory = $false, HelpMessage = "vs version")]
        [ValidateSet('Build', 'Rebuild', 'Clean')]
        [string]$Target='Build',
        [Parameter(Mandatory = $false, HelpMessage = "vs version")]
        [ValidateSet('Debug', 'Release')]
        [string]$Configuration='Debug',
        [Parameter(Mandatory = $false, HelpMessage = "vs version")]
        [ValidateSet('Win32', 'Win64', 'x86', 'x64')]
        [string]$Platform='Win32',  
        [Parameter(Mandatory = $false, HelpMessage = "vs version")]
        [ValidateSet('16','17')]
        [int]$MajorVersion=17,
        [Parameter(Mandatory = $False)]
        [switch]$Quiet               
    )

    try {
        $InShell = (-not([string]::IsNullOrEmpty($env:IN_VS_SHELL)) -and ("$env:IN_VS_SHELL" -eq "1"))

        if($InShell -eq $False){
            Write-Host "starting shell..."
            Start-Vs2022Shell
        }
        if(isadmin){
            Enable-NetAdapter -Name "ETH0" -Confirm:$False
        }
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Path not found  $Path"
            return
        }        
        $MsBuildExe = Get-MsBuild $MajorVersion
       
        if (-not (Test-Path -Path $MsBuildExe)) {
            Write-Error "MsBuildExe not found from vs $MajorVersion"
            return
        }
        $Targets = @()
        $Configurations = @()
        $StdOut = (New-TemporaryFile).FullName
        $StdErr = (New-TemporaryFile).FullName
        $SlnId = (Get-Item "$Path").Name
        $Destination  = (Get-Item "$Path").DirectoryName
        [System.Collections.ArrayList]$VsArgs = [System.Collections.ArrayList]::new()
        # (You had an initial empty Add; we just build cleanly)
        [void]$VsArgs.Add("`"$Path`"")
        [void]$VsArgs.Add("/t:$Target")
        [void]$VsArgs.Add("/p:Platform=$Platform")
        [void]$VsArgs.Add("/p:Configuration=$Configuration")


        $argsPreview = $VsArgs -join ' '
        Write-Verbose "MsBuildExe executable: $MsBuildExe"
        Write-Verbose "MsBuildExe version: $MajorVersion"
        Write-Verbose "Command: msbuild $argsPreview"
        $StartProcessArgs = @()

        [pscustomobject]$StartProcessArgs = @{
                    FilePath = $MsBuildExe 
                    ArgumentList = $VsArgs 
                    Wait = $False
                    WorkingDirectory = $Destination 
                    NoNewWindow = $True
                    PassThru = $True
        }

        if($Quiet){
           $StartProcessArgs['RedirectStandardError'] = $StdErr 
           $StartProcessArgs['RedirectStandardOutput'] = $StdOut    
        }

        
        try {
            $TargetStr = $Target + "ing"
            Write-Host "`n$TargetStr $SlnId ($Platform | $Configuration)" -f DarkCyan -n 
            $proc = Start-Process @StartProcessArgs;
            $exit = $proc.ExitCode
            $done = $proc.HasExited
            Write-Host "..." -n -f DarkGray
            while(-not($done)){
                Write-Host "." -n -f DarkGray
                Start-Sleep -Milliseconds 500
                $done = $proc.HasExited

            }
            $Res = Get-Content -Path "$StdOut" | Select -Last 5
            $exit = $proc.ExitCode
            if ($exit -ne 0) {        
                Write-Host "`nError Compiling $SlnId `: $exit" -f DarkRed
                if($Quiet){
                    Show-MsBuildOutput "$StdOut" -OnlyFailed

                } else{
                    Show-MsBuildOutput "$StdOut"                    
                }
                
            } else {
                Write-Host "`nSuccessfully $Target $SlnId `: $exit" -f DarkGreen
                Write-Host "`n$Res" -f DarkGreen
            }
            

        }
        catch {
            # Keep logs around so caller can inspect; uncomment to auto-clean:
            # Remove-Item -Path $StdOut,$StdErr -Force -ErrorAction SilentlyContinue
        }
        finally {
            # Keep logs around so caller can inspect; uncomment to auto-clean:
            # Remove-Item -Path $StdOut,$StdErr -Force -ErrorAction SilentlyContinue
        }
    
    } catch {
        Write-Error "$_"
    }
}

function Build-Ceda {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "vs version")]
        [ValidateSet('Build', 'Rebuild', 'Clean')]
        [string]$Target='Build',        
        [Parameter(Mandatory = $False)]
        [switch]$ShowLogs
    )
    $Quiet = ($ShowLogs -eq $False)
    Build-Sln -Path "C:\Dev\EATON\cfd-hq-consoles-ceda\Components\CEDA\Code\Ceda32.sln" -Target $Target -Quiet:$Quiet
}

New-alias -Name bceda -Value Build-Ceda -Force -ErrorAction Ignore -Scope GLobal -Option AllScope

New-alias -Name ps2019 -Value Start-Vs2019Shell -Force -ErrorAction Ignore -Scope GLobal -Option AllScope
New-alias -Name ps2022 -Value Start-Vs2022Shell -Force -ErrorAction Ignore -Scope GLobal -Option AllScope