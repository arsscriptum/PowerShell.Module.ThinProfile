

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   PdfExporter.ps1                                                              |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Written by Guillaume Plante <guillaumeplante@eaton.com>                      |
#|                                                                                |
#|   Copyright © Eaton Corporation 2025. All rights reserved                      |
#|   This file and its contents are proprietary and confidential.                 |
#|   Unauthorized copying or distribution is prohibited.                          |
#+--------------------------------------------------------------------------------+


function Convert-TechNotePdfToMarkdownEnterprise {
<#
.SYNOPSIS
    Converts a technical PDF document into a Markdown file using Azure OpenAI
    while enforcing Microsoft Enterprise Data Protection (EDP).

.DESCRIPTION
    This function extracts text from a PDF document and submits the content
    exclusively to an Azure OpenAI deployment hosted in the caller's
    Azure tenant.  

    Enterprise Data Protection Enforcement:
    - ONLY Azure OpenAI endpoints (*.openai.azure.com) are allowed
    - Public OpenAI endpoints (api.openai.com) are explicitly blocked
    - Data is processed under Microsoft Product Terms and DPA
    - Prompts and responses are NOT used for model training
    - Tenant isolation and regional compliance are preserved

    If Enterprise Data Protection cannot be guaranteed, the function FAILS
    with a terminating error.

    This behavior is intentional and auditable.

.PARAMETER PdfPath
    Path to the source PDF technical note.

.PARAMETER OutputMarkdownPath
    Destination path for the generated Markdown file.

.PARAMETER AzureOpenAIEndpoint
    Azure OpenAI resource endpoint
    Example: https://myresource.openai.azure.com

.PARAMETER DeploymentName
    Azure OpenAI model deployment name (not a raw model name).

.PARAMETER ApiKey
    Azure OpenAI API key for the resource.

.PARAMETER ApiVersion
    Azure OpenAI API version. Defaults to a stable preview.

.PARAMETER TimeoutSeconds
    REST call timeout. Defaults to 120 seconds.

.PARAMETER MaxRetries
    Number of retries for transient failures. Defaults to 3.

.NOTES
    - Requires pdftotext (Poppler) available in PATH
    - Designed for enterprise, regulated, and auditable environments
    - Any attempt to bypass EDP constraints is treated as a configuration error
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path of the Pdf to convert")]
        [ValidateNotNullOrEmpty()]
        [string] $PdfPath,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Path for Output Markdown")]
        [ValidateNotNullOrEmpty()]
        [string] $OutputMarkdownPath,

        [Parameter(Mandatory)]
        [string] $AzureOpenAIEndpoint,

        [Parameter(Mandatory)]
        [string] $DeploymentName,

        [Parameter(Mandatory)]
        [string] $ApiKey,

        [string] $ApiVersion = "2024-02-15-preview",

        [int] $TimeoutSeconds = 120,

        [int] $MaxRetries = 3
    )

    Write-Verbose "Starting enterprise-protected PDF to Markdown conversion."

    # ---------------------------------------------------------------------
    # Enterprise Data Protection Enforcement
    # ---------------------------------------------------------------------

    if ($AzureOpenAIEndpoint -notmatch '^https://.*\.openai\.azure\.com$') {
        throw @"
ENTERPRISE DATA PROTECTION VIOLATION

The provided endpoint is NOT an Azure OpenAI endpoint:
    $AzureOpenAIEndpoint

This function explicitly forbids:
    - api.openai.com
    - Any non-Microsoft-hosted LLM endpoint

Execution aborted to prevent data exfiltration.
"@
    }

    Write-Verbose "Azure OpenAI endpoint validated for Enterprise Data Protection."

    # ---------------------------------------------------------------------
    # Input validation
    # ---------------------------------------------------------------------

    if (-not (Test-Path $PdfPath)) {
        throw "PDF file not found: $PdfPath"
    }

    $txtPath = [System.IO.Path]::ChangeExtension($PdfPath, ".txt")

    # ---------------------------------------------------------------------
    # PDF text extraction
    # ---------------------------------------------------------------------

    Write-Verbose "Extracting text from PDF using pdftotext."

    try {
        & pdftotext -layout $PdfPath $txtPath
    }
    catch {
        throw "Failed to extract text from PDF: $_"
    }

    if (-not (Test-Path $txtPath)) {
        throw "Text extraction failed; output file not created."
    }

    $pdfText = Get-Content $txtPath -Raw

    if ([string]::IsNullOrWhiteSpace($pdfText)) {
        throw "Extracted PDF content is empty."
    }

    # ---------------------------------------------------------------------
    # Prompt construction
    # ---------------------------------------------------------------------

    $prompt = @"
You are a technical documentation extraction system.

Rules:
- Extract factual technical content only
- Preserve logical structure
- Output GitHub-flavored Markdown
- Do NOT invent or infer missing data
- If information is incomplete, state it explicitly

