#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ConfigureWellKnownPaths.ps1                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Set-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Value = $Null,
        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'Machine', 'Session', 'UserSession')]
        [string]$Scope = 'UserSession'
    )
    switch ($Scope.ToLower())
    {
        { 'session', 'usersession' -eq $_ }
        {
            $CurrentSetting = (Get-ChildItem -Path env: -Recurse | % -Process { if ($_.Name -eq $Name) { $_.Value } })

            if (($CurrentSetting -eq $null) -or ($CurrentSetting -ne $null -and $CurrentSetting.Value -ne $Value)) {
                Write-Verbose "Environment Setting $Name is not set or has a different value, changing to $Value"
                $TempPSDrive = $(get-date -Format "temp\hhh-\mmmm-\sss")
                new-psdrive -Name $TempPSDrive -PSProvider Environment -Root env: | Out-null
                $NewValPath = ("$TempPSDrive" + ":\$Name")
                Remove-Item -Path $NewValPath -Force -ErrorAction Ignore | Out-null
                if ($Value -ne $Null) {
                    New-Item -Path $NewValPath -Value $Value -Force -ErrorAction Ignore | Out-null
                }
                Remove-PSDrive $TempPSDrive -Force | Out-null
            }
        }
        { 'user', 'usersession' -eq $_ }
        {
            Write-Verbose "Setting $Name --> $Value [User]"
            [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
        }
        { 'machine' -eq $_ }
        {
            Write-Verbose "Setting $Name --> $Value [Machine]"
            [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Machine)
        }
    }
    Publish-RegistryChanges
}




function Publish-RegistryChanges {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$Timeout = 1000,
        [Parameter(Mandatory = $false, Position = 1)]
        [int]$Flags = 2 # SMTO_ABORTIFHUNG: return if receiving thread does not respond (hangs)
    )
    $TypeAdded = $True
    try {
        [WinAPI.RegAnnounce]$test
    } catch {
        $TypeAdded = $False
        Write-Verbose "WinAPI.RegAnnounce not declared..."
    }
    $Result = $true
    $funcDef = @'

        [DllImport("user32.dll", SetLastError = true, CharSet=CharSet.Auto)]

         public static extern IntPtr SendMessageTimeout (
            IntPtr     hWnd,
            uint       msg,
            UIntPtr    wParam,
            string     lParam,
            uint       fuFlags,
            uint       uTimeout,
        out UIntPtr    lpdwResult
         );

'@

    if ($TypeAdded -eq $False) {
        Write-Verbose "ADDING WinAPI.RegAnnounce"
        $funcRef = add-type -Namespace WinAPI -Name RegAnnounce -MemberDefinition $funcDef
    }

    try {
        $HWND_BROADCAST = [intPtr]0xFFFF
        $WM_SETTINGCHANGE = 0x001A # Same as WM_WININICHANGE
        $fuFlags = $Flags
        $timeOutMs = $Timeout # Timeout in milli seconds
        $res = [uIntPtr]::Zero

        # If the function succeeds, this value is non-zero.
        $funcVal = [WinAPI.RegAnnounce]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", $fuFlags, $timeOutMs, [ref]$res);

        if ($funcVal -eq 0) {
            throw "SendMessageTimeout did not succeed, res= $res"
        }
        else {
            write-Verbose "Message sent"
            return $True
        }
    }
    catch {
        $Result = $False
        Write-Error $_
    }
    return $Result
}

function Publish-SettingsUpdated {
    $cmdFile = Join-Path "$PSScriptRoot" 'RefreshEnv.cmd'
    if (Test-Path $cmdFile) {
        & "$cmdFile"
    }
    Publish-RegistryChanges
}


