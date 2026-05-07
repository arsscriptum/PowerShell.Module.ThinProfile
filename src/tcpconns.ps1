function Convert-TimeSpanToString {
    param(
        [Parameter(Mandatory)]
        [TimeSpan] $TimeSpan
    )

    # Build parts dynamically
    $parts = @()

    if ($TimeSpan.Days -gt 0) {
        $parts += ("{0} day{1}" -f $TimeSpan.Days, $(if ($TimeSpan.Days -gt 1) { "s" } else { "" }))
    }

    if ($TimeSpan.Hours -gt 0) {
        $parts += ("{0} hr{1}" -f $TimeSpan.Hours, $(if ($TimeSpan.Hours -gt 1) { "s" } else { "" }))
    }

    if ($TimeSpan.Minutes -gt 0) {
        $parts += ("{0} min{1}" -f $TimeSpan.Minutes, $(if ($TimeSpan.Minutes -gt 1) { "s" } else { "" }))
    }

    if ($TimeSpan.Seconds -gt 0 -and $parts.Count -eq 0) {
        # Only show seconds if no larger units are present
        $parts += ("{0} second{1}" -f $TimeSpan.Seconds, $(if ($TimeSpan.Seconds -gt 1) { "s" } else { "" }))
    }

    if ($parts.Count -eq 0) {
        return "0 seconds"
    }

    return ($parts -join " ")
}

function Convert-Bytes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [uint64]$Bytes
    )
    process {
        try {
            [string]$res_str = ""
            if ($Bytes -gt 1TB) {
                $res_str = "{0:n2} TB" -f ($Bytes / 1TB)
            } elseif ($Bytes -gt 1GB) {
                $res_str = "{0:n2} GB" -f ($Bytes / 1GB)
            } elseif ($Bytes -gt 1MB) {
                $res_str = "{0:n2} MB" -f ($Bytes / 1MB)
            } elseif ($Bytes -gt 1KB) {
                $res_str = "{0:n2} KB" -f ($Bytes / 1KB)
            } else {
                $res_str = "{0:n2} Bytes" -f $Bytes
            }

            return $res_str
        } catch {
            Write-Error "$_"
        }
    }
}


function Show-ProcessConnections {
    param(
        [switch]$ResolveRemoteIp
    )

    # Ensure helper functions exist
    if (-not (Get-Command Convert-Bytes -ErrorAction SilentlyContinue)) {
        function Convert-Bytes {
            param([long]$Bytes)
            if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
            if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
            if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
            return "$Bytes B"
        }
    }

    if (-not (Get-Command Convert-TimeSpanToString -ErrorAction SilentlyContinue)) {
        function Convert-TimeSpanToString {
            param([TimeSpan]$TimeSpan)
            $parts = @()

            if ($TimeSpan.Days -gt 0)     { $parts += "$($TimeSpan.Days) day$((if ($TimeSpan.Days -eq 1) {''} else {'s'}))" }
            if ($TimeSpan.Hours -gt 0)    { $parts += "$($TimeSpan.Hours) hr$((if ($TimeSpan.Hours -eq 1) {''} else {'s'}))" }
            if ($TimeSpan.Minutes -gt 0)  { $parts += "$($TimeSpan.Minutes) min$((if ($TimeSpan.Minutes -eq 1) {''} else {'s'}))" }

            if ($parts.Count -eq 0 -and $TimeSpan.Seconds -gt 0) {
                $parts += "$($TimeSpan.Seconds) sec$((if ($TimeSpan.Seconds -eq 1) {''} else {'s'}))"
            }

            if ($parts.Count -eq 0) { return "0 seconds" }
            return ($parts -join " ")
        }
    }

    Write-Verbose "Gathering TCP connection list..."
    $ProcessListConnections = Get-NetTCPConnection | Group-Object -Property OwningProcess

    $results = @()

    foreach ($group in $ProcessListConnections) {
        $processId = $group.Name

        # Process object (may not exist)
        $pInfo = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $pInfo) { continue }

        $PsName      = $pInfo.ProcessName
        $PsCmdLine   = $pInfo.CommandLine
        $PsRunning   = (($pInfo.HasExited -eq $false) -and ($pInfo.Responding -eq $true))
        $CurMemStr   = Convert-Bytes $pInfo.WorkingSet64
        $MaxMemStr   = Convert-Bytes $pInfo.PeakWorkingSet64
        if($pInfo.StartTime){
            $Since       = (Get-Date) - $pInfo.StartTime
            $SinceStr    = Convert-TimeSpanToString $Since
        } else {
            $Since       = (Get-Date) - (Get-Date)
            $SinceStr    = Convert-TimeSpanToString $Since

        }
        
        foreach ($conn in $group.Group) {
            $remoteHost = $null

            if ($ResolveRemoteIp -and $conn.RemoteAddress -and $conn.RemoteAddress -ne "0.0.0.0") {
                try {
                    $remoteHost = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
                } catch { 
                    $remoteHost = "<unresolved>"
                }
            }

            $results += [PSCustomObject]@{
                PID         = $processId
                Name        = $PsName
                CurMem      = $CurMemStr
                MaxMem      = $MaxMemStr
                Since       = $SinceStr
                CmdLine     = $PsCmdLine
                State       = $conn.State
                LocalPort   = $conn.LocalPort
                RemoteIP    = $conn.RemoteAddress
                RemoteHost  = $remoteHost
            }
        }
    }

    # Show GUI table
    $results | Out-GridView -Title "Active Process Connections"
}

function Show-ProcessConnectionTree {
    param(
        [switch]$ResolveRemoteIp
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # ---- Helper: Convert bytes ----
    if (-not (Get-Command Convert-Bytes -ErrorAction SilentlyContinue)) {
        function Convert-Bytes {
            param([long]$Bytes)
            if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
            if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
            if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
            return "$Bytes B"
        }
    }

    # ---- Helper: Convert TimeSpan ----
    if (-not (Get-Command Convert-TimeSpanToString -ErrorAction SilentlyContinue)) {
        function Convert-TimeSpanToString {
            param([TimeSpan]$TimeSpan)
            $parts = @()

            if ($TimeSpan.Days -gt 0)    { $parts += "$($TimeSpan.Days) day$((if ($TimeSpan.Days -eq 1) {''} else {'s'}))" }
            if ($TimeSpan.Hours -gt 0)   { $parts += "$($TimeSpan.Hours) hr$((if ($TimeSpan.Hours -eq 1) {''} else {'s'}))" }
            if ($TimeSpan.Minutes -gt 0) { $parts += "$($TimeSpan.Minutes) min$((if ($TimeSpan.Minutes -eq 1) {''} else {'s'}))" }

            if ($parts.Count -eq 0 -and $TimeSpan.Seconds -gt 0) {
                $parts += "$($TimeSpan.Seconds) sec$((if ($TimeSpan.Seconds -eq 1) {''} else {'s'}))"
            }

            if ($parts.Count -eq 0) { return "0 seconds" }
            return ($parts -join " ")
        }
    }

    # ---- Gather TCP + UDP grouped by process ----
    $tcpGroups = Get-NetTCPConnection | Group-Object -Property OwningProcess
    $udpGroups = Get-NetUDPEndpoint  | Group-Object -Property OwningProcess

    # Master process ID list
    $allProcessIds = @(
        $tcpGroups.Name +
        $udpGroups.Name
    ) | Sort-Object -Unique

    # ---- Create Form ----
    $form              = New-Object System.Windows.Forms.Form
    $form.Text         = "Process Connections (TCP + UDP)"
    $form.Size         = New-Object System.Drawing.Size(1000,700)

    $tree              = New-Object System.Windows.Forms.TreeView
    $tree.Dock         = "Fill"
    $tree.Font         = "Consolas, 10"
    $tree.HotTracking  = $true

    $form.Controls.Add($tree)

    # ---- Populate Tree ----
    foreach ($processId in $allProcessIds) {

        $pInfo = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $pInfo) { continue }

        # Build process node label
        $curMem = Convert-Bytes $pInfo.WorkingSet64
        $maxMem = Convert-Bytes $pInfo.PeakWorkingSet64

        if ($pInfo.StartTime) {
            $since = Convert-TimeSpanToString ((Get-Date) - $pInfo.StartTime)
        } else {
            $since = "N/A"
        }

        $procNode = New-Object System.Windows.Forms.TreeNode
        $procNode.Text = "[{0}] {1}  | CurMem: {2} | MaxMem: {3} | Since: {4}" -f `
            $processId, $pInfo.ProcessName, $curMem, $maxMem, $since

        # ---- TCP Connections ----
        $tcp = $tcpGroups | Where-Object { $_.Name -eq $processId }
        if ($tcp) {

            $tcpHeader = New-Object System.Windows.Forms.TreeNode
            $tcpHeader.Text = "TCP Connections ({0})" -f $tcp.Group.Count
            $tcpHeader.ForeColor = [System.Drawing.Color]::Blue

            foreach ($conn in $tcp.Group) {

                $remoteHost = $null
                if ($ResolveRemoteIp -and $conn.RemoteAddress -ne "0.0.0.0") {
                    try {
                        $remoteHost = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
                    } catch { $remoteHost = "<unresolved>" }
                }

                $line = "TCP  {0}:{1}  ->  {2}:{3}  [{4}]  Host:{5}" -f `
                    $conn.LocalAddress, $conn.LocalPort, $conn.RemoteAddress, $conn.RemotePort, `
                    $conn.State, $remoteHost

                $tcpNode = New-Object System.Windows.Forms.TreeNode
                $tcpNode.Text = $line
                $tcpHeader.Nodes.Add($tcpNode)
            }

            $procNode.Nodes.Add($tcpHeader)
        }

        # ---- UDP Endpoints ----
        $udp = $udpGroups | Where-Object { $_.Name -eq $processId }
        if ($udp) {

            $udpHeader = New-Object System.Windows.Forms.TreeNode
            $udpHeader.Text = "UDP Endpoints ({0})" -f $udp.Group.Count
            $udpHeader.ForeColor = [System.Drawing.Color]::DarkGreen

            foreach ($u in $udp.Group) {

                $remoteHost = $null
                if ($ResolveRemoteIp -and $u.RemoteAddress -ne "0.0.0.0") {
                    try {
                        $remoteHost = [System.Net.Dns]::GetHostEntry($u.RemoteAddress).HostName
                    } catch { $remoteHost = "<unresolved>" }
                }

                $line = "UDP  {0}:{1}  ->  {2}  Host:{3}" -f `
                    $u.LocalAddress, $u.LocalPort, $u.RemoteAddress, $remoteHost

                $udpNode = New-Object System.Windows.Forms.TreeNode
                $udpNode.Text = $line
                $udpHeader.Nodes.Add($udpNode)
            }

            $procNode.Nodes.Add($udpHeader)
        }

        # add to tree
        $tree.Nodes.Add($procNode)
    }

    # ---- Show the Form ----
    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}

