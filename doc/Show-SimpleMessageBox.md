---
external help file: PowerShell.Module.ThinProfile-help.xml
Module Name: PowerShell.Module.ThinProfile
online version:
schema: 2.0.0
---

# Show-SimpleMessageBox

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Show-SimpleMessageBox [-Content] <Object> [[-Title] <String>] [[-ButtonType] <Array>]
 [[-CustomButtons] <Array>] [[-ContentFontSize] <Int32>] [[-TitleFontSize] <Int32>]
 [[-BorderThickness] <Int32>] [[-CornerRadius] <Int32>] [[-ShadowDepth] <Int32>] [[-BlurRadius] <Int32>]
 [[-WindowHost] <Object>] [[-Timeout] <Int32>] [[-OnLoaded] <ScriptBlock>] [[-OnClosed] <ScriptBlock>]
 [-ProgressAction <ActionPreference>] [-ContentBackground <String>] [-FontFamily <String>]
 [-TitleFontWeight <String>] [-ContentFontWeight <String>] [-ContentTextForeground <String>]
 [-TitleTextForeground <String>] [-BorderBrush <String>] [-TitleBackground <String>]
 [-ButtonTextForeground <String>] [<CommonParameters>]
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

### -BorderBrush
{{ Fill BorderBrush Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

Required: False
Position: Named
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

### -ButtonTextForeground
{{ Fill ButtonTextForeground Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

Required: False
Position: Named
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

### -ContentBackground
{{ Fill ContentBackground Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

Required: False
Position: Named
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

### -ContentFontWeight
{{ Fill ContentFontWeight Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Black, Bold, DemiBold, ExtraBlack, ExtraBold, ExtraLight, Heavy, Light, Medium, Normal, Regular, SemiBold, Thin, UltraBlack, UltraBold, UltraLight

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentTextForeground
{{ Fill ContentTextForeground Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

Required: False
Position: Named
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

### -FontFamily
{{ Fill FontFamily Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: 13_Misa, 14 SegmentLED, 1952 RHEINMETALL, 395 Equalizer, 395 equalizer 2, A4 SPEED, Acme, adelia, alarm clock, Alef, aliens and cows, Amiri, Amiri Quran, Arial, Arial Black, Audiowide, Bahnschrift, Bahnschrift Condensed, Bahnschrift Light, Bahnschrift Light Condensed, Bahnschrift Light SemiCondensed, Bahnschrift SemiBold, Bahnschrift SemiBold Condensed, Bahnschrift SemiBold SemiConden, Bahnschrift SemiCondensed, Bahnschrift SemiLight, Bahnschrift SemiLight Condensed, Bahnschrift SemiLight SemiConde, Baiser, Bassy, Baumans, Billion Dreams, Billstone Signature Personal Us, Blue Screen Personal Use, Bridal Routine Demo, Brittany Signature, Bump Pad, Bungee Outline, Bungee Shade, Bungee Spice, Bungee Tint, Caladea, Calibri, Calibri Light, Cambria, Cambria Math, Candara, Candara Light, Carlito, Cascadia Code, Cascadia Code ExtraLight, Cascadia Code Light, Cascadia Code SemiBold, Cascadia Code SemiLight, Cascadia Mono, Cascadia Mono ExtraLight, Cascadia Mono Light, Cascadia Mono SemiBold, Cascadia Mono SemiLight, Cheap Fire, Cherolina, cityburn, Comic Sans MS, COMPUTER Robot, Consola Mono, Consolas, Constantia, Corbel, Corbel Light, Courier New, Darlington Demo, David CLM, David Libre, DEC Terminal Modern, Deep Shadow, Deep Shadow Over, Deep Shadow Under, DejaVu Math TeX Gyre, DejaVu Sans, DejaVu Sans Condensed, DejaVu Sans Light, DejaVu Sans Mono, DejaVu Serif, DejaVu Serif Condensed, digital dark system, Digital-7, Digital-7 Italic, Digital-7 Mono, DirtyBoy, DISPLAY FREE TFB, Dream Weaver - Demo, Ebrima, Energized, Espionage, Expletus Sans, F25 Bank Printer, FIGHTBACK, Fisheye, Font Awesome 6 Brands Regular, Font Awesome 6 Free Regular, Font Awesome 6 Free Solid, Font Awesome v4 Compatibility R, Frank Ruehl CLM, Frank Ruhl Hofshi, Franklin Gothic Medium, Gabella, Gabella College, Gabella Shiny, Gabriola, Gadugi, Game Over, Gentium Basic, Gentium Book Basic, Georgia, Halimun, Hatch, HoloLens MDL2 Assets, Honk, Honk Balloon, Honk Brush, Honk Compressed, Honk Flower, Honk Irregular, Honk Ninja, Honk Rounded, Honk Softie, Honk Wood, Impact, Ink Free, Javanese Text, JMH Typewriter, Jura, Kalnia Glaze, Kalnia Glaze ExtraLight, Kalnia Glaze Light, Kalnia Glaze Medium, Kalnia Glaze SemiBold, Kalnia Glaze Thin, Kanit, Kanit Black, Kanit ExtraBold, Kanit ExtraLight, Kanit Light, Kanit Medium, Kanit SemiBold, Kanit Thin, La Machine Company, Leelawadee UI, Leelawadee UI Semilight, Liberation Mono, Liberation Sans, Liberation Sans Narrow, Liberation Serif, Libre Barcode 39 Text, Linux Biolinum G, Linux Libertine Display G, Linux Libertine G, Lotion, Lotion Black, Lotion Black Without Ligatures, Lotion SemiBold, Lotion SmBold Without Ligatures, Lotion Without Ligatures, LT Binary Neue, LT Binary Neue Round, Lucida Console, Lucida Sans Unicode, Malgun Gothic, Malgun Gothic Semilight, Marlett, Megalomania, Michroma, Microsoft Himalaya, Microsoft JhengHei, Microsoft JhengHei Light, Microsoft JhengHei UI, Microsoft JhengHei UI Light, Microsoft New Tai Lue, Microsoft PhagsPa, Microsoft Sans Serif, Microsoft Tai Le, Microsoft YaHei, Microsoft YaHei Light, Microsoft YaHei UI, Microsoft YaHei UI Light, Microsoft Yi Baiti, MingLiU-ExtB, MingLiU_HKSCS-ExtB, Miriam CLM, Miriam Libre, Miriam Mono CLM, Mongolian Baiti, MonoSpatial, Movie Letters, MS Gothic, MS PGothic, MS UI Gothic, MV Boli, Myanmar Text, Nabla Regular, Nachlieli CLM, New Brush, Nirmala UI, Nirmala UI Semilight, Noto Kufi Arabic, Noto Naskh Arabic, Noto Sans, Noto Sans Arabic, Noto Sans Armenian, Noto Sans Georgian, Noto Sans Georgian Bold, Noto Sans Hebrew, Noto Sans Lao, Noto Sans Lisu, Noto Serif, Noto Serif Armenian, Noto Serif Bold, Noto Serif Georgian, Noto Serif Hebrew, Noto Serif Lao, Nouveau IBM, Nouveau IBM Stretch, NSimSun, OpenSymbol, Orbitron, Orbitron Black, Orbitron ExtraBold, Orbitron Medium, Orbitron SemiBold, Palatino Linotype, ParadroidMono Light, Parisienne, Photograph Signature, PMingLiU-ExtB, PUNKBABE, Race Stripe Demo, Rajdhani, Rajdhani Bold, Rajdhani Light, Rajdhani Medium, Rajdhani Semibold, Redemption, Redriver, Reem Kufi, Revalia, Rubik, Sacrifice Demo, Scheherazade, Secret Code, Segoe MDL2 Assets, Segoe Print, Segoe Script, Segoe UI, Segoe UI Black, Segoe UI Emoji, Segoe UI Historic, Segoe UI Light, Segoe UI Semibold, Segoe UI Semilight, Segoe UI Symbol, Share-TechMono, Signatra DEMO, Signatrue, Silkscreen, Simplicity, SimSun, SimSun-ExtB, Sitka Banner, Sitka Display, Sitka Heading, Sitka Small, Sitka Subheading, Sitka Text, Skynews, Solid Mono, Speedwriter, Sylfaen, Symbol, System+error, Tahoma, Technova, Terminal F4, The Wedding Signature, The X-Files, Times New Roman, Tomatoes, Tomorrow, Tomorrow Black, Tomorrow ExtraBold, Tomorrow ExtraLight, Tomorrow Light, Tomorrow Medium, Tomorrow SemiBold, Tomorrow Thin, Trade Winds, Trebuchet MS, TT Interphases Pro Mono Trl, TT Intrphss Pr Mn Trl Vr, TT Intrphss Pr Mn Trl Vr It, Universal Accreditation, Verdana, voxBOX, voxBOX Condensed, voxBOX Condensed Italic, voxBOX Expanded, voxBOX Expanded Italic, voxBOX Gradient, voxBOX Gradient Italic, voxBOX Halftone, voxBOX Halftone Italic, voxBOX Italic, voxBOX Laser, voxBOX Laser Italic, voxBOX Leftalic, voxBOX Semi-Italic, voxBOX Super-Italic, voxBOX Title, voxBOX Title Italic, Wallpoet, WarText, Webdings, White Rabbit, Wingdings, X-Classified, Yu Gothic, Yu Gothic Light, Yu Gothic Medium, Yu Gothic UI, Yu Gothic UI Light, Yu Gothic UI Semibold, Yu Gothic UI Semilight

Required: False
Position: Named
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
Position: 13
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
Position: 12
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
Position: 11
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

### -TitleBackground
{{ Fill TitleBackground Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

Required: False
Position: Named
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

### -TitleFontWeight
{{ Fill TitleFontWeight Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Black, Bold, DemiBold, ExtraBlack, ExtraBold, ExtraLight, Heavy, Light, Medium, Normal, Regular, SemiBold, Thin, UltraBlack, UltraBold, UltraLight

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TitleTextForeground
{{ Fill TitleTextForeground Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: AliceBlue, AntiqueWhite, Aqua, Aquamarine, Azure, Beige, Bisque, Black, BlanchedAlmond, Blue, BlueViolet, Brown, BurlyWood, CadetBlue, Chartreuse, Chocolate, Coral, CornflowerBlue, Cornsilk, Crimson, Cyan, DarkBlue, DarkCyan, DarkGoldenrod, DarkGray, DarkGreen, DarkKhaki, DarkMagenta, DarkOliveGreen, DarkOrange, DarkOrchid, DarkRed, DarkSalmon, DarkSeaGreen, DarkSlateBlue, DarkSlateGray, DarkTurquoise, DarkViolet, DeepPink, DeepSkyBlue, DimGray, DodgerBlue, Firebrick, FloralWhite, ForestGreen, Fuchsia, Gainsboro, GhostWhite, Gold, Goldenrod, Gray, Green, GreenYellow, Honeydew, HotPink, IndianRed, Indigo, Ivory, Khaki, Lavender, LavenderBlush, LawnGreen, LemonChiffon, LightBlue, LightCoral, LightCyan, LightGoldenrodYellow, LightGray, LightGreen, LightPink, LightSalmon, LightSeaGreen, LightSkyBlue, LightSlateGray, LightSteelBlue, LightYellow, Lime, LimeGreen, Linen, Magenta, Maroon, MediumAquamarine, MediumBlue, MediumOrchid, MediumPurple, MediumSeaGreen, MediumSlateBlue, MediumSpringGreen, MediumTurquoise, MediumVioletRed, MidnightBlue, MintCream, MistyRose, Moccasin, NavajoWhite, Navy, OldLace, Olive, OliveDrab, Orange, OrangeRed, Orchid, PaleGoldenrod, PaleGreen, PaleTurquoise, PaleVioletRed, PapayaWhip, PeachPuff, Peru, Pink, Plum, PowderBlue, Purple, Red, RosyBrown, RoyalBlue, SaddleBrown, Salmon, SandyBrown, SeaGreen, SeaShell, Sienna, Silver, SkyBlue, SlateBlue, SlateGray, Snow, SpringGreen, SteelBlue, Tan, Teal, Thistle, Tomato, Transparent, Turquoise, Violet, Wheat, White, WhiteSmoke, Yellow, YellowGreen

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
