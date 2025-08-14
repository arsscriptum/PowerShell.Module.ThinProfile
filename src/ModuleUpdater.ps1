#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   moduleupdater.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-ThinProfileModuleVersionPath {
    $ModPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $VersionPath = Join-Path $ModPath 'version'
    return $VersionPath
}

function Test-FileHashMatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "File '$_' does not exist or is not a valid file."
            }
            return $true
        })]
        [string]$File,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript({
            try {
                $null = [uri]$_
                return [uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute)
            } catch {
                return $false
            }
        })]
        [string]$HashUrl
    )
   
    $expected = (Invoke-RestMethod -Uri $HashUrl -TimeoutSec 10).Trim()
    $actual = (Get-FileHash -Path $File -Algorithm SHA256).Hash
    return ($expected -eq $actual)
}

function Get-RemoteText {
    param([string]$Url, [int]$Retries = 3)
    for ($i = 0; $i -lt $Retries; $i++) {
        try { return (Invoke-RestMethod -Uri $Url -TimeoutSec 10) }
        catch {
            if ($i -eq $Retries - 1) { throw }
            Start-Sleep -Seconds ([math]::Pow(2, $i))
        }
    }
}


function New-ThinProfileModuleVersionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$AutoUpdateFlag,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    $ThinProfileVersionPath = Get-ThinProfileModuleVersionPath
    $JsonPath = (Join-Path $ThinProfileVersionPath "clienttools.json")
    $CurrDate = Get-Date -UFormat "%s"
    $ModuleName = (Get-ThinProfileModuleInformation).ModuleName.Name
    $ModuleInstallPath = (Get-ThinProfileModuleInformation).ModuleInstallPath
    $ModulePath = (Get-ThinProfileModuleInformation).ModulePath

    $psm1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psm1'
    $psd1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psd1'

    $ValidFiles = ((Test-Path "$psm1path") -and (Test-Path "$psd1path"))
    if (!$ValidFiles) {
        Write-Error "Missing Module File"
    }


    $UpdateUrl = "https://arsscriptum.github.io/{0}" -f $ModuleName
    $VersionUrl = "https://arsscriptum.github.io/{0}/{1}" -f $ModuleName, "Version.nfo"
    $CurrVersion = Get-ThinProfileModuleVersion
    if ((!(Test-Path "$JsonPath")) -or ($Force)) {
        [pscustomobject]$o = [pscustomobject]@{
            CurrentVersion = "$CurrVersion"
            LastUpdate = "$CurrDate"
            UpdateUrl = "$UpdateUrl"
            VersionUrl = "$VersionUrl"
            ModuleName = "$ModuleName"
            AutoUpdate = $AutoUpdateFlag
            LocalPSM1 = "$psm1path"
            LocalPSD1 = "$psd1path"
        }
        $NewFileJsonData = $o | ConvertTo-Json
        New-Item -Path "$JsonPath" -ItemType File -Force -EA Stop -Value $NewFileJsonData | Out-Null
    }

}


function Set-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [bool]$Enable
    )


    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        New-Item -Path $RegKeyRoot -Force | Out-Null
    }
    $Val = if ($Enable) { 1 } else { 0 }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    Set-ItemProperty -Path $RegKeyRoot -Name "override" -Value $Val -Type DWORD
}


function Get-ThinProfileAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\ThinProfileAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        return $False
    }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    $RegVal = Get-ItemProperty -Path $RegKeyRoot -Name "override" -ErrorAction Ignore
    if (-not ($RegVal)) {
        return $False
    }
    if ($RegVal.override) {
        return $True
    }
    return $False
}


