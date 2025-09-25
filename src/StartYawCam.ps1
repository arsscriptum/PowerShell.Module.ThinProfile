#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   StartYawCam.ps1                                                              ║
#║   start yawcam process                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Start-YawcamJavaProcess {
    [CmdletBinding()]
    param()

    [string]$JavaExePath = "C:\Program Files (x86)\Common Files\Oracle\Java\javapath\javaw.exe"
    [string]$WorkingDirectory = "C:\Programs\Yawcam"
    [System.Collections.ArrayList]$classPaths = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$cmdArgs = [System.Collections.ArrayList]::new()
    [void]$classPaths.Add(".")
    [void]$classPaths.Add("lib/activation.jar")
    [void]$classPaths.Add("lib/commons-jxpath-1.1.jar")
    [void]$classPaths.Add("lib/commons-logging.jar")
    [void]$classPaths.Add("lib/commons-logging-api.jar")
    [void]$classPaths.Add("lib/dsj.jar")
    [void]$classPaths.Add("lib/monte-cc.jar")
    [void]$classPaths.Add("lib/mail.jar")
    [void]$classPaths.Add("lib/mx4j-impl.jar")
    [void]$classPaths.Add("lib/mx4j-jmx.jar")
    [void]$classPaths.Add("lib/mx4j-remote.jar")
    [void]$classPaths.Add("lib/mx4j-tools.jar")
    [void]$classPaths.Add("lib/sbbi-jmx-1.0.jar")
    [void]$classPaths.Add("lib/sbbi-upnplib-1.0.4.jar")
    [void]$classPaths.Add("lib/ftp4j.jar")
    [void]$classPaths.Add("lib/commons-codec-1.4.jar")
    [void]$classPaths.Add("lib/turbojpeg.jar")
    [void]$classPaths.Add("lib/system-event.jar")
    $classpathStrArgs = $classPaths -join ";"

    [void]$cmdArgs.Add("-cp")
    [void]$cmdArgs.Add("$classpathStrArgs")
    [void]$cmdArgs.Add("-Djava.net.preferIPv4Stack=true")
    [void]$cmdArgs.Add("-splash:img/splash.gif")
    [void]$cmdArgs.Add("yawcam.Main")
    $argumentsStr = $cmdArgs -join " "
     #Write-HOst "$JavaExePath $argumentsStr" -f Magenta
    $ProgramArgsSet = @{
        FilePath = $JavaExePath
        ArgumentList = $cmdArgs
        PassThru = $False
        Wait = $False
        WindowStyle = 'Hidden'
        WorkingDirectory = $WorkingDirectory
    }
    Start-Process @ProgramArgsSet

}
