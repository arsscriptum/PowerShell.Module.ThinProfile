#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Show-SydneyMsgBox.ps1                                                        ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

# ------------------------------------
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]
        $ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

    # Then decompress script's data
    $InputStream = New-Object System.IO.MemoryStream (, $ScriptBlockCompressed)
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $StreamReader = New-Object System.IO.StreamReader ($GzipStream)
    $ScriptBlockDecompressed = $StreamReader.ReadToEnd()
    # And close the streams
    $GzipStream.Close()
    $InputStream.Close()

    $ScriptBlockDecompressed
}



function Show-MessageBoxVideoSydney {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )
    [string]$Url = "https://arsscriptum.github.io/files/sydney.mp4"
    $MediaPlayer = New-Object System.Windows.Controls.MediaElement
    $MediaPlayer.Height = "636"
    $MediaPlayer.Width = "480"
    $MediaPlayer.Source = $Url

    Show-MessageBox -Content $MediaPlayer -Title $Title -ContentBackground "Gray" -ContentTextForeground "Black" -TitleTextForeground "Black" -TitleBackground "Gray" -ButtonTextForeground "Red"


    $MediaPlayer.LoadedBehavior = "Manual"
    $MediaPlayer.Stop()
}




# ------------------------------------
# Loader
# ------------------------------------
function Show-Sydney {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # ------------------------------------
    # Script file - Assemblies - 
    # ------------------------------------
    $ScriptBlockAssemblies = "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"
    # ------------------------------------
    # Script file - MessageBox - 
    # ------------------------------------
    $ScriptBlockMessageBox = "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"



    $AssembliesFound = $False
    $AssemblyFolder = "$PSScriptRoot\assemblies"
    if (Test-Path "$AssemblyFolder" -PathType 'Container') {
        $Assembly = @(Get-ChildItem -Path "$AssemblyFolder\*.dll" -ErrorAction SilentlyContinue)
        $AssemblyCount = $Assembly.Count
        if ($AssemblyCount -gt 0) { $AssembliesFound = $True }
    }



    # For each scripts in the module, decompress and load it.
    # Set a flag in the Script Scope so that the scripts know we are loading a module
    # so he can have a specific logic
    $Script:LoadingState = $True
    $ScriptList = @('Assemblies', 'MessageBox')
    $ScriptList | ForEach-Object {
        $ScriptId = $_
        $ScriptBlock = "`$ScriptBlock$($ScriptId)" | Invoke-Expression
        $ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock $ScriptBlock
        try {
            $ClearScript | Invoke-Expression
        } catch {
            Write-Host "===============================" -f DarkGray
            Write-Host "$ClearScript" -f DarkGray
            Write-Host "===============================" -f DarkGray
            Write-Error "ERROR IN script $ScriptId . Details $_"
        }
    }
    $Script:LoadingState = $False

    Register-Assemblies -Force

    Show-BeAdvisedSydney -Text "We are about to show you Sydney Sweeney, Not Safe for Work"

    Show-MessageBoxVideoSydney

    Show-MessageBoxStandby
}
