---
external help file: PowerShell.Module.ThinProfile-help.xml
Module Name: PowerShell.Module.ThinProfile
online version:
schema: 2.0.0
---

# Invoke-Robocopy

## SYNOPSIS
Copy a directory to a destination directory using ROBOCOPY.

## SYNTAX

```
Invoke-Robocopy [-Source] <String> [-Destination] <String> [-SyncType <String>] [-Log <String>]
 [-ExcludedFiles <String[]>] [-ExcludedDirectories <String[]>] [-Threads <Int32>] [-Retries <Int32>]
 [-WaitOnError <Int32>] [-CopyAll] [-BackupMode] [-Restartable] [-ListOnly]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invoke ROBOCOPY to copy files, a wrapper.

## EXAMPLES

### EXAMPLE 1
```
Sync-Directories $dst $src -SyncType 'NOCOPY'
Sync-Directories $src $dst -SyncType 'MIRROR' -Verbose
Sync-Directories $src $dst -Test
```

## PARAMETERS

### -Source
Source Directory (drive:\path or \\\\server\share\path).

```yaml
Type: String
Parameter Sets: (All)
Aliases: s, src

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Destination
Destination Dir  (drive:\path or \\\\server\share\path).

```yaml
Type: String
Parameter Sets: (All)
Aliases: d, dst

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SyncType
One of the following operating procedures:
'MIR'    ==\> MIRror a directory tree (equivalent to /E plus /PURGE), delete dest files/dirs that no longer exist in source.
'COPY'   ==\> It will leave everything in destination, but will add new files fro source, usefull to merge 2 folders
'NOCOPY' ==\> delete dest files/dirs that no longer exist in source.
do not copy new, keep same.
Default  ==\> MIRROR

```yaml
Type: String
Parameter Sets: (All)
Aliases: t, type

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Log
Log File name

```yaml
Type: String
Parameter Sets: (All)
Aliases: l

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludedFiles
{{ Fill ExcludedFiles Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: xf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludedDirectories
{{ Fill ExcludedDirectories Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: xd

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Threads
Num threads in multi-threaded copies with n threads (default 8)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 8
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retries
Retries

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -WaitOnError
WaitOnError seconds

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -CopyAll
COPY ALL file info (equivalent to /COPY:DATSOU)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: all

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BackupMode
copy files in restartable mode.; if access denied use Backup mode.
Requires Admin privileges to add user rights.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: b

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Restartable
use restartable mode

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: z

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ListOnly
list only

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