function Show-NetworkMonitorPanels {

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    #---------------------------------------------
    # Helper: Convert bytes
    #---------------------------------------------
    function Convert-Bytes($Bytes) {
        if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
        if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
        return "$Bytes B"
    }

    #---------------------------------------------
    # Helper: Convert timespan to readable string
    #---------------------------------------------
    function Convert-TimeSpanToString([TimeSpan]$TimeSpan) {
        $parts = @()

        if ($TimeSpan.Days -gt 0)    { $parts += "$($TimeSpan.Days)d" }
        if ($TimeSpan.Hours -gt 0)   { $parts += "$($TimeSpan.Hours)h" }
        if ($TimeSpan.Minutes -gt 0) { $parts += "$($TimeSpan.Minutes)m" }
        if ($parts.Count -eq 0)      { $parts += "$($TimeSpan.Seconds)s" }

        return ($parts -join " ")
    }

    #---------------------------------------------
    # Create the Form
    #---------------------------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Network Monitor (TCP + UDP)"
    $form.Size = New-Object System.Drawing.Size(1200, 900)
    $form.StartPosition = "CenterScreen"

    #---------------------------------------------
    # GLOBAL REFRESH CHECKBOX
    #---------------------------------------------
    $chkRefresh = New-Object System.Windows.Forms.CheckBox
    $chkRefresh.Text = "REFRESH"
    $chkRefresh.Location = "20, 10"
    $chkRefresh.AutoSize = $true
    $form.Controls.Add($chkRefresh)

    #---------------------------------------------
    # TCP SECTION CONTROLS
    #---------------------------------------------
    $chkTcpEnabled = New-Object System.Windows.Forms.CheckBox
    $chkTcpEnabled.Text = "LIST TCP CONNECTIONS"
    $chkTcpEnabled.Location = "20, 50"
    $chkTcpEnabled.AutoSize = $true

    $chkTcpResolve = New-Object System.Windows.Forms.CheckBox
    $chkTcpResolve.Text = "RESOLVE REMOTE HOST"
    $chkTcpResolve.Location = "20, 75"
    $chkTcpResolve.AutoSize = $true

    $lblTcpTotal = New-Object System.Windows.Forms.Label
    $lblTcpTotal.Text = "TOTAL TCP CONNS 0"
    $lblTcpTotal.Location = "900, 55"
    $lblTcpTotal.AutoSize = $true

    $lstTcp = New-Object System.Windows.Forms.ListBox
    $lstTcp.Location = "20, 110"
    $lstTcp.Size = "1140, 300"
    $lstTcp.Font = "Consolas, 10"

    $form.Controls.AddRange(@($chkTcpEnabled, $chkTcpResolve, $lblTcpTotal, $lstTcp))

    #---------------------------------------------
    # UDP SECTION CONTROLS
    #---------------------------------------------
    $chkUdpEnabled = New-Object System.Windows.Forms.CheckBox
    $chkUdpEnabled.Text = "LIST UDP CONNECTIONS"
    $chkUdpEnabled.Location = "20, 430"
    $chkUdpEnabled.AutoSize = $true

    $chkUdpResolve = New-Object System.Windows.Forms.CheckBox
    $chkUdpResolve.Text = "RESOLVE REMOTE HOST"
    $chkUdpResolve.Location = "20, 455"
    $chkUdpResolve.AutoSize = $true

    $lblUdpTotal = New-Object System.Windows.Forms.Label
    $lblUdpTotal.Text = "TOTAL UDP ENDP 0"
    $lblUdpTotal.Location = "900, 430"
    $lblUdpTotal.AutoSize = $true

    $lstUdp = New-Object System.Windows.Forms.ListBox
    $lstUdp.Location = "20, 490"
    $lstUdp.Size = "1140, 300"
    $lstUdp.Font = "Consolas, 10"

    $form.Controls.AddRange(@($chkUdpEnabled, $chkUdpResolve, $lblUdpTotal, $lstUdp))

    #---------------------------------------------
    # REFRESH TIMER (5 seconds)
    #---------------------------------------------
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 5000   # 5 seconds

    #---------------------------------------------
    # REFRESH LOGIC
    #---------------------------------------------
    $timer.Add_Tick({
        if (-not $chkRefresh.Checked) { return }

        #------------------ TCP ------------------
        if ($chkTcpEnabled.Checked) {

            $lstTcp.Items.Clear()

            $tcp = Get-NetTCPConnection
            $lblTcpTotal.Text = "TOTAL TCP CONNS $($tcp.Count)"

            foreach ($conn in $tcp) {

                $remoteHost = ""
                if ($chkTcpResolve.Checked -and $conn.RemoteAddress -ne "0.0.0.0") {
                    try {
                        $remoteHost = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
                    } catch { $remoteHost = "<unresolved>" }
                }

                $line = "{0,5}  {1,20}  {2}:{3}  ->  {4}:{5}  {6}  {7}" -f `
                    $conn.OwningProcess,
                    $conn.State,
                    $conn.LocalAddress,
                    $conn.LocalPort,
                    $conn.RemoteAddress,
                    $conn.RemotePort,
                    $remoteHost,
                    ""

                $lstTcp.Items.Add($line)
            }
        }

        #------------------ UDP ------------------
        if ($chkUdpEnabled.Checked) {

            $lstUdp.Items.Clear()

            $udp = Get-NetUDPEndpoint
            $lblUdpTotal.Text = "TOTAL UDP ENDP $($udp.Count)"

            foreach ($u in $udp) {

                $remoteHost = ""
                if ($chkUdpResolve.Checked -and $u.RemoteAddress -ne "0.0.0.0") {
                    try {
                        $remoteHost = [System.Net.Dns]::GetHostEntry($u.RemoteAddress).HostName
                    } catch { $remoteHost = "<unresolved>" }
                }

                $line = "{0,5}  UDP  {1}:{2}  ->  {3}  {4}" -f `
                    $u.OwningProcess,
                    $u.LocalAddress,
                    $u.LocalPort,
                    $u.RemoteAddress,
                    $remoteHost

                $lstUdp.Items.Add($line)
            }
        }
    })

    # Start timer
    $timer.Start()

    # Show form
    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}

