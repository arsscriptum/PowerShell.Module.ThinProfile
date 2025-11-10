#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Encoder.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
<# works like this

   $inputPath = "C:\tmp\data\hiatus.jpg"
   $OutputPath = "C:\tmp\data\hiatus_copy.jpg"
   Invoke-FileToBinEncoded $InputPath

    # create a file 
    #
    # This variable represent the file  that was compressed and encoded.
    # Conversion  bytes =>  raw bytes => 34644 bytes base64
    # You can extract the byet array data of the original file using "Expand-Base64EncodedToBytes" or "Invoke-BinEncodedToFile"
    #
    $hiatus = "H4sIAAAAAAAACuy7d1...

     ".\hiatusVarDecl.ps1"
     Invoke-BinEncodedToFile $OutputPath $hiatus
 #>


 

function Invoke-FileToBinEncoded {

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
    $InputFileSize = (Get-Item $InputPath).Length
    $OutputFilename = "{0}VarDecl.ps1" -f $FileBaseName
    $DefaultOutFile = Join-Path "$($PWD.Path)" "$OutputFilename"

    if([System.IO.File]::Exists($DefaultOutFile)){
        if($Force){
            Write-Warning "File $DefaultOutFile already exists! Deleting..."
            Remove-Item -Path "$DefaultOutFile" -Force -ErrorAction Ignore | Out-Null
        }else{
            Write-Warning "File $DefaultOutFile already exists! Use -Force to overwrite"
            return
        }
    }

    [Byte[]]$RawBytes = Get-Content -Path $InputPath -Raw -AsByteStream
    [Int32]$RawBytesCount = $RawBytes.Count
    Write-Verbose "Extracting data from $InputPath ($InputFileSize bytes) => $RawBytesCount bytes"



    [System.IO.MemoryStream]$MemoryStream = [System.IO.MemoryStream]::new()
    [System.IO.Compression.GzipStream]$GzipStream = [System.IO.Compression.GzipStream]::new($MemoryStream, ([System.IO.Compression.CompressionMode]::Compress))
    $GzipStream.Write($RawBytes, 0, $RawBytesCount)
    $GzipStream.Close()
    $MemoryStream.Close()
    Write-Verbose "Compressing byte array data...."
    $GzippedBytes = $MemoryStream.ToArray()
    $GzippedBytesCount = $GzippedBytes.Count
    Write-Verbose "Compression completed => $GzippedBytesCount bytes"
    Write-Verbose "Encoding data to base64..."
    $Base64Content = [System.Convert]::ToBase64String($GzippedBytes)
    $Base64ContentSize = $Base64Content.Length
    Write-Verbose "Encoding completed => $Base64ContentSize bytes"
    $StringDecl = @"
#
# This variable represent the file $Path that was compressed and encoded. 
# Conversion {0} bytes => {1} raw bytes => {2} bytes base64
# You can extract the byet array data of the original file using "Expand-Base64EncodedToBytes" or "Invoke-BinEncodedToFile"
#
`${3} = `"{4}`" `n`n
"@ -f $InputPathLen, $MemoryByteArrayCompressedSize, $Base64ContentSize, $FileBaseName, $Base64Content


    Set-Content -Path "$DefaultOutFile" -Value "`n`n$StringDecl`n" -Force
}

function Expand-Base64EncodedToBytes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(position = 0, Mandatory = $true)]
        [string]$Base64Data
    )
   # Base64 to Byte array of compressed data
    [byte[]]$RawDataCompressed = [System.Convert]::FromBase64String($Base64Data)
    $Base64DataLen = $Base64Data.Lenght
    $RawDataCompressedCount = $RawDataCompressed.Count
    # Decompress data
   
    [System.IO.MemoryStream]$InputStream = [System.IO.MemoryStream]::new($RawDataCompressed)
    [System.IO.MemoryStream]$MemoryStream = [System.IO.MemoryStream]::new()
    [System.IO.Compression.GzipStream]$GzipStream = [System.IO.Compression.GzipStream]::new( $InputStream, ([System.IO.Compression.CompressionMode]::Decompress) )
    $GzipStream.CopyTo($MemoryStream)
    $GzipStream.Close()
    $MemoryStream.Close()
    $MemoryStream.Length
    $InputStream.Close()
    [Byte[]]$RawBytes = $MemoryStream.ToArray()
    $RawBytesCount = $RawBytes.Count
    Write-Verbose "Decompression completed => $RawBytesCount bytes"
    # [System.Text.Encoding]::UTF8.GetString to get string.
    $RawBytes

}


function Invoke-BinEncodedToFile {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('o')]
        [string]$DestinationPath,
        [Parameter(position = 1, Mandatory = $true)]
        [string]$Base64Data,
        [Parameter(Mandatory = $false)]
        [Alias('f')]
        [switch]$Force
    )

    if([System.IO.File]::Exists($DestinationPath)){
        if($Force){
            Write-Warning "File $DestinationPath already exists! Deleting..."
            Remove-Item -Path "$DestinationPath" -Force -ErrorAction Ignore | Out-Null
        }else{
            Write-Warning "File $DestinationPath already exists! Use -Force to overwrite"
            return
        }
    }
    [byte[]]$bytes = Expand-Base64EncodedToBytes $Base64Data

    [System.IO.File]::WriteAllBytes("$DestinationPath", $bytes)
}
