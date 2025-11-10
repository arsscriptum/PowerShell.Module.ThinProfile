#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ScheduledTaskDetails.ps1                                                  ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Written by Guillaume Plante <guillaumeplante@eaton.com>                      ║
#║                                                                                ║
#║   Copyright (C) 2025 Eaton Corporation. All rights reserved                    ║
#║   This file and its contents are proprietary and confidential.                 ║
#║   Unauthorized copying or distribution is prohibited.                          ║
#╚════════════════════════════════════════════════════════════════════════════════╝
function Get-ScheduledTaskRunHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $logName = 'Microsoft-Windows-TaskScheduler/Operational'

    # Make sure logging is enabled
    if (-not (Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue).IsEnabled) {
        Write-Warning "Task Scheduler log is not enabled: $logName"
        return
    }

    # Query for Task Start (Event ID 100) and Task Completed (Event ID 102)
    $events = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=100 or EventID=102]]" -ErrorAction SilentlyContinue |
        Where-Object { $_.Properties[0].Value -like "*$TaskName*" } |
        Sort-Object TimeCreated

    $history = @()
    $currentRun = $null

    foreach ($event in $events) {
        $eventID = $event.Id
        $taskNameInEvent = $event.Properties[0].Value
        $timestamp = $event.TimeCreated

        switch ($eventID) {
            100 {
                $currentRun = [PSCustomObject]@{
                    TaskName     = $taskNameInEvent
                    StartTime    = $timestamp
                    EndTime      = $null
                    ResultCode   = $null
                }
            }
            102 {
                if ($currentRun -ne $null -and $currentRun.TaskName -eq $taskNameInEvent) {
                    $currentRun.EndTime    = $timestamp
                    $currentRun.ResultCode = $event.Properties[1].Value
                    $history += $currentRun
                    $currentRun = $null
                }
            }
        }
    }

    return $history
}



function Set-EventChannelEnable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$Channel="Microsoft-Windows-TaskScheduler/Operational",
        [Parameter(Mandatory = $false)]
        [bool]$Enable = $True
    )
    $wevtutilexe = (get-command -Name "wevtutil.exe" -CommandType Application).Source
    $SetValue = if($Enable){"/enabled:true"}else{"/enabled:false"}

    Write-Host "Setting Value for $val -> $Value --> " -f DarkBlue -n
    $cmdres = Start-Process -FilePath "$wevtutilexe" -ArgumentList "set-log","$Channel","$SetValue","/maxSize:41943040" -NoNewWindow -Wait -Passthru
    $ecode = $cmdres.ExitCode
    $pcpu = $cmdres.CPU -as [string]
    if ($ecode -eq 0) {
        Write-Host "SUCCESS after $pcpu" -f DarkGreen
    } else {
            Write-Host "FAILED. Returned `"$errmsg`"" -f DarkRed
    }
    
}

function Remove-SchedTaskProperties {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName
    )

    process {
        $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks\TasksProperties\{0}" -f $TaskName
        $registryPathTypes = "$registryPath\Types"

        if (Test-Path $registryPathTypes) {
            Write-Verbose "[Remove-SchedTaskProperties] Remove Registry Properties $TaskName, [$registryPathTypes]"
            Remove-Item -Path $registryPathTypes -Recurse -Force | Out-Null
        }
        # Ensure the registry path exists
        if (Test-Path $registryPath) {
            Write-Verbose "[Remove-SchedTaskProperties] Remove Registry Properties $TaskName, [$registryPath]"
            Remove-Item -Path $registryPath -Recurse -Force | Out-Null
        }
    }

}

function Write-SchedTaskProperties {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Properties of the scheduled task")]
        [pscustomobject]$TaskProperties
    )

    $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks\TasksProperties\{0}" -f $TaskName
    $registryPathTypes = "$registryPath\Types"

    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    if (-not (Test-Path $registryPathTypes)) {
        New-Item -Path $registryPathTypes -Force | Out-Null
    }

    foreach ($prop in $TaskProperties.PSObject.Properties) {
        $VariableName = "$($prop.Name)"
        $value = $prop.Value
        $type = $value.GetType()
        $VariableValue = ($prop.Value -as $prop.TypeNameOfValue)
        $VariableType = ($prop.Value).GetType()
        $VariableTypeFull = $VariableType.FullName
        $RegValueType = 'String' # Default

        Write-Verbose "$VariableName is a [$($VariableType.Name)] ($VariableTypeFull)"

        $DefaultType = $False

        if (($VariableType -eq [uint32]) -or ($VariableType -eq [int32])) {
            $RegValueType = 'DWord'
        } elseif (($VariableType -eq [bool]) -or ($VariableType -eq [Boolean])) {
            $RegValueType = 'Binary'
        } elseif (($VariableType -eq [decimal]) -or ($VariableType -eq [int64]) -or ($VariableType -eq [uint64])) {
            $RegValueType = 'QWord'
        } elseif ($VariableType -eq [string[]]) {
            $RegValueType = 'MultiString'
        } elseif ($VariableType -eq [string]) {
            $RegValueType = if ($VariableValue -match '[$%]') { 'ExpandString' } else { 'String' }
        } else {
            $DefaultType = $True
            $RegValueType = 'String'
        }

        if ($DefaultType) {
            Write-Verbose "cannot identify $VariableName registry type. default to string"
        } else {
            Write-Verbose "identified $VariableName registry type to $RegValueType"
        }
        Write-Verbose "Property `"$VariableName`" has value $VariableValue as [$VariableType] ($VariableTypeFull). Saved as $RegValueType"
        # Write to registry
        try {
            # registry value type -> $Kind
            #  "String", "ExpandString", "Binary", "DWord", "MultiString", "QWord"
            Write-Verbose "[Write-SchedTaskProperties] New-ItemProperty -Path $registryPath -Name $VariableName -Value $VariableValue -PropertyType $RegValueType"

            New-ItemProperty -Path $registryPath -Name $VariableName -Value $VariableValue -PropertyType $RegValueType -Force | Out-null
            New-ItemProperty -Path $registryPathTypes -Name "$VariableName" -Value "$VariableTypeFull" -PropertyType 'String' -Force | Out-null
        } catch {
            Write-Warning "Failed to register '$property_name': $_"
        }
    }
}


