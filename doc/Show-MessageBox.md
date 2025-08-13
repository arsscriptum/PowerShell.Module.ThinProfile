---
external help file: PowerShell.Module.ThinProfile-help.xml
Module Name: PowerShell.Module.ThinProfile
online version:
schema: 2.0.0
---

# Show-MessageBox

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Show-MessageBox [-Content] <Object> [[-Title] <String>] [[-ButtonType] <Array>] [[-CustomButtons] <Array>]
 [[-ContentFontSize] <Int32>] [[-TitleFontSize] <Int32>] [[-BorderThickness] <Int32>] [[-CornerRadius] <Int32>]
 [[-ShadowDepth] <Int32>] [[-BlurRadius] <Int32>] [[-WindowWidth] <Int32>] [[-WindowHost] <Object>]
 [[-Timeout] <Int32>] [[-TitleAlign] <Object>] [[-ContentAlign] <Object>] [[-OnLoaded] <ScriptBlock>]
 [[-OnClosed] <ScriptBlock>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BlurRadius
{{ Fill BlurRadius Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BorderThickness
{{ Fill BorderThickness Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ButtonType
{{ Fill ButtonType Description }}

```yaml
Type: Array
Parameter Sets: (All)
Aliases:
Accepted values: OK, OK-Cancel, Abort-Retry-Ignore, Yes-No-Cancel, Yes-No, Retry-Cancel, Cancel-Continue, Cancel-TryAgain-Continue, None

Required: False
Position: 2
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

### -Content
{{ Fill Content Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentAlign
{{ Fill ContentAlign Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
Accepted values: center, left, right, stretch

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentFontSize
{{ Fill ContentFontSize Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CornerRadius
{{ Fill CornerRadius Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomButtons
{{ Fill CustomButtons Description }}

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnClosed
{{ Fill OnClosed Description }}

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnLoaded
{{ Fill OnLoaded Description }}

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShadowDepth
{{ Fill ShadowDepth Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
{{ Fill Timeout Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
{{ Fill Title Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TitleAlign
{{ Fill TitleAlign Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
Accepted values: center, left, right, stretch

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TitleFontSize
{{ Fill TitleFontSize Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
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

### -WindowHost
{{ Fill WindowHost Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WindowWidth
{{ Fill WindowWidth Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