function Show-NetworkMonitorTreePanels2 {

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # -------------------------------------------------------------
    # Helper: Convert bytes
    # -------------------------------------------------------------
    function Convert-Bytes($Bytes) {
        if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
        if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
        return "$Bytes B"
    }

    # -------------------------------------------------------------
    # Helper: Convert timespan to readable string
    # -------------------------------------------------------------
    function Convert-TimeSpanToString([TimeSpan]$TimeSpan) {
        $parts = @()
        if ($TimeSpan.Days -gt 0)    { $parts += "$($TimeSpan.Days)d" }
        if ($TimeSpan.Hours -gt 0)   { $parts += "$($TimeSpan.Hours)h" }
        if ($TimeSpan.Minutes -gt 0) { $parts += "$($TimeSpan.Minutes)m" }
        if ($parts.Count -eq 0)      { $parts += "$($TimeSpan.Seconds)s" }
        return ($parts -join " ")
    }

    # -------------------------------------------------------------
    # Create Form
    # -------------------------------------------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Network Monitor (TCP + UDP)"
    $form.Size = New-Object System.Drawing.Size(1400, 900)
    $form.StartPosition = "CenterScreen"

    # -------------------------------------------------------------
    # GLOBAL REFRESH CHECKBOX
    # -------------------------------------------------------------
    $chkRefresh = New-Object System.Windows.Forms.CheckBox
    $chkRefresh.Text = "REFRESH (5-sec auto)"
    $chkRefresh.Location = "20, 10"
    $chkRefresh.AutoSize = $true
    $form.Controls.Add($chkRefresh)

    # -------------------------------------------------------------
    # TCP TITLE BAR
    # -------------------------------------------------------------
    $lblTcpTitle = New-Object System.Windows.Forms.Label
    $lblTcpTitle.Text = "TCP CONNECTIONS"
    $lblTcpTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, "Bold")
    $lblTcpTitle.Location = "20, 40"
    $lblTcpTitle.AutoSize = $true

    $lblTcpTotal = New-Object System.Windows.Forms.Label
    $lblTcpTotal.Text = "TOTAL TCP CONNS 0"
    $lblTcpTotal.Location = "1200, 45"
    $lblTcpTotal.AutoSize = $true

    # TCP checkboxes
    $chkTcpEnabled = New-Object System.Windows.Forms.CheckBox
    $chkTcpEnabled.Text = "LIST TCP CONNECTIONS"
    $chkTcpEnabled.Location = "20, 75"
    $chkTcpEnabled.AutoSize = $true

    $chkTcpResolve = New-Object System.Windows.Forms.CheckBox
    $chkTcpResolve.Text = "RESOLVE REMOTE HOST"
    $chkTcpResolve.Location = "20, 100"
    $chkTcpResolve.AutoSize = $true

    # TCP TreeView
    $tvTcp = New-Object System.Windows.Forms.TreeView
    $tvTcp.Location = "20, 130"
    $tvTcp.Size = "1350, 300"
    $tvTcp.Font = "Consolas, 10"
    $tvTcp.HideSelection = $false

    $form.Controls.AddRange(@(
        $lblTcpTitle, $lblTcpTotal, $chkTcpEnabled, $chkTcpResolve, $tvTcp
    ))

    # -------------------------------------------------------------
    # UDP TITLE BAR
    # -------------------------------------------------------------
    $lblUdpTitle = New-Object System.Windows.Forms.Label
    $lblUdpTitle.Text = "UDP CONNECTIONS"
    $lblUdpTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, "Bold")
    $lblUdpTitle.Location = "20, 460"
    $lblUdpTitle.AutoSize = $true

    $lblUdpTotal = New-Object System.Windows.Forms.Label
    $lblUdpTotal.Text = "TOTAL UDP ENDP 0"
    $lblUdpTotal.Location = "1200, 465"
    $lblUdpTotal.AutoSize = $true

    $chkUdpEnabled = New-Object System.Windows.Forms.CheckBox
    $chkUdpEnabled.Text = "LIST UDP CONNECTIONS"
    $chkUdpEnabled.Location = "20, 495"
    $chkUdpEnabled.AutoSize = $true

    $chkUdpResolve = New-Object System.Windows.Forms.CheckBox
    $chkUdpResolve.Text = "RESOLVE REMOTE HOST"
    $chkUdpResolve.Location = "20, 520"
    $chkUdpResolve.AutoSize = $true

    # UDP tree
    $tvUdp = New-Object System.Windows.Forms.TreeView
    $tvUdp.Location = "20, 550"
    $tvUdp.Size = "1350, 300"
    $tvUdp.Font = "Consolas, 10"
    $tvUdp.HideSelection = $false

    $form.Controls.AddRange(@(
        $lblUdpTitle, $lblUdpTotal, $chkUdpEnabled, $chkUdpResolve, $tvUdp
    ))

    # -------------------------------------------------------------
    # REFRESH TIMER (5 seconds)
    # -------------------------------------------------------------
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 5000

    # -------------------------------------------------------------
    # REFRESH LOGIC
    # -------------------------------------------------------------
    $timer.Add_Tick({

        if (-not $chkRefresh.Checked) { return }

        # ------------------------- TCP --------------------------
        if ($chkTcpEnabled.Checked) {

            $tvTcp.Nodes.Clear()

            $tcpGroups = Get-NetTCPConnection | Group-Object -Property OwningProcess
            $lblTcpTotal.Text = "TOTAL TCP CONNS {0}" -f ($tcpGroups.Group | Measure-Object).Count

            foreach ($grp in $tcpGroups) {

                $pInfo = Get-Process -Id $grp.Name -ErrorAction SilentlyContinue
                if ($null -eq $pInfo) { continue }

                # Process info node
                $curMem = Convert-Bytes $pInfo.WorkingSet64
                $maxMem = Convert-Bytes $pInfo.PeakWorkingSet64
                $since  = if($pInfo.StartTime) { Convert-TimeSpanToString ((Get-Date) - $pInfo.StartTime) } else { "N/A" }

                $procNode = New-Object System.Windows.Forms.TreeNode
                $procNode.Text = "[{0}] {1} | Cur:{2} | Max:{3} | Since:{4}" -f `
                    $grp.Name, $pInfo.ProcessName, $curMem, $maxMem, $since

                # Add TCP children
                foreach ($tcp in $grp.Group) {

                    $remoteHost = ""
                    if ($chkTcpResolve.Checked -and $tcp.RemoteAddress -ne "0.0.0.0") {
                        try { 
                            $remoteHost = [System.Net.Dns]::GetHostEntry($tcp.RemoteAddress).HostName 
                        } catch { $remoteHost = "<unresolved>" }
                    }

                    $line = "TCP {0}:{1} → {2}:{3} [{4}] Host:{5}" -f `
                        $tcp.LocalAddress, $tcp.LocalPort, $tcp.RemoteAddress, $tcp.RemotePort, `
                        $tcp.State, $remoteHost

                    $child = New-Object System.Windows.Forms.TreeNode
                    $child.Text = $line
                    $procNode.Nodes.Add($child)
                }

                $tvTcp.Nodes.Add($procNode)
            }
        }

        # ------------------------- UDP --------------------------
        if ($chkUdpEnabled.Checked) {

            $tvUdp.Nodes.Clear()

            $udpGroups = Get-NetUDPEndpoint | Group-Object -Property OwningProcess
            $lblUdpTotal.Text = "TOTAL UDP ENDP {0}" -f ($udpGroups.Group | Measure-Object).Count

            foreach ($grp in $udpGroups) {

                $pInfo = Get-Process -Id $grp.Name -ErrorAction SilentlyContinue
                if ($null -eq $pInfo) { continue }

                $curMem = Convert-Bytes $pInfo.WorkingSet64
                $maxMem = Convert-Bytes $pInfo.PeakWorkingSet64
                $since  = if($pInfo.StartTime) { Convert-TimeSpanToString ((Get-Date) - $pInfo.StartTime) } else { "N/A" }

                $procNode = New-Object System.Windows.Forms.TreeNode
                $procNode.Text = "[{0}] {1} | Cur:{2} | Max:{3} | Since:{4}" -f `
                    $grp.Name, $pInfo.ProcessName, $curMem, $maxMem, $since

                foreach ($udp in $grp.Group) {

                    $remoteHost = ""
                    if ($chkUdpResolve.Checked -and $udp.RemoteAddress -ne "0.0.0.0") {
                        try { 
                            $remoteHost = [System.Net.Dns]::GetHostEntry($udp.RemoteAddress).HostName 
                        } catch { $remoteHost = "<unresolved>" }
                    }

                    $line = "UDP {0}:{1} → {2}  Host:{3}" -f `
                        $udp.LocalAddress, $udp.LocalPort, `
                        $udp.RemoteAddress, $remoteHost

                    $child = New-Object System.Windows.Forms.TreeNode
                    $child.Text = $line
                    $procNode.Nodes.Add($child)
                }

                $tvUdp.Nodes.Add($procNode)
            }
        }
    })

    # -------------------------------------------------------------
    # Start the timer
    # -------------------------------------------------------------
    $timer.Start()

    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}