function Read-SchedTaskProperties {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName
    )

    process {


        $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks\TasksProperties\{0}" -f $TaskName
        $registryPathTypes = "$registryPath\Types"

        if (-not (Test-Path $registryPath)) {
            throw "Task registry path '$registryPath' does not exist."
        }

        $TaskProperties = [pscustomobject]@{}
        $Key = Get-Item -Path $registryPath -ErrorAction Stop
        $Properties = $Key.Property

        foreach ($property_name in $Properties) {
            try {
                # Read raw string type from Types subkey
                $typeString = (Get-ItemProperty -Path $registryPathTypes -Name $property_name).$property_name
                $property_value = (Get-ItemProperty -Path $registryPath -Name $property_name).$property_name

                # Convert type string to actual [type]
                $resolvedType = [type]::GetType($typeString, $false)

                if ($null -eq $resolvedType) {
                    Write-Warning "Could not resolve type '$typeString' for property '$property_name'. Defaulting to string."
                    $resolvedType = [string]
                }

                # Try casting the value to the original type
                if (($resolvedType -eq [bool]) -or ($resolvedType -eq [Boolean])) {
                    $converted_boolean = if ($property_value -eq '0') { $False } else { $True }
                    $convertedValue = [bool]::Parse($converted_boolean)
                }
                elseif ($resolvedType.IsEnum) {
                    $convertedValue = [Enum]::Parse($resolvedType, $property_value)
                }
                elseif ($resolvedType -eq [string[]] -and ($property_value -is [string])) {
                    $convertedValue =, $property_value # Ensure it's an array
                }
                else {
                    $convertedValue = $property_value -as $resolvedType
                }

                Write-Verbose "Restoring '$property_name' as [$($resolvedType.FullName)]: $convertedValue"

                $TaskProperties | Add-Member -MemberType NoteProperty -Name $property_name -Value $convertedValue -Force
            } catch {
                Write-Warning "Failed to restore property '$property_name': $_"
            }
        }

        return $TaskProperties
    }
}


function Add-SchedTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName
    )

    process {

        $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks"

        # Ensure the registry path exists
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }

        # Get all script files (*.ps1) in the specified folder
        $rval = Get-ItemProperty -Path $registryPath -Name "activetasks" -ErrorAction Ignore

        [string[]]$list = @()
        if (!($rval)) {
            $list += "$TaskName"
            Set-ItemProperty -Path $registryPath -Name "activetasks" -Value $list -Type MultiString
        } else {
            [string[]]$list = $rval.activetasks
            $list += "$TaskName"
            Set-ItemProperty -Path $registryPath -Name "activetasks" -Value $list -Type MultiString
        }
    }
}


