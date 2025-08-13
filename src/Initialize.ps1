#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   initialize.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Uninitialize-ThinProfileModule {
    [CmdletBinding(SupportsShouldProcess)]
    param()
} 


function Initialize-ThinProfileModule {
    [CmdletBinding(SupportsShouldProcess)]
    param() 

    
}

function AutoInitialize-ThinProfileModule {
    [CmdletBinding(SupportsShouldProcess)]
    param() 

    New-ThinProfileModuleVersionFile -AutoUpdateFlag $True -Force
}