SOURCE DOCUMENT:
$pdfText
"@

    $body = @{
        messages = @(
            @{ role = "system"; content = "Enterprise technical documentation processor." },
            @{ role = "user";   content = $prompt }
        )
        temperature = 0.1
    } | ConvertTo-Json -Depth 6

    $uri = "$AzureOpenAIEndpoint/openai/deployments/$DeploymentName/chat/completions?api-version=$ApiVersion"

    $headers = @{
        "api-key"      = $ApiKey
        "Content-Type" = "application/json"
    }

    # ---------------------------------------------------------------------
    # Azure OpenAI call with retries and timeout
    # ---------------------------------------------------------------------

    $attempt = 0
    $response = $null

    do {
        $attempt++
        Write-Verbose "Azure OpenAI call attempt $attempt / $MaxRetries"

        try {
            $response = Invoke-RestMethod `
                -Uri $uri `
                -Method Post `
                -Headers $headers `
                -Body $body `
                -TimeoutSec $TimeoutSeconds

            break
        }
        catch {
            Write-Warning "Attempt $attempt failed: $_"

            if ($attempt -ge $MaxRetries) {
                throw "Azure OpenAI call failed after $MaxRetries attempts."
            }

            Start-Sleep -Seconds (3 * $attempt)
        }

    } while ($attempt -lt $MaxRetries)

    if (-not $response.choices[0].message.content) {
        throw "Azure OpenAI response was empty or malformed."
    }

    # ---------------------------------------------------------------------
    # Output Markdown
    # ---------------------------------------------------------------------

    Write-Verbose "Writing Markdown output to $OutputMarkdownPath"

    Set-Content `
        -Path $OutputMarkdownPath `
        -Value $response.choices[0].message.content `
        -Encoding UTF8

    Write-Verbose "Conversion completed successfully under Enterprise Data Protection."
}



New-alias -Name pdf2md -Value Convert-TechNotePdfToMarkdownEnterprise -Force -ErrorAction Ignore -Scope GLobal -Option AllScope

function Convert-JsonToRdp {
<#
.SYNOPSIS
    Converts a JSON-based RDP connection profile into a valid .rdp file.

.DESCRIPTION
    This function reads a RDP connection profile expressed as JSON and
    generates a standard Remote Desktop (.rdp) file.

    It performs no credential handling.
    Authentication is expected to be managed separately via
    Windows Credential Manager (cmdkey).

.PARAMETER JsonProfilePath
    Path to the JSON profile file.

.PARAMETER OutputRdpPath
    Path where the .rdp file will be written.

.NOTES
    - JSON must only contain RDP configuration values
    - Ordering is preserved for readability (not required by RDP)
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $JsonProfilePath,

        [Parameter(Mandatory)]
        [string] $OutputRdpPath
    )

    if (-not (Test-Path $JsonProfilePath)) {
        throw "JSON profile not found: $JsonProfilePath"
    }

    $profile = Get-Content $JsonProfilePath -Raw | ConvertFrom-Json

    $lines = foreach ($prop in $profile.PSObject.Properties) {
        "$($prop.Name.Replace('_',' ')):$($prop.Value)"
    }

    Set-Content `
        -Path $OutputRdpPath `
        -Value $lines `
        -Encoding ASCII
}

function Connect-VMFromProfile {
<#
.SYNOPSIS
    Builds an RDP file from a JSON profile and connects using stored credentials.

.DESCRIPTION
    - Reads JSON RDP config from $ENV:VM_CONNECT_PROFILE
    - Generates a temporary .rdp file
    - Injects credentials from Get-AppCredentials
    - Launches mstsc with no prompt when permitted

    Credentials are stored securely using Credential Manager.
#>

    [CmdletBinding()]
    param ()

    $MsTscCmd = Get-Command -Name 'mstsc.exe' -CommandType Application -ErrorAction Ignore
    if (-not $MsTscCmd) {
        throw "mstsc.exe not in path!"
    }
    $MsTscExe = $MsTscCmd.Path

    $cmdkeyCmd = Get-Command -Name 'cmdkey.exe' -CommandType Application -ErrorAction Ignore
    if (-not $MsTscCmd) {
        throw "cmdkey.exe not in path!"
    }
    $cmdkeyExe = $cmdkeyCmd.Path

    if (-not $ENV:VM_CONNECT_PROFILE) {
        throw "ENV:VM_CONNECT_PROFILE is not set."
    }

    if (-not $ENV:VM_CREDENTIALS_ID) {
        throw "ENV:VM_CREDENTIALS_ID is not set."
    }

    $rdpPath = [System.IO.Path]::ChangeExtension(((New-TemporaryFile).Fullname),".rdp")

    Convert-JsonToRdp -JsonProfilePath "$ENV:VM_CONNECT_PROFILE" -OutputRdpPath "$rdpPath"

    $Creds = Get-AppCredentials "$ENV:VM_CREDENTIALS_ID"

    $VmHostname = (Get-Content "$rdpPath" | Where-Object { $_ -like "full address:*" }) -replace 'full address:s:', ''
    $opt0 = "/list:TERMSRV/{0}" -f $VmHostname
    $opt1 = "/generic:TERMSRV/{0}" -f $VmHostname
    $opt2 = "/user:{0}" -f $Creds.UserName
    $opt3 = "/pass:{0}" -f $Creds.GetNetworkCredential().Password
    [string[]]$Res = &"$cmdkeyExe" "$opt0"
    if($Res -match 'admin') {
        Write-Host "Credentials Already Stored for $opt1" -f DarkGreen
    } else {
        Write-Host "Registering Credentials for $opt1 ... " -f DarkYellow -n
        Write-Verbose "`"$cmdkeyExe`" `"$opt1`" `"$opt2`" `"$opt3`""
        &"$cmdkeyExe" "$opt1" "$opt2" "$opt3" | Out-Null
        [string[]]$Res = &"$cmdkeyExe" "$opt0"
        if($Res -match 'admin') { 
            Write-Host "OK" -f DarkGreen
        } else {
            Write-Host "Failed" -f DarkRed
        }
    }

    Start-Process -FilePath "$MsTscExe" -ArgumentList "`"$rdpPath`""
}
New-alias -Name vm -Value Connect-VMFromProfile -Force -ErrorAction Ignore -Scope GLobal -Option AllScope