function Get-SchedTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks"
    [string[]]$list = @()
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        return $list
    }

    # Get all script files (*.ps1) in the specified folder
    $rval = Get-ItemProperty -Path $registryPath -Name "activetasks" -ErrorAction Ignore

    [string[]]$list = @()
    if (!($rval)) {
        return $list
    } else {
        [string[]]$list = $rval.activetasks
        return $list
    }
    $list
}


function Clear-SchedTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks"
    [string[]]$list = @()
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        return
    }

    # Get all script files (*.ps1) in the specified folder
    $rval = Get-ItemProperty -Path $registryPath -Name "activetasks" -ErrorAction Ignore


    if (!($rval)) {
        return
    } else {
        Remove-Item -Path $rval.PSPath -Force -Recurse
        Write-Verbose "Deleted registry key: $($rval.PSChildName)"
    }
}

function Remove-SchedTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName
    )

    process {

        $registryPath = "HKCU:\Software\arsscriptum\PowerShell.Module.ThinProfile\SchedTasks"

        # Check if registry key exists
        if (-not (Test-Path $registryPath)) {
            Write-Verbose "No scheduled task registry key exists."
            return
        }

        # Retrieve the existing list
        $rval = Get-ItemProperty -Path $registryPath -Name "activetasks" -ErrorAction SilentlyContinue

        if ($null -ne $rval -and $rval.activetasks) {
            [string[]]$list = $rval.activetasks
            # Remove the task (case-insensitive match)
            $newList = $list | Where-Object { $_ -ne $TaskName }

            if ($newList.Count -eq 0) {
                Remove-ItemProperty -Path $registryPath -Name "activetasks" -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -Path $registryPath -Name "activetasks" -Value $newList -Type MultiString
            }

            Write-Verbose "Removed task '$TaskName' from scheduled task registry."
        } else {
            Write-Verbose "No active tasks found to remove."
        }
    }
}

function Show-SchedTasksDebugInfo {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Json
    )


    try {
        [string[]]$TasksList = Get-SchedTasks
        if (-not $TasksList -or $TasksList.Count -eq 0) {
            Write-Host "⚠ No scheduled tasks found in registry list." -ForegroundColor Yellow
            return
        }

        foreach ($task in $TasksList) {
            try {
                $TaskDetails = Get-ScheduledTaskDetails -TaskName $task
                $Status = Get-ScheduledTaskInfo -TaskName $task -ErrorAction Stop

                Write-Host "`n=========================================" -ForegroundColor DarkGray
                Write-Host "Scheduled Task : $task" -ForegroundColor Cyan
                Write-Host "Path           : $($TaskDetails.TaskPath)"
                Write-Host "User           : $($TaskDetails.Principal.UserId)"
                Write-Host "Created        : $($TaskDetails.General_DateCreated)"
                Write-Host "State          : $($Status.State)"
                Write-Host "Last Run Time  : $($Status.LastRunTime)"
                Write-Host "Last Result    : $($Status.LastTaskResult)"
                Write-Host "Next Run Time  : $($Status.NextRunTime)"
                Write-Host "Execute        : $($TaskDetails.Actions_Execute)"
                Write-Host "Arguments      : $($TaskDetails.Actions_Arguments)"
                Write-Host "Start Boundary : $($TaskDetails.Triggers_StartBoundary)"
                Write-Host "End Boundary   : $($TaskDetails.Triggers_EndBoundary)"
                Write-Host "Enabled        : $($TaskDetails.Triggers_Enabled)"
            } catch {
                Write-Warning "⚠ Failed to get task info for '$task': $_"
            }
        }

    } catch {
        Write-Error "❌ Error during update check: $_"
        return $false
    }
}

