#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ModulesPathAliases.ps1                                                    ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
New-Alias ModAssert -Value "Push-ModAssert" -Description "Push-location $env:ModAssert" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModClientTools -Value "Push-ModClientTools" -Description "Push-location $env:ModClientTools" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCompiler -Value "Push-ModCompiler" -Description "Push-location $env:ModCompiler" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCore -Value "Push-ModCore" -Description "Push-location $env:ModCore" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModCryptography -Value "Push-ModCryptography" -Description "Push-location $env:ModCryptography" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModDocker -Value "Push-ModDocker" -Description "Push-location $env:ModDocker" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModDownloader -Value "Push-ModDownloader" -Description "Push-location $env:ModDownloader" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModGithub -Value "Push-ModGithub" -Description "Push-location $env:ModGithub" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModIniConfig -Value "Push-ModIniConfig" -Description "Push-location $env:ModIniConfig" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModManageMini -Value "Push-ModManageMini" -Description "Push-location $env:ModManageMini" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModMiniPc -Value "Push-ModMiniPc" -Description "Push-location $env:ModMiniPc" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModNtRights -Value "Push-ModNtRights" -Description "Push-location $env:ModNtRights" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModOpenHwdMon -Value "Push-ModOpenHwdMon" -Description "Push-location $env:ModOpenHwdMon" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModPackageDownloader -Value "Push-ModPackageDownloader" -Description "Push-location $env:ModPackageDownloader" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModProfileUtils -Value "Push-ModProfileUtils" -Description "Push-location $env:ModProfileUtils" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModReddit -Value "Push-ModReddit" -Description "Push-location $env:ModReddit" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModShellGPT -Value "Push-ModShellGPT" -Description "Push-location $env:ModShellGPT" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModShim -Value "Push-ModShim" -Description "Push-location $env:ModShim" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTakeOwnership -Value "Push-ModTakeOwnership" -Description "Push-location $env:ModTakeOwnership" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTerminal -Value "Push-ModTerminal" -Description "Push-location $env:ModTerminal" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModThinProfile -Value "Push-ModThinProfile" -Description "Push-location $env:ModThinProfile" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModTools -Value "Push-ModTools" -Description "Push-location $env:ModTools" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModWindowsHost -Value "Push-ModWindowsHost" -Description "Push-location $env:ModWindowsHost" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias ModZBookHardware -Value "Push-ModZBookHardware" -Description "Push-location $env:ModZBookHardware" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
New-Alias Modter2K -Value "Push-Modter2K" -Description "Push-location $env:Modter2K" -Scope Global -Force -ErrorAction Stop -Option ReadOnly,AllScope
