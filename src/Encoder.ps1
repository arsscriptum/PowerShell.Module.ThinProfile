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

# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDVNnxKqrRdHXQV
# lKBuUsnKg1oY6g8CDopMIG9xsXq8h6CCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDr
# /WhT1fdvbjnqFryTbI9jS7Soj+gG+DBzFyxSG7qPUzANBgkqhkiG9w0BAQEFAASC
# AYANINku9I+40GDHeNwN7nPZM/Rbldch4MkRn5uVSHGy1R07BzF8Isb90U/kpEyz
# sQmB9ee/rHOkGwu10ww4oK17IvXCSZ89HLYDfn+K1i+QsUKAPB66zaTFH93WE+DG
# LYalxsQQosTHuAiOAqXw5f8nuypoauxdAaozcqs5ByqCC8Z9EzjT9jIqp969awER
# WG//IozVsomoiVPcwWiLKcMJtu7cuS/T9pgAujsl9BvMVWfGMhn9plC+B9p9MT0E
# Rf/h78vPvWu3HF4ABTdEgT3mAzGp7DZTeuTnkQlH613XaKEs7YwtgCfelAu+bJEU
# kX0lrKJGG/X+iE7g7eL1KmdQado6W86A9wwlKbzbCXOZuOvohRhNdnC7WidvF1yc
# 1+uFg8PcPkpItGIGPy6Je93cqYV4DOzWg2gJBx+TNpJIFvtWYPxKt5lmQlkQ03vL
# /lFcOXICT5Jm0SItUvnH4c1al8UDvI6GyZF9lGYunZsiXfxXyk1TsHo55o6wYdiV
# nH8=
# SIG # End signature block
