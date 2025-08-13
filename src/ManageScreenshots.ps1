#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   initialize.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Invoke-ManageScreenshotArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'Maximum archive size in MB')]
        [ValidateRange(1, 1024)]
        [int]$MaxArchiveSizeMB = 25,

        [Parameter(Mandatory = $false, HelpMessage = 'Maximum file age in days')]
        [ValidateRange(1, 365)]
        [int]$MaxFileAgeDays = 7,

        [Parameter(Mandatory = $false, HelpMessage = 'Screenshots source folder')]
        [string]$SourcePath = "C:\ProgramData\Screenshots",

        [Parameter(Mandatory = $false, HelpMessage = 'Archive folder')]
        [string]$ArchivePath = "C:\ProgramData\Screenshots\Archives",
        [Parameter(Mandatory = $false, HelpMessage = 'Maximum file age in days')]
        [switch]$Clean
    )

    try {
        # Ensure archive folder exists
        if (-not (Test-Path $ArchivePath)) {
            New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
        }



        # Move all .png files to the archive
        $filesToMove = Get-ChildItem -Path $SourcePath -Filter "*.png" -File -ErrorAction SilentlyContinue
        if($Clean){
            Remove-Item -Path "$SourcePath\*.png" -Force | Out-Null
            Remove-Item -Path $ArchivePath -Force -Recurse | Out-Null
            New-Item -Path $ArchivePath -Force -ItemType Directory | Out-Null
            Write-Host "Removed All Files..." -f DarkRed
            return
        }elseif ($filesToMove) {
            Write-Verbose "Moving $($filesToMove.Count) file(s) to archive..."
            Move-Item -Path $filesToMove.FullName -Destination $ArchivePath -Force
        }


        # Delete files older than MaxFileAgeDays
        $cutOffDate = (Get-Date).AddDays(-$MaxFileAgeDays)
        $oldFiles = Get-ChildItem -Path $ArchivePath -File | Where-Object { $_.LastWriteTime -lt $cutOffDate }
        foreach ($file in $oldFiles) {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Delete old file")) {
                Remove-Item -Path $file.FullName -Force
            }
        }

        # Check total size and reduce until < MaxArchiveSizeMB
        $sizeLimitBytes = $MaxArchiveSizeMB * 1MB
        $archiveFiles = Get-ChildItem -Path $ArchivePath -File | Sort-Object LastWriteTime
        $totalSize = ($archiveFiles | Measure-Object Length -Sum).Sum

        while ($totalSize -gt $sizeLimitBytes -and $archiveFiles.Count -gt 0) {
            $oldestFile = $archiveFiles[0]
            if ($PSCmdlet.ShouldProcess($oldestFile.FullName, "Delete to maintain size limit")) {
                Remove-Item -Path $oldestFile.FullName -Force
                Write-Verbose "Deleted: $($oldestFile.Name) to maintain archive size."
            }

            # Update file list and total size
            $archiveFiles = Get-ChildItem -Path $ArchivePath -File | Sort-Object LastWriteTime
            $totalSize = ($archiveFiles | Measure-Object Length -Sum).Sum
        }

        $Log = "Archive maintenance complete. Current archive size: {0:N2} MB" -f ($totalSize / 1MB)
        Write-Host "$Log"
    }
    catch {
        Write-Error "Error managing screenshot archive: $_"
    }
}