function Update-ModulesShortcuts {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Filter,
        [Parameter(Mandatory = $false)]
        [switch]$Test
    )
    $TestOnly = $False
    if (($PSBoundParameters.ContainsKey('WhatIf')) -or ($PSBoundParameters.ContainsKey('Test'))) {
        Write-Host '[Update-ModulesShortcuts] ' -ForegroundColor DarkRed -NoNewline
        Write-Host "TEST ONLY" -ForegroundColor Yellow
        $TestOnly = $True
    }

    $FnDefinitions = [System.Collections.Generic.List[string]]::new()
    $AliasDefinitions = [System.Collections.Generic.List[string]]::new()
    $ModuleDevelopmentPath = "C:\Users\$ENV:USERNAME\Documents\PowerShell\Module-Development"

    Write-Host "[Update-ModulesShortcuts] Using module development path: $ModuleDevelopmentPath" -ForegroundColor DarkYellow

    pushd "$ModuleDevelopmentPath"
    $mods = (Get-ChildItem -Path "$ModuleDevelopmentPath" -Directory)
    $modsCount = $mods.Count
    Write-Host "[Update-ModulesShortcuts] Found $modsCount modules." -ForegroundColor Cyan

    if ($PSBoundParameters.ContainsKey('Filter')) {
        $mods = $mods | Where-Object { $_.Name -match "$Filter" }
        $modsCount = $mods.Count
        Write-Host "[Update-ModulesShortcuts] Filtered with '$Filter' -> $modsCount modules." -ForegroundColor Magenta
    }

    foreach ($m in $mods) {
        $name = $m.Name
        $shortname = $name.Substring(18)
        $fullpath = $m.FullName
        $envval = "Mod$shortname"
        $log = "Processing Module $name ($fullpath)"

        if (-not $TestOnly) {
            Write-Host "[Update-ModulesShortcuts] Setting env: $envval => $fullpath" -ForegroundColor Blue
            Set-EnvironmentVariable -Name $envval -Value $fullpath -Scope UserSession
        } else {
            Write-Host "[Update-ModulesShortcuts] [TEST] Would set env: $envval => $fullpath" -ForegroundColor DarkGray
        }

        Write-Host "[Update-ModulesShortcuts] $log" -ForegroundColor DarkYellow

        $AliasDefinitions.Add("New-Alias $envval -Value `"Push-$envval`" -Description `"Push-location `$env:$envval`" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope")
        $FnDefinitions.Add("function Push-$envval {  Write-Host `"Pushd => `$env:$envval`" ; Push-location `$env:$envval; }")
    }

    $ProfilePath = (Get-Item -Path "$Profile").DirectoryName
    $ProfileRepositoryPath = Join-Path $ProfilePath "Profile"
    $PrivateScriptsPath = Join-Path $ProfileRepositoryPath "private"
    $ModulesPathFunctions = Join-Path $PrivateScriptsPath "ModulesPathFunctions.ps1"
    $ModulesPathAliases = Join-Path $PrivateScriptsPath "ModulesPathAliases.ps1"

    Write-Host "[Update-ModulesShortcuts] Generating function/alias script files..." -ForegroundColor Magenta

    Write-FileHeader -FileName "ModulesPathFunctions.ps1" -Description "Generated PowerShell Script with function to move in module path" | Set-Content -Path $ModulesPathFunctions -Force
    Add-Content -Path $ModulesPathFunctions -Value $FnDefinitions -Force
    Write-Host "[Update-ModulesShortcuts] Wrote: $ModulesPathFunctions" -ForegroundColor Green

    Write-FileHeader -FileName "ModulesPathAliases.ps1" -Description "Generated PowerShell Script with function to move in module path" | Set-Content -Path $ModulesPathAliases -Force
    Add-Content -Path $ModulesPathAliases -Value $AliasDefinitions -Force
    Write-Host "[Update-ModulesShortcuts] Wrote: $ModulesPathAliases" -ForegroundColor Green
}



