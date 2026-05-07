


function Install-AdminVoicesDism {
    dism /Online /Add-Capability /CapabilityName:Language.Basic~~~fr-FR~0.0.1.0
    dism /Online /Add-Capability /CapabilityName:Language.TextToSpeech~~~fr-FR~0.0.1.0
    dism /Online /Add-Capability /CapabilityName:Language.Speech~~~fr-FR~0.0.1.0
   
    dism /Online /Add-Capability /CapabilityName:Language.Handwriting~~~fr-FR~0.0.1.0

    rem Pour fr-CA :
    dism /Online /Add-Capability /CapabilityName:Language.Basic~~~fr-CA~0.0.1.0
    dism /Online /Add-Capability /CapabilityName:Language.TextToSpeech~~~fr-CA~0.0.1.0
    dism /Online /Add-Capability /CapabilityName:Language.Speech~~~fr-CA~0.0.1.0
}

function Install-AdminVoices {
    <#
.SYNOPSIS
Installe les composants de langue/français (fr-FR, fr-CA) : Basic, TextToSpeech (TTS), Speech, Handwriting.
Utilise Add-WindowsCapability (recommandé) et bascule sur DISM.exe si nécessaire.
Nécessite : PowerShell admin, Windows 10/11.

.EXAMPLES
.\Install-VoixFR.ps1                       # Installe fr-FR + fr-CA depuis Windows Update
.\Install-VoixFR.ps1 -Cultures fr-FR       # Uniquement fr-FR
.\Install-VoixFR.ps1 -Source "D:\sources\sxs"  # Installation hors-ligne
#>

    [CmdletBinding()]
    param(
        # Cultures à installer
        [string[]]$Cultures = @('fr-FR', 'fr-CA'),

        # Source hors-ligne (dossier SxS / ISO monté). Laisser vide pour Windows Update.
        [string]$Source = $null,

        # Inclure l’écriture manuscrite (facultatif)
        [switch]$IncludeHandwriting
    )

    function Test-Admin {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal ($current)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "Ce script doit être exécuté en tant qu’Administrateur."
        }
    }

    function Install-Capability {
        param(
            [Parameter(Mandatory)] [string]$Name,
            [string]$Source
        )

        Write-Host "→ Installation: $Name" -ForegroundColor Cyan

        try {
            $params = @{
                Online = $true
                Name = $Name
                ErrorAction = 'Stop'
            }
            if ($Source) { $params['Source'] = $Source }
            $result = Add-WindowsCapability @params
            if ($result -and $result.State -in 'Installed', 'InstallPending') {
                Write-Host "   OK ($($result.State))"
                return $true
            } else {
                Write-Warning "   Add-WindowsCapability a renvoyé: $($result.State)"
            }
        } catch {
            Write-Warning "   Add-WindowsCapability a échoué: $($_.Exception.Message)"
        }

        # Fallback DISM
        $dismArgs = "/Online /Add-Capability /CapabilityName:$Name"
        if ($Source) { $dismArgs += " /Source:`"$Source`"" }
        $dismArgs += " /NoRestart"
        Write-Host "   → Fallback DISM.exe $dismArgs"
        $p = Start-Process -FilePath dism.exe -ArgumentList $dismArgs -Wait -NoNewWindow -Passthru
        if ($p.ExitCode -eq 0) {
            Write-Host "   OK (DISM)"
            return $true
        } else {
            Write-Error "   Échec DISM (code $($p.ExitCode))"
            return $false
        }
    }

    function Get-CapName {
        param(
            [Parameter(Mandatory)] [string]$Culture,
            [Parameter(Mandatory)][ValidateSet('Basic', 'TTS', 'Speech', 'Handwriting')] $Type
        )
        switch ($Type) {
            'Basic' { "Language.Basic~~~$Culture~0.0.1.0" }
            'TTS' { "Language.TextToSpeech~~~$Culture~0.0.1.0" }
            'Speech' { "Language.Speech~~~$Culture~0.0.1.0" }
            'Handwriting' { "Language.Handwriting~~~$Culture~0.0.1.0" }
        }
    }

    function Test-Installed {
        param([string]$CapabilityName)
        $cap = Get-WindowsCapability -Online | Where-Object { $_.Name -eq $CapabilityName }
        return ($cap -and $cap.State -eq 'Installed')
    }

    try {
        Test-Admin
        Write-Host "=== Installation des voix FR via Windows Capabilities ===" -ForegroundColor Green
        if ($Source) { Write-Host "Source hors-ligne: $Source" -ForegroundColor Yellow }

        foreach ($culture in $Cultures) {
            Write-Host "`n--- Culture: $culture ---" -ForegroundColor Magenta

            # Ordre recommandé : Basic → TTS → Speech → (Optionnel) Handwriting
            $queue = @(
                Get-CapName -Culture $culture -Type Basic
                Get-CapName -Culture $culture -Type TTS
                Get-CapName -Culture $culture -Type Speech
            )
            if ($IncludeHandwriting) {
                $queue += Get-CapName -Culture $culture -Type Handwriting
            }

            foreach ($capName in $queue) {
                if (Test-Installed $capName) {
                    Write-Host "Déjà installé: $capName"
                } else {
                    Install-Capability -Name $capName -Source $Source | Out-Null
                }
            }
        }

        Write-Host "`n=== Vérification côté .NET (System.Speech) ===" -ForegroundColor Green
        Add-Type -AssemblyName System.Speech
        $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $voices = $s.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo } |
        Where-Object { $_.Culture.Name -like "fr*" } |
        Select-Object Name, Culture
        if ($voices) {
            $voices | Format-Table -Auto
            Write-Host "`nTest audio (fr* détecté)..." -ForegroundColor Cyan
            $s.SelectVoice(($voices | Select-Object -First 1).Name)
            $s.Speak("Bonjour. La voix française a été installée avec succès.")
        } else {
            Write-Warning "Aucune voix .NET FR détectée. Redémarre Windows puis relance le test."
        }
        $s.Dispose()
    }
    catch {
        Write-Error $_.Exception.Message
    }

    function Install-Voices {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $synth.GetInstalledVoices() |
        ForEach-Object {
            [pscustomobject]@{
                Nom = $_.VoiceInfo.Name
                Culture = $_.VoiceInfo.Culture
                Genre = $_.VoiceInfo.Gender
                Âge = $_.VoiceInfo.Age
                Défault = $_.Enabled
            }
        } | Sort-Object Culture, Nom
        $synth.Dispose()
    }
    function Get-Voix {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $synth.GetInstalledVoices() |
        ForEach-Object {
            [pscustomobject]@{
                Nom = $_.VoiceInfo.Name
                Culture = $_.VoiceInfo.Culture
                Genre = $_.VoiceInfo.Gender
                Âge = $_.VoiceInfo.Age
                Défault = $_.Enabled
            }
        } | Sort-Object Culture, Nom
        $synth.Dispose()
    }
}