function ConvertFrom-CimType {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([type])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "CIM type to convert")]
        [Microsoft.Management.Infrastructure.CimType]$CimType
    )

    process {
        switch ($CimType) {
            'Boolean' { [bool] }
            'Char16' { [char] }
            'DateTime' { [string] } # Can optionally be parsed to [datetime]
            'Instance' { [Microsoft.Management.Infrastructure.CimInstance] }
            'Real32' { [single] }
            'Real64' { [double] }
            'Reference' { [Microsoft.Management.Infrastructure.CimInstance] }
            'SInt8' { [sbyte] }
            'UInt8' { [byte] }
            'SInt16' { [int16] }
            'UInt16' { [uint16] }
            'SInt32' { [int32] }
            'UInt32' { [uint32] }
            'SInt64' { [int64] }
            'UInt64' { [uint64] }
            'String' { [string] }
            'Object' { [object] }

            'BooleanArray' { [bool[]] }
            'Char16Array' { [char[]] }
            'DateTimeArray' { [string[]] }
            'InstanceArray' { [Microsoft.Management.Infrastructure.CimInstance[]] }
            'Real32Array' { [single[]] }
            'Real64Array' { [double[]] }
            'ReferenceArray' { [Microsoft.Management.Infrastructure.CimInstance[]] }
            'SInt8Array' { [sbyte[]] }
            'UInt8Array' { [byte[]] }
            'SInt16Array' { [int16[]] }
            'UInt16Array' { [uint16[]] }
            'SInt32Array' { [int32[]] }
            'UInt32Array' { [uint32[]] }
            'SInt64Array' { [int64[]] }
            'UInt64Array' { [uint64[]] }
            'StringArray' { [string[]] }
            'ObjectArray' { [object[]] }

            default {
                throw "❌ Unsupported CimType: $CimType"
            }
        }
    }
}

function Convert-SchedTaskStateValueToString {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "State ID (0-4) to convert to string")]
        [ValidateRange(0, 4)]
        [int32]$Id
    )

    process {
        $SchedTaskStateEnum = @{
            0 = 'Unknown'
            1 = 'Disabled'
            2 = 'Queued'
            3 = 'Ready'
            4 = 'Running'
        }

        if ($SchedTaskStateEnum.ContainsKey($Id)) {
            return $SchedTaskStateEnum[$Id]
        } else {
            Write-Warning "Unrecognized state ID: $Id"
            return 'Invalid'
        }
    }
}


function Unregister-AllSchedTasks {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    try {
        [string[]]$TasksList = Get-SchedTasks
        if (-not $TasksList -or $TasksList.Count -eq 0) {
            Write-Host "⚠ No scheduled tasks found in registry list." -ForegroundColor Yellow
            return
        }
        [System.Collections.ArrayList]$DeleteList = [System.Collections.ArrayList]::new()
        foreach ($task in $TasksList) {
            $TaskPtr = Get-ScheduledTask -TaskName $task -ErrorAction Ignore
            if ($TaskPtr -ne $Null) {
                $task_name = $TaskPtr.TaskName
                $prop = $TaskPtr.CimInstanceProperties.Where({ $_.Name -eq 'State' })
                $propType = $prop.CimType | ConvertFrom-CimType
                $CurrentStateId = $prop.Value -as $propType
                $CurrentStateName = $CurrentStateId | Convert-SchedTaskStateValueToString
                try {
                    Write-Host "Unregistering ScheduledTask `"$task_name`" (state $CurrentStateName) " -f DarkYellow -n
                    $TaskPtr | Unregister-ScheduledTask -Confirm:$False -ErrorAction Stop
                    Write-Host "Success!" -f DarkGreen
                    [void]$DeleteList.Add($task_name)
                } catch {
                    Write-Host "Failed! ($_)" -f DarkRed
                }
            }
        }

        if ($($DeleteList.Count) -gt 0) {
            Write-Host "Cleaning up: " -n -f DarkRed
            foreach ($rmtask in $DeleteList) {
                Write-Host "$rmtask " -n -f DarkCyan
                Remove-SchedTasks $rmtask
            }
            Write-Host "`nRemoved $($DeleteList.Count) tasks" -f DarkCyan
        }
    } catch {
        Write-Error "❌ Error : $_"
        return $false
    }
}

function Test-SerializableProperty {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "Name of the scheduled task")]
        [string]$PropertyName
    )

    process {
        $ScheduledTaskProperties = @(
            'State'
            #'Actions'
            'Author'
            'Date'
            'Description'
            #'Documentation'
            #'Principal'
            #'SecurityDescriptor'
            #'Settings'
            #'Source'
            'TaskName'
            'TaskPath'
            #'Triggers'
            'URI'
            'Version'
            #'PSComputerName'
            #'CimClass'
            #'CimInstanceProperties'
            #'CimSystemProperties'
        )

        if ($ScheduledTaskProperties.Contains($PropertyName)) {
            return $True
        } else {
            return $False
        }
    }

}