function Get-DocumentsPath {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Verbose "[Get-DocumentsPath] Method 1: Using [System.Environment]::GetFolderPath"

    $path = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    if (Test-Path $path) {
        Write-Verbose "[Get-DocumentsPath] Method 1: found `"$path`""
        return $path
    }

    Write-Verbose "[Get-DocumentsPath] Method 2: Using $HOME environment variable"
    $path = Join-Path $HOME "Documents"
    if (Test-Path $path) {
        Write-Verbose "[Get-DocumentsPath] Method 2: found `"$path`""
        return $path
    }

    Write-Verbose "[Get-DocumentsPath] Method 3: Using Shell.SpecialFolder via COM Object"
    try {
        $shell = New-Object -ComObject Shell.Application
        $path = $shell.Namespace(16).Self.Path # 16 corresponds to MyDocuments
        if (Test-Path $path) {
            Write-Verbose "[Get-DocumentsPath] Method 3: found `"$path`""
            return $path
        }
    } catch {
        # Handle COM failure gracefully
    }

    Write-Verbose "[Get-DocumentsPath] Method 4: Using [Environment]::ExpandEnvironmentVariables"
    $path = [Environment]::ExpandEnvironmentVariables("%USERPROFILE%\Documents")
    if (Test-Path $path) {
        Write-Verbose "[Get-DocumentsPath] Method 4: found `"$path`""
        return $path
    }

    # If all methods fail
    #throw "Unable to determine the Documents path."
    return $Null
}


function Get-CustomPathValues {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $DocumentsPath = Get-DocumentsPath
    $CustomPaths = [ordered]@{}
    $CustomPaths.Add("MyDocuments", "$DocumentsPath")
    $CustomPaths.Add("docs", "$DocumentsPath")
    $CustomPaths.Add("data", "c:\Data")
    $CustomPaths.Add("Vaults", "c:\Data")
    $CustomPaths.Add("DejaToolsRootDirectory", "c:\Dev\DejaInsight")
    $CustomPaths.Add("DevelopmentRoot", "c:\Dev")
    $CustomPaths.Add("ScriptsRoot", "c:\Scripts")
    $CustomPaths.Add("ToolsRoot", "c:\Programs\SystemTools")
    $CustomPaths.Add("wwwroot", "c:\www")
    $CustomPaths.Add("wwwroot2", "c:\www")
    $CustomPaths.Add("siteroot", "c:\www\arsscriptum.github.io")
    $CustomPaths.Add("RedditSupport", "c:\Scripts\PowerShell.RedditSupport")
    $CustomPaths.Add("moddev", "C:\Users\$ENV:USERNAME\Documents\PowerShell\Module-Development")
    $CustomPaths.Add("MyCopilot", "c:\Dev\github-copilot-data-files")
    $CustomPaths.Add("ProfilePath", "C:\Users\$ENV:USERNAME\Documents\PowerShell\Profile")
    $CustomPaths.Add("ProfileScripts", "C:\Users\$ENV:USERNAME\scripts")
    $CustomPaths.Add("ProgramData", "c:\ProgramData")
    $CustomPaths.Add("Sandbox", "c:\Dev\Sandbox")
    $CustomPaths.Add("SystemScripts", "c:\Scripts")
    $CustomPaths.Add("SystemPrograms", "c:\Programs")
    $CustomPaths.Add("PowerShellSandbox", "c:\Scripts\Sandbox\WindowsSandbox")
    $CustomPaths.Add("ScriptsSandbox", "c:\Tmp\Sandbox\WindowsSandbox")
    $CustomPaths.Add("CodeSandbox", "c:\Tmp\Sandbox\WindowsSandbox")
    $CustomPaths.Add("WinSandbox", "c:\Tmp\Sandbox\WindowsSandbox")
    $CustomPaths.Add("CodeTemplates", "c:\Dev\templates")
    $CustomPaths.Add("Templates", "c:\Dev\templates")
    $CustomPaths.Add("LastProject", "c:\Dev\Binary-Vault")
    $CustomPaths.Add("NOTES", "C:\Users\$ENV:USERNAME\Documents\NOTES")
    $CustomPaths.Add("TODO", "C:\Users\$ENV:USERNAME\Documents\NOTES\TODO.md")
    $CustomPaths.Add("ProjectNotes", "C:\Users\$ENV:USERNAME\Documents\NOTES\Projects.md")
    $CustomPaths.Add("VersionPatcher", "C:\Dev\Native.VersionPatcher\bin\Win32\Release\verpatch.exe")
    $CustomPaths.Add("MyDownloads", "C:\Users\$ENV:USERNAME\Downloads")
    $CustomPaths.Add("MyResources", "$ENV:Resources")
    $CustomPaths.Add("Burn", "$ENV:CDBurning")
    $CustomPaths.Add("MyFonts", "$ENV:Fonts")
    $CustomPaths.Add("MyCookies", "$ENV:Cookies")
    $CustomPaths.Add("MyHistory", "$ENV:History")
    $CustomPaths.Add("NetLinks", "$ENV:NetworkShortcuts")
    $CustomPaths.Add("StartupPath", "$ENV:Startup")
    
    $VideoPath = "C:\Users\$ENV:USERNAME\Videos"
    $YtVideosPath = Join-Path "$VideoPath" "YouTube"
    $RedditVideosPath = Join-Path "$VideoPath" "Reddit"

    $CustomPaths.Add("Videos", "$VideoPath")
    $CustomPaths.Add("YouTubeVideos", "$YtVideosPath")
    $CustomPaths.Add("RedditVideos", "$RedditVideosPath")
    return $CustomPaths
}

function Update-WellKnownPaths {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$NoProgress
    )
    try {
        $VideoPath = "C:\Users\$ENV:USERNAME\Videos"
        $YtVideosPath = Join-Path "$VideoPath" "YouTube"
        $RedditVideosPath = Join-Path "$VideoPath" "Reddit"

        Write-Host "[Update-WellKnownPaths] Checking/creating video paths..." -ForegroundColor Yellow

        if (-not (Test-Path -Path $RedditVideosPath)) {
            Write-Host "[Update-WellKnownPaths] Creating Reddit video directory: $RedditVideosPath" -ForegroundColor DarkYellow
            New-Item -Path "$RedditVideosPath" -ItemType Directory -Force -EA Ignore | Out-Null
        } else {
            Write-Host "[Update-WellKnownPaths] Reddit video directory exists: $RedditVideosPath" -ForegroundColor Green
        }

        if (-not (Test-Path -Path $YtVideosPath)) {
            Write-Host "[Update-WellKnownPaths] Creating YouTube video directory: $YtVideosPath" -ForegroundColor DarkYellow
            New-Item -Path "$YtVideosPath" -ItemType Directory -Force -EA Ignore | Out-Null
        } else {
            Write-Host "[Update-WellKnownPaths] YouTube video directory exists: $YtVideosPath" -ForegroundColor Green
        }

        $FnDefinitions = [System.Collections.Generic.List[string]]::new()
        $AliasDefinitions = [System.Collections.Generic.List[string]]::new()
        $CustomPaths = Get-CustomPathValues

        Write-Host "[Update-WellKnownPaths] Updating environment variables and aliases..." -ForegroundColor Cyan
        $CustomPaths.GetEnumerator() | ForEach-Object {
            $VarName = $_.Name
            $VarPath = $_.Value
            Write-Host "[Update-WellKnownPaths] Setting variable: $VarName => $VarPath" -ForegroundColor Blue
            Set-EnvironmentVariable -Name $VarName -Value $VarPath -Scope 'UserSession' | Out-Null

            $AliasName = $VarName.ToLower().Replace("templates", "tpl").Replace("root", "").Replace("sandbox", "sb").Replace("directory", "").Replace("development", "dev").Replace("my", "").Replace("powershell", "ps")
            $AliasDef = "New-Alias $AliasName -Value `"Push-$VarName`" -Description `"Push-location `$env:$VarName`" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope"
            $FnDef = "function Push-$VarName {  Write-Host `"Pushd => `$env:$VarName`" ; Push-location `$env:$VarName; }"
            Write-Host "[Update-WellKnownPaths] Alias: $AliasName, Function: Push-$VarName" -ForegroundColor DarkCyan

            $AliasDefinitions.Add($AliasDef)
            $FnDefinitions.Add($FnDef)
        }

        $ProfilePath = (Get-Item -Path "$Profile").DirectoryName
        $ProfileRepositoryPath = Join-Path $ProfilePath "Profile"
        $PrivateScriptsPath = Join-Path $ProfileRepositoryPath "private"
        $CustomPathFunctions = Join-Path $PrivateScriptsPath "CustomPathFunctions.ps1"
        $CustomPathAliases = Join-Path $PrivateScriptsPath "CustomPathAliases.ps1"

        Write-Host "[Update-WellKnownPaths] Generating function and alias script files..." -ForegroundColor Magenta

        Write-FileHeader -FileName "CustomPathFunctions.ps1" -Description "Generated PowerShell Script with function to move in custom path" | Set-Content -Path $CustomPathFunctions -Force
        Add-Content -Path $CustomPathFunctions -Value $FnDefinitions -Force
        Write-Host "[Update-WellKnownPaths] Wrote: $CustomPathFunctions" -ForegroundColor Green

        Write-FileHeader -FileName "CustomPathAliases.ps1" -Description "Generated PowerShell Script with function to move in custom path" | Set-Content -Path $CustomPathAliases -Force
        Add-Content -Path $CustomPathAliases -Value $AliasDefinitions -Force
        Write-Host "[Update-WellKnownPaths] Wrote: $CustomPathAliases" -ForegroundColor Green

    } catch {
        Write-Host "[Update-WellKnownPaths] ERROR: $_" -ForegroundColor Red
        Write-Error "$_"
    }
}

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC66c3T3yyuIolc
# DSqDdUDLPkXvqMvzIDRIs4Zjhx2lTaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
# p0U/KDSBkGfnMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI0d1aWxsYXVtZSBQ
# bGFudGUgKERldiBDb2RlIFNpZ25pbmcpMB4XDTI1MTExMDAxMzk1MVoXDTI4MTEx
# MDAxNDk1MFowLjEsMCoGA1UEAwwjR3VpbGxhdW1lIFBsYW50ZSAoRGV2IENvZGUg
# U2lnbmluZykwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDNtS5Po9Nh
# zeqSwRPGh7K9cW2vIzSjyQSe+RwMf9uqvtWSgQ1NdYVz2BHaCY2P6+nyaPwj6IqY
# OnWI2NI6iPTSbOZgGot7KI7m7PyLnXlTeLROt77j9uoYqSlFdt0AAIGULpzPBH+a
# L7fp81YQtgEANaAgHx9+DcvyBBnVNirUyL8qgxXrGiERX73FC7Xjp0ZwhPNiE6Qn
# GH62IhZHEhpevLFvHPA049DBoo3J1x1AFzTVRpWEpQiy2PzMiYQzHtjTdggLcEUM
# 4AaK8E8koLvehCs4Su0XetmF3mBExAhKTZe0X9sPzvpn77698N2SPnlPmnal7Evv
# XvN3UVB8I6dwQsSDth52EXWU8dHoBdR/Fr3K6ncj3Tr2Lt2QhRtWFVBL91YiXl8z
# Ki+pGC1URu+3mJgeIv6djB38WFVUOwveI914UKL8834H0xYKnzjRsgcAMI1cu3BA
# 9W1GCEaDOmxL9PX1QzfgpgGyXW9klqMhCFBhtO048hXpgruamHBVER0CAwEAAaNG
# MEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQW
# BBQyHm576+dQI3D2EeTojJF7IUH2eTANBgkqhkiG9w0BAQsFAAOCAYEAMuuH5/Ru
# wEm6w1nNYcixd9yWRgK6I6egsIHmuKJNvZU3sXZKBrDZqW1cTOcgezXgzkInfO7/
# nY54DuG4Y1CP1caL80F8WRouSptwd7RJmKwd9lAUsPjaLDZt+Asa3OjYwIlB3Y5Q
# sbFMs1QXZzLI2TBAJ8hYRnagEx20YLvzvF75Re8SlgzmI/G5tR7fsyz9+xTrJtAo
# H1rXhTMid5rYPNwnJs3htwHesUUY1f+SL4Lx904zut8tFlSjNSPFkDGU2PJzcjNf
# 1zButoZe7rwuIB9NLCBwBEuBzxuqxwRGPwl5Xesa49fPhieUQCYxYcVFs0SZbqul
# wlX8LjhQp10bat3KqzZiYJ5vb5zWXopHbvC22DvOMrUV7dCX5L1jcsXa0FB0SAc5
# pxd+46MarKv3GYjgKhqJ6N1+4YIMkAQ0z4OSXPcMHSDFzAL17EPInDBGXDsaaRmR
# w6eNDXRkW/zBgU0VkROO/IJucQIl8wrwqdMQO4Y+67OIqUJ0VQ216XCQMYICdDCC
# AnACAQEwQjAuMSwwKgYDVQQDDCNHdWlsbGF1bWUgUGxhbnRlIChEZXYgQ29kZSBT
# aWduaW5nKQIQFIjQDRt846dFPyg0gZBn5zANBglghkgBZQMEAgEFAKCBhDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCC0
# EAdOoPUVDrCR28YkbJ89AM90E1SnAAtBbkLCT6uglzANBgkqhkiG9w0BAQEFAASC
# AYCaVBbDmKGSc50JxKx/MhYnGZZZLIaJjOlbmf7DdvrDXS+wm6mPSxeQ+d88Ycje
# yQp8RMypTGFyM5YdtTryMTYjN1rU/ybQ2eM2E7Qi5EvcOnFZwKTs5tgzmmu7EBtT
# QlZGOjwtyWl6tGuWMgjFWpYz7WcPLWgHopnNLFkF0v5g15Mi9a59M0Pjx3mOcanh
# e1rJ2Ma4OqRjYWv6VFXNJPWhm/YZKZwG63KAZ6nuEkCE/lV4ANTuq+OedAt+C91+
# /EDCJFgX4sewGLzD7+3Ts0VagzaOQkPvN5xHmPuAsT+a7rEcLLME6sxZqFblwZdL
# 95ZV91IT68ksh96qAVATY8Jsr0Kzv2g/qlXJiVXjagsHZ5JAYojGYb+Pe9NtvF2G
# zW8qnX65ZnNVjqzobWlyiRpvHNtDHXMfs3wZazBGajjNBnTx2Kd1pBQ2OXAISCeM
# DMBPrx4A6l+cN+Q/C+/5UK1Si/B75rsxnvdOFfypiImgpWtb2NjEAFhI9tYWTwne
# GKE=
# SIG # End signature block
