#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ImportIcons.ps1                                                           ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
# Convert-PngsToIco "C:\Users\gp\Pictures" "C:\Users\gp\Images\icons"
function Convert-PngsToIco {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SourceDir,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DestDir           
    )

    $MagickExe = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"

    if (-not (Test-Path $DestDir)) {
        New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
    }

    $pngFiles = Get-ChildItem -Path $SourceDir -Filter *.png -File

    foreach ($file in $pngFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $safeBase = $baseName -replace ' ', ''
        $icoName = "$safeBase.ico"
        $icoPath = Join-Path $DestDir $icoName

        $args = @("""$($file.FullName)""", "-resize", "256x256", """$icoPath""")
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()

        $proc = Start-Process -FilePath $MagickExe -ArgumentList $args `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr

        if ($proc.ExitCode -ne 0) {
            Write-Warning "Failed to convert $($file.Name): $(Get-Content $stderr -Raw)"
        } else {
            Write-Host "Converted $($file.Name) -> $icoName"
        }

        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}