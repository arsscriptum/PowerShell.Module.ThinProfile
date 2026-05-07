

function Invoke-TeamsCheckConnect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DoConnect
    )

    try {
        if ($DoConnect) {
            $ConnectionResults = Connect-MicrosoftTeams
            Register-appCredentials -Id "msteams_Account" -Username "$($ConnectionResults.Account)" -Password "$($ConnectionResults.Environment)"
            Register-appCredentials -Id "msteam_tenant_data" -Username "$($ConnectionResults.Tenant)" -Password "$($ConnectionResults.TenantId)"
        }

        $TenantsData = Get-appCredentials -Id "msteam_tenant_data"
        $Tenant = $TenantsData.UserName
        $TenantId = $TenantsData.GetNetworkCredential().Password

        $msteams_accntData = Get-appCredentials -Id "msteams_Account"
        $AccountStr = $msteams_accntData.UserName
        $EnvironmentStr = $msteams_accntData.GetNetworkCredential().Password


        Write-Host "Account      : $AccountStr" -f DarkCyan
        Write-Host "Environment  : $EnvironmentStr" -f DarkCyan
        Write-Host "Tenant       : $Tenant" -f DarkCyan
        Write-Host "TenantId     : $TenantId" -f DarkCyan

        [pscustomobject]$obj = [pscustomobject]@{
            Tenant = "$Tenant"
            TenantId = "$TenantId"
            Account = "$AccountStr"
            Environment = "$EnvironmentStr"

        }
        $obj

    } catch {
        Write-Error "$_"
    }
}



function Invoke-TeamTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DoConnect
    )

    try {


        $DataDir = "$env:ScriptsRoot\ms-teams\data"
        $Filename = "TeamsChat-{0}-ExportAPI-{1}.csv" -f "$($Colleague)", "$(Get-Date -Format 'yyyyMMdd-HHmm')"

        if (-not (Test-Path $DataDir)) {
            New-Item -Path "$DataDir" -ItemType Directory -Force -EA Ignore | Out-Null
        }
        $ConnectData = Invoke-TeamsCheckConnect -DoConnect:$DoConnect

        # --- INPUTS ---
        $TenantId = "$($ConnectData.TenantId)"
        $ClientId = "<app-id>"
        $ClientSecret = "<client-secret>" # Prefer a certificate in production
        $UserUpn = "you@yourtenant.com" # Whose messages to export (often your own)
        $Colleague = "colleague@yourtenant.com"
        $Start = [datetime]::UtcNow.AddYears(-1).ToString("o") # adjust window
        $End = [datetime]::UtcNow.ToString("o")
        $OutFile = Join-Path "$DataDir" "$Filename"

        # --- Connect app-only ---
        $secure = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret $secure

        # --- Resolve user + colleague ---
        $user = Get-MgUser -UserId $UserUpn
        $colleague = Get-MgUser -UserId $Colleague

        # --- (Optional) find the chatId for your 1:1 with the colleague ---
        $chats = Get-MgUserChat -UserId $user.Id -Filter "chatType eq 'oneOnOne'" -ExpandProperty "members" -All
        $targetChat = $chats | Where-Object {
            $memberIds = $_.Members | ForEach-Object { $_.AdditionalProperties.userId }
            $memberIds -contains $user.Id -and $memberIds -contains $colleague.Id
        }
        if (-not $targetChat) { throw "Could not find a 1:1 chat between $UserUpn and $Colleague." }

        # --- Call Export API: /users/{id}/chats/getAllMessages with date range ---
        $base = "https://graph.microsoft.com/v1.0/users/$($user.Id)/chats/getAllMessages"
        $uri = "$base`?$top=250&`$filter=lastModifiedDateTime gt $([uri]::EscapeDataString($Start)) and lastModifiedDateTime lt $([uri]::EscapeDataString($End))"

        $all = @()
        do {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
            $all += $resp.value
            $uri = $resp. '@odata.nextLink'
        } while ($uri)

        # --- Narrow to just that chat and export ---
        $rows = $all | Where-Object { $_.chatId -eq $targetChat.Id } | ForEach-Object {
            [pscustomobject]@{
                chatId = $_.chatId
                MessageId = $_.Id
                When = $_.createdDateTime
                FromDisplayName = $_.from.user.displayName
                FromUserId = $_.from.user.Id
                MessageType = $_.MessageType
                Importance = $_.Importance
                Subject = $_.Subject
                Text = ($_.body.content -replace '<br\s*/?>', "`n" -replace '<.*?>', '').Trim()
                HasAttachments = [bool]($_.attachments)
                Reactions = ($_.Reactions | ForEach-Object { $_.reactionType }) -join ';'
            }
        }
        $rows | Sort-Object When | Export-Csv -NoTypeInformation -Encoding UTF8 $OutFile
        Write-Host "Exported $(($rows|Measure-Object).Count) messages to `"$OutFile`""

    } catch {
        Write-Error "$_"
    }
}