function Invoke-ThinProfileAutoUpdate {
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $False, HelpMessage = 'Force')]
        [switch]$Force,
        [Parameter(Mandatory = $False, HelpMessage = 'Import')]
        [switch]$Import
    )
    try {
        $TestFileHashMatch = $True
        $TestFileHashMatchSignature = $False
        
        if (Get-ThinProfileAutoUpdateOverride) {
            Write-Host "[Invoke-ThinProfileAutoUpdate] Bypass Override" -ForegroundColor DarkRed
            return
        }

        $verDir = Get-ThinProfileModuleVersionPath
        $json = Join-Path $verDir "clienttools.json"
        if (-not (Test-Path $json)) { New-ThinProfileModuleVersionFile }

        $data = Get-Content $json -Raw | ConvertFrom-Json
        [version]$curr = Get-ThinProfileModuleVersion

        try {
            [version]$remote = [version](Get-RemoteText -Url $data.VersionUrl)
        } catch {
            Write-Verbose "Version check failed: $_"
            return
        }

        if (-not ($Force -or ($remote -gt $curr))) {
            Write-Verbose "No update required ($curr)"
            return
        }

        $info = Get-ThinProfileModuleInformation
        $root = Split-Path -Parent $info.ModuleInstallPath
        $target = Join-Path $root "$remote"
        if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }

        $psd1 = Join-Path $target "$($data.ModuleName).psd1"
        $psm1 = Join-Path $target "$($data.ModuleName).psm1"

        $tmp1 = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
        $tmp2 = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())

        $urlPsd1 = "$($data.UpdateUrl)/$($data.ModuleName).psd1"
        $urlPsm1 = "$($data.UpdateUrl)/$($data.ModuleName).psm1"
        Write-Verbose "psm1 ($psm1)"
        Write-Verbose "psd1 ($psd1)"
        Write-Verbose "urlPsm1 ($urlPsm1)"
        Write-Verbose "urlPsd1 ($urlPsd1)"

        try {
            Invoke-WebRequest $urlPsm1 -OutFile $tmp2 -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Host "Failed to get data file from `"$urlPsm1`" -> $tmp2" -f DarkRed
            throw "Failed to get data file from `"$urlPsm1`" -> $tmp2`n$_"
        }

        try {
            Invoke-WebRequest $urlPsd1 -OutFile $tmp1 -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Host "Failed to get data file from `"$urlPsd1`" -> $tmp1" -f DarkRed
            throw "Failed to get data file from `"$urlPsd1`" -> $tmp1`n$_"
        }

        # After download:
        
        if ($TestFileHashMatch) {
            $ChecksumUrl = "{0}/{1}.psm1.sha256" -f "$($Data.UpdateUrl)","$($Data.ModuleName)"
            $psm1HackCheck = Test-FileHashMatch $ChecksumUrl $psm1tmp
            if (-not ($psm1HackCheck)) {
                throw "Hash mismatch for PSM1."
            }
            Write-Host "✅ psm1 File Hash $psm1tmp is GOOD"

            $ChecksumUrl = "{0}/{1}.psd1.sha256" -f "$($Data.UpdateUrl)","$($Data.ModuleName)"
            $psd1HackCheck = Test-FileHashMatch $ChecksumUrl $psd1tmp
            if (-not ($ChecksumUrl)) {
                throw "Hash mismatch for PSD1."
            }
            Write-Host "✅ psd1 File Hash $psm1tmp is GOOD"

            # (Optional) signature
            if ($TestFileHashMatchSignature) {
                $sig = Get-AuthenticodeSignature -FilePath "$psm1tmp" -ErrorAction Ignore
                if ( ($sig -eq $Null) -Or ($sig.Status -ne 'Valid') ) { throw "Invalid signature on PSM1: $($sig.Status)" }

                $man = Test-ModuleManifest -Path $tmp1
                if ([version]$man.ModuleVersion -ne $remote) {
                    throw "Manifest version $($man.ModuleVersion) != announced $remote"
                }
            }
        }

        Move-Item $tmp1 $psd1 -Force
        Move-Item $tmp2 $psm1 -Force

        $data.CurrentVersion = $remote.ToString()
        $data.LocalPSD1 = $psd1
        $data.LocalPSM1 = $psm1
        $data | ConvertTo-Json -Depth 4 | Set-Content -Path $json -Encoding UTF8

        Write-ThinProfileHost "✅ Updated to $remote"

        if ($Import) {
            # optional safe reload
            Remove-Module $info.ModuleName -Force -ErrorAction SilentlyContinue
            Import-Module $info.ModuleName -MinimumVersion $remote -Force
        }
    } catch {
        Write-Verbose "Version update failed: $_"
        return
    }
}