function Get-ScheduledTaskDetails {
    [CmdletBinding(DefaultParameterSetName = 'TaskName')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'TaskName', HelpMessage = 'TaskName')]
        [string]$TaskName,

        [Parameter(Mandatory = $true, ParameterSetName = 'TaskPath', HelpMessage = 'TaskPath')]
        [string]$TaskPath
    )
    # Retrieve task data based on parameter set
    if ($PSCmdlet.ParameterSetName -eq 'TaskName') {
        $TaskPtr = Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore
        $DetailsTaskData = schtasks /Query /TN $TaskName /V /FO CSV | ConvertFrom-Csv
    }
    else {
        $TaskPtr = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction Ignore
        $Name = $TaskPtr.TaskName
        $DetailsTaskData = schtasks /Query /TN $Name /V /FO CSV | ConvertFrom-Csv
    }
    $TaskProperties = [pscustomobject]@{}
    #$prop = $TaskPtr.CimInstanceProperties.Where({ $_.Name -eq 'Author' })
    $TaskPtr = Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore
    if ($Null -eq $TaskPtr) {
        Write-Error "ScheduledTask Not Found $TaskName"
        return
    }
    foreach ($prop in $TaskPtr.CimInstanceProperties) {
        $property_name = "$($prop.Name)"
        if (Test-SerializableProperty $property_name) {
            $property_value = $prop.Value
            $pcimtype = $prop.CimType
            try {
                $typeStruct = ConvertFrom-CimType $pcimtype
                $VariableTypeName = $typeStruct.Name
                $VariableTypeFull = $typeStruct.FullName
                $resolvedType = [type]::GetType($VariableTypeFull, $false)
                if ($null -eq $resolvedType) {
                    Write-Warning "Could not resolve type '$typeString' for property '$property_name'. Defaulting to string."
                    $resolvedType = [string]
                }
                Write-Verbose "CimType $pcimtype"
                Write-Verbose "VariableTypeName $pcimtype"
                Write-Verbose "VariableTypeFull $VariableTypeFull"
                Write-Verbose "resolvedType $resolvedType"
            } catch {
                throw "$_"
            }

            if (($resolvedType -eq [bool]) -or ($resolvedType -eq [Boolean])) {
                $converted_boolean = if ($property_value -eq '0') { $False } else { $True }
                $convertedValue = [bool]::Parse($converted_boolean)
            }
            elseif ($resolvedType.IsEnum) {
                $convertedValue = [Enum]::Parse($resolvedType, $property_value)
            }
            elseif ($resolvedType -eq [string[]] -and ($property_value -is [string])) {
                $convertedValue =, $property_value # Ensure it's an array
            }
            else {
                $convertedValue = $property_value -as $resolvedType
            }

            Write-Verbose "Restoring '$property_name' as [$($resolvedType.FullName)]: $convertedValue"

            $TaskProperties | Add-Member -MemberType NoteProperty -Name $property_name -Value $convertedValue -Force

            Write-Verbose "$VariableName"
        } else {
            Write-Verbose "Property $property_name is not serialized in the shceduledtask object. We don't use it. See function Test-SerializableProperty to change the fiultered properties."
        }
    }

    foreach ($prop in $DetailsTaskData.PSObject.Properties) {
        try {
            $raw_prop_name = "$($prop.Name)"
            $property_name = $raw_prop_name.Replace(' ', '_')
            $property_value = ($prop.Value -as $prop.TypeNameOfValue)
            $typeStruct = $property_value.GetType()
            $VariableTypeName = $typeStruct.Name
            $VariableTypeFull = $typeStruct.FullName
            $resolvedType = [type]::GetType($VariableTypeFull, $false)
            Write-Verbose "raw_prop_name $raw_prop_name"
            Write-Verbose "property_name $property_name"
            Write-Verbose "VariableTypeName $VariableTypeName"
            Write-Verbose "VariableTypeFull $VariableTypeFull"
            Write-Verbose "resolvedType $resolvedType"
            if ($null -eq $resolvedType) {
                Write-Warning "Could not resolve type '$VariableTypeFull' for property '$property_name'. Defaulting to string."
                $resolvedType = [string]
            }

            # Try casting the value to the original type
            if (($resolvedType -eq [bool]) -or ($resolvedType -eq [Boolean])) {
                $converted_boolean = if ($property_value -eq '0') { $False } else { $True }
                $convertedValue = [bool]::Parse($converted_boolean)
            }
            elseif ($resolvedType.IsEnum) {
                $convertedValue = [Enum]::Parse($resolvedType, $property_value)
            }
            elseif ($resolvedType -eq [string[]] -and ($property_value -is [string])) {
                $convertedValue =, $property_value # Ensure it's an array
            }
            else {
                $convertedValue = $property_value -as $resolvedType
            }

            Write-Verbose "Restoring '$property_name' as [$($resolvedType.FullName)]: $convertedValue"

            $TaskProperties | Add-Member -MemberType NoteProperty -Name $property_name -Value $convertedValue -Force
        } catch {
            Write-Warning "Failed to restore property '$property_name': $_"
        }
    }

    $StateString = $TaskProperties.State | Convert-SchedTaskStateValueToString
    $TaskProperties | Add-Member -MemberType NoteProperty -Name "State_DisplayName" -Value "$StateString" -Force

    return $TaskProperties
}

        <#
function Archive {

    $UserData = $AllTaskData.Principal
    foreach ($prop in $UserData.PSObject.Properties) {
        $pname = "User_{0}" -f $prop.Name.Replace(' ', '-')
        $AllTaskData | Add-Member -NotePropertyName $pname -NotePropertyValue $prop.Value -Force
    }
    $Settings = $AllTaskData.Settings
    foreach ($prop in $Settings.PSObject.Properties) {
        $pname = "Settings_{0}" -f $prop.Name.Replace(' ', '-')
        $AllTaskData | Add-Member -NotePropertyName $pname -NotePropertyValue $prop.Value -Force
    }
    $Triggers = $AllTaskData.Triggers
    $AllTaskData | Add-Member -NotePropertyName "Triggers_StartBoundary" -NotePropertyValue $Triggers.StartBoundary -Force
    $AllTaskData | Add-Member -NotePropertyName "Triggers_EndBoundary" -NotePropertyValue $Triggers.EndBoundary -Force
    $AllTaskData | Add-Member -NotePropertyName "Triggers_Enabled" -NotePropertyValue $Triggers.Enabled -Force
    $AllTaskData | Add-Member -NotePropertyName "Triggers_DaysOfWeek" -NotePropertyValue $Triggers.DaysOfWeek -Force

    $Actions = $AllTaskData.Actions
    $AllTaskData | Add-Member -NotePropertyName "Actions_Execute" -NotePropertyValue $Actions.Execute -Force
    $AllTaskData | Add-Member -NotePropertyName "Actions_Arguments" -NotePropertyValue $Actions.Arguments -Force

    # Merge properties from $DetailsTaskData into $AllTaskData


    return $AllTaskData

}
    #>
# SIG # Begin signature block
# MIIHTgYJKoZIhvcNAQcCoIIHPzCCBzsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDnxnbO3tf4slqb
# inLtwXyCCO+/13MBIFXZgfS6Sy2xAaCCBDAwggQsMIIClKADAgECAhAUiNANG3zj
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
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAf
# QhcmqfOXjR9CnYz8izvPnBqwSwz1VwY1gvr+La1HqTANBgkqhkiG9w0BAQEFAASC
# AYCLfjUURnDgt3kEVsI6jMHbOnynKu6pFX38utibFmyIq5N4nbClF5Eskkl06f8J
# zL8rGQwmdvHtUT/WMFIrDAg22yWLEk4h2JZUPSwHnnzWNg5RFWbHN8kOa01xbhr0
# 0Uyy0knQ7/kwXk34HK8OodVuswY/o+jn71S9WzaFJedpqA3kJ2lxHZYynRVAKgcj
# hLP+Q/mteAot2H3GMC7kyYTNx1eGLNIQaXexOFhnffjTzLZKayC/aeFLnWHPQdU0
# i22Mb7mbUzZ5qYwjz5KshltkKkqoZisFE16PfS6r+VxKVFD7pZWgA7KJWQ/L6SnA
# iyeevJUy5mNZ1ItzBSkpZM1/3mgMIfIELeQ6RnPgugN1Eu0ZuKPni9BA2oNedm9R
# y6D/8kNtF0/fFARo+jiF7O9ehW8RdpCbcKeqcFQiV21dtBSDdrdPJmQQTcKfsQk1
# EJfPhS2Gd77QpqkeMTgggh5h0K4m7srzNNaJLKvIE+FPMsA4iDWe8PTD3boP0fkZ
# 44c=
# SIG # End signature block
