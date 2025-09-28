
#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   encoder.ps1                                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Invoke-FileToBase64DeclaredVariable {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
                if (-not ($_ | Test-Path)) {
                    throw "File or folder does not exist"
                }
                if (-not ($_ | Test-Path -PathType Leaf)) {
                    throw "The Path argument must be a file. Directory paths are not allowed."
                }
                return $true
            })]
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('i')]
        [string]$InputPath,
        [Parameter(Mandatory = $false)]
        [Alias('f')]
        [switch]$Force
    )

    $FileBaseName = (Get-Item $InputPath).BaseName
    $InputPathLen = (Get-Item $InputPath).Length
    $OutputFilename = "{0}VarDecl.ps1" -f $FileBaseName
    $DefaultOutFile = Join-Path "$($PWD.Path)" "$OutputFilename"

    $Content = Get-Content -Path $InputPath -Raw
    [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    Write-Verbose "Extracting bytes from $InputPath"
    [Byte[]]$ScriptBlockEncoded = $Encoding.GetBytes($InputPath)


    [System.IO.MemoryStream]$MemoryStream = [System.IO.MemoryStream]::new()
    [System.IO.Compression.GzipStream]$GzipStream = [System.IO.Compression.GzipStream]::new($MemoryStream, ([System.IO.Compression.CompressionMode]::Compress))
    $GzipStream.Write($ScriptBlockEncoded, 0, $ScriptBlockEncoded.Length)
    $GzipStream.Close()
    $MemoryStream.Close()
    Write-Verbose "Compressing byte array data...."
    $MemoryByteArrayCompressed = $MemoryStream.ToArray()
    $MemoryByteArrayCompressedSize = $MemoryByteArrayCompressed.Count
    Write-Verbose "Encoding data too base64..."
    $Base64Content = [System.Convert]::ToBase64String($MemoryByteArrayCompressed)
    $Base64ContentSize = $Base64Content.Count
    $StringDecl = @"
#
# This variable represent the file $Path that was compressed and encoded. 
# Conversion {0} bytes => {1} raw bytes => {2} bytes base64
# You can extract the byet array data of the original file using "Expand-CompressedBase64Encoded"
#
`${3} = `"{4}`" `n`n
"@ -f $InputPathLen, $MemoryByteArrayCompressedSize, $Base64ContentSize, $FileBaseName, $Base64Content


    Set-Content -Path "$DefaultOutFile" -Value "`n`n$StringDecl`n" -Force

}