function Say-Fr {
    [CmdletBinding()]
    param(
        # Le texte à prononcer (obligatoire)
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Texte,

        # Nom (ou fragment du nom) de la voix à utiliser, ex.: "fr-FR" ou "Hortense"
        [string]$Voix = "fr",

        # Vitesse de parole (-10 = très lent, 0 = normal, 10 = très rapide)
        [ValidateRange(-10, 10)]
        [int]$Vitesse = 0,

        # Volume (0..100)
        [ValidateRange(0, 100)]
        [int]$Volume = 100
    )

    begin {
        # Charge l’assembly .NET de synthèse vocale
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $script:synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

        # Sélection de la voix (recherche par nom OU culture)
        $toutesVoix = $synth.GetInstalledVoices() |
        ForEach-Object { $_.VoiceInfo }

        # Essaye d’abord une voix dont la culture est FR (fr-FR, fr-CA, …)
        $voixChoisie =
        $toutesVoix | Where-Object { $_.Culture.Name -like "fr*" } |
        Where-Object { $_.Name -match [regex]::Escape($Voix) } |
        Select-Object -First 1

        if (-not $voixChoisie) {
            # Sinon, accepte tout ce qui contient $Voix (nom de voix)
            $voixChoisie =
            $toutesVoix | Where-Object { $_.Name -match $Voix } |
            Select-Object -First 1
        }

        if (-not $voixChoisie) {
            throw "Aucune voix française trouvée. Exécutez Get-Voix pour lister les voix installées ou installez une voix FR dans les paramètres Windows."
        }

        $synth.SelectVoice($voixChoisie.Name)
        $synth.Rate = $Vitesse
        $synth.Volume = $Volume
    }

    process {
        $synth.Speak($Texte)
    }

    end {
        $synth.Dispose()
    }
}
