#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   StartTerminal.ps1                                                            ║
#║   Launching Windows Terminal                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Start-WindowsTerminal {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("VsDos2019","VsDos2022", "PwshVs2019","PwshVs2022", "Ubuntu", "Core", "Legacy")]
        [string]$Mode = 'Core',
        [Parameter(Mandatory = $false)]
        [Alias("p","path","dir")]
        [string]$StartingDirectory,
        [Parameter(Mandatory = $false)]
        [Alias("a")]
        [switch]$Admin,
        [Parameter(Mandatory = $false)]
        [Alias("q")]
        [switch]$Quake,
        [Parameter(Mandatory = $false)]
        [Alias("m")]
        [switch]$Maximized,
        [Parameter(Mandatory = $false)]
        [ValidateSet("h","v")]
        [string]$Split,
        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [switch]$NewTab,
        [Parameter(Mandatory = $false)]
        [string]$Title

    )
    try{
        $ExeTerminal = Join-Path "$ENV:LOCALAPPDATA" "Microsoft\WindowsApps\wt.exe"
        $ExecName = (Get-Item -Path $ExeTerminal).Name
        if(!(test-path $ExeTerminal)){throw "no wt.exe found"}
        
        [string]$TermProfile = $Mode
        [System.Collections.Arraylist]$cmdargs=[System.Collections.Arraylist]::new()
        if( ($PSBoundParameters.ContainsKey('StartingDirectory')) -And (!([string]::IsNullOrEmpty($StartingDirectory))) -And (Test-Path -Path "$StartingDirectory")) {
            [void]$cmdargs.Add("-d")
            [void]$cmdargs.Add("$StartingDirectory")
        }
        if( ($PSBoundParameters.ContainsKey('Title')) -And (!([string]::IsNullOrEmpty($Title)))) {
            [void]$cmdargs.Add("split-pane")
            [void]$cmdargs.Add("--title")
            [void]$cmdargs.Add("$Title")
        }
        if($Quake){
            [void]$cmdargs.Add("-w")
            [void]$cmdargs.Add("_quake")
        }
        if($Maximized){
            [void]$cmdargs.Add("-M")
        }
        [void]$cmdargs.Add("-p")
        [void]$cmdargs.Add("$TermProfile")
        if($NewTab){
            [void]$cmdargs.Add(";new-tab")
        }
        if ($PSBoundParameters.ContainsKey('Split')) {
            [void]$cmdargs.Add(";split-pane")
            $opt = "-{0}" -f $Split.ToUpper()
            [void]$cmdargs.Add("$opt")
        }


        [string]$ArgsString = ""
        $cmdargs | % { $ArgsString += "$_ " }

        Write-Verbose "Arguments => $ArgsString"
        $process = $null
        if ($Admin) {
            Write-Verbose "Start-Process -FilePath $ExeTerminal -ArgumentList ` -Passthru -Verb RunAs"
            $process = Start-Process -FilePath $ExeTerminal -ArgumentList $cmdargs -Passthru -Verb RunAs
        } else {
            Write-Verbose "Start-Process -FilePath $ExeTerminal -ArgumentList ` -Passthru"
            $process = Start-Process -FilePath $ExeTerminal -ArgumentList $cmdargs -Passthru 
        }
    } catch {
        Write-Error " Caught an Exception Error: $_"
    }
}
