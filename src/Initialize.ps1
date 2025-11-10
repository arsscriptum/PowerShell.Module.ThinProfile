#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Initialize.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
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
