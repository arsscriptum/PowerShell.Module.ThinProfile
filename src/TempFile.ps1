

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   TempFile.ps1                                                                 |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+


function New-TempFileExt {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Optional extension suffix; 1–4 characters, no invalid filename chars
        [Parameter(Mandatory = $false, position = 0)]
        [ValidateLength(1, 4)]
        [ValidatePattern('^[^\\/:*?"<>|]+$')]
        [Alias('s')]
        [string]$Suffix,
        [Parameter(Mandatory = $false)]
        [Alias('x')]
        [switch]$FileInfo
    )

    # Create the temporary file
    $tempFile = New-TemporaryFile

    # If a suffix was provided, normalize it and rename the file
    if ($PSBoundParameters.ContainsKey('Suffix') -and $Suffix) {
        # Trim whitespace and remove any leading dot
        $normalized = $Suffix.Trim()
        if ($normalized.StartsWith('.')) {
            $normalized = $normalized.TrimStart('.')
        }

        # Compute destination path with new extension
        $destPath = [System.IO.Path]::ChangeExtension($tempFile.FullName, $normalized)

        # If a file with that name already exists (unlikely, but safe to handle), create a unique name
        if (Test-Path -LiteralPath $destPath) {
            $dir = $tempFile.DirectoryName
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($tempFile.Name)
            $i = 1
            do {
                $candidate = "$baseName-$i.$normalized"
                $destPath = Join-Path -Path $dir -ChildPath $candidate
                $i++
            } while (Test-Path -LiteralPath $destPath)
        }

        # Rename (move) the file to the new extension
        Move-Item -LiteralPath $tempFile.FullName -Destination $destPath
        $infoFile = Get-Item -LiteralPath $destPath
        if ($FileInfo) {
            return $infoFile
        }
        return $infoFile.FullName

        # Return the new FileInfo object
        return
    }

    if ($FileInfo) {
        return $tempFile
    }
    return $tempFile.FullName

    # No suffix provided—return the original temp file

}

function New-TempFilePs1 {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [Alias('x')]
        [switch]$FileInfo
    )
    $ret = New-TempFileExt 'ps1' -FileInfo:$FileInfo
    $ret
}


new-alias -Name newff -Value New-TempFileExt -Force -ErrorAction Ignore | Out-Null
new-alias -Name newps1 -Value New-TempFilePs1 -Force -ErrorAction Ignore | Out-Null
