function Find-ModulePaths {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Name of the subfolder to search in all PSModulePath locations.")]
        [string]$ModuleFolder,

        [Parameter(Mandatory = $false, HelpMessage = "Delete matching folders if found.")]
        [switch]$Delete
    )

    $foundPaths = @()

    # Split PSModulePath on ; for Windows
    $modulePaths = $env:PSModulePath -split ';'

    foreach ($basePath in $modulePaths) {
        $fullPath = Join-Path -Path $basePath -ChildPath $ModuleFolder

        if (Test-Path -Path $fullPath) {
            Write-Host "Found: $fullPath"
            $foundPaths += $fullPath

            if ($Delete.IsPresent) {
                if ($PSCmdlet.ShouldProcess($fullPath, "Delete folder")) {
                    Write-Host "Deleting: $fullPath"
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                    Write-Host "Deleted: $fullPath"
                }
            }
        }
    }

    if ($foundPaths.Count -eq 0) {
        Write-Host "No folders found matching '$ModuleFolder' in PSModulePath."
    }

    return $foundPaths
}

function Show-FunctionPath {
    $path = $null
    $folder = $null

    if ($MyInvocation.MyCommand.Path) {
        $path = $MyInvocation.MyCommand.Path
        $folder = Split-Path -Path $path -Parent
        Write-Host "This function is in script file: $path"
        Write-Host "Folder: $folder"
    }
    elseif ($MyInvocation.MyCommand.Module) {
        $folder = $MyInvocation.MyCommand.Module.ModuleBase
        Write-Host "Running from module folder: $folder"
    }
    else {
        $folder = (Get-Location).Path
        Write-Host "Running interactively in console. Current folder: $folder"
    }
}
