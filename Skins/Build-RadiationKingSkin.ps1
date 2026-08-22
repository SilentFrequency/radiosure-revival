################################################################################
#  Build-RadiationKingSkin.ps1                                                 #
#                                                                              #
#  Generates a RadioSure skin styled after the Radiation King - the 1950s      #
#  valve radio from Fallout: walnut cabinet, backlit amber tuning dial, brass   #
#  knobs. Fallout and Vault-Tec are trademarks of Bethesda Softworks; this is   #
#  fan work and every pixel here is drawn from scratch with System.Drawing -    #
#  no game assets are used or redistributed.                                    #
#                                                                              #
#  Control geometry is identical to the stock Standard skin: same buttons in    #
#  the same places, restyled.                                                  #
################################################################################

[CmdletBinding()]
param(
    [string] $OutDir   = "$env:LOCALAPPDATA\RadioSure\Skins\Radiation King.rsn",
    [string] $SkinName = "Radiation King"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function C ([int]$r, [int]$g, [int]$b, [int]$a = 255) {
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

# --- Palette: oxblood bakelite, brass, and warm dial light --------------------
# The Radiation King's body is a deep red bakelite, not walnut - the cream
# grille and brass trim only sing against that red.
$WoodDeep   = C 46  12  11
$WoodDark   = C 84  22  19
$WoodMid    = C 124 34  28
$WoodLite   = C 168 58  44
$Brass      = C 198 154  82
$BrassLite  = C 240 208 142
$BrassDark  = C 110  80  36
$DialCream  = C 235 214 168
$DialWarm   = C 214 178 112
$Amber      = C 255 176  64
$AmberGlow  = C 255 150  40
$InkBrown   = C 40  24  10
$Shadow     = C 0   0   0

# --- Canvas helpers -----------------------------------------------------------

function New-Canvas ([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return @{ Bitmap = $bmp; Graphics = $g }
}

function Save-Canvas ($canvas, [string]$name) {
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Bitmap.Dispose()
}

function New-RoundRect ([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x,             $y,             $d, $d, 180, 90)
    $p.AddArc($x + $w - $d,   $y,             $d, $d, 270, 90)
    $p.AddArc($x + $w - $d,   $y + $h - $d,   $d, $d,   0, 90)
    $p.AddArc($x,             $y + $h - $d,   $d, $d,  90, 90)
    $p.CloseFigure()
    return $p
}

function Draw-Glow ($g, [single]$cx, [single]$cy, [single]$radius, $colour, [int]$alpha) {
    if ($radius -le 0) { return }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse($cx - $radius, $cy - $radius, $radius * 2, $radius * 2)
    $br = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $br.CenterColor = [System.Drawing.Color]::FromArgb($alpha, $colour.R, $colour.G, $colour.B)
    $br.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $colour.R, $colour.G, $colour.B))
    $g.FillPath($br, $path)
    $br.Dispose(); $path.Dispose()
}

# Walnut: a warm vertical gradient, then long grain streaks, then a few darker
# figure lines. Cheap, but at 490px wide it reads convincingly as wood.
function Draw-Wood ($g, [int]$x, [int]$y, [int]$w, [int]$h, [int]$seed) {
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $WoodMid, $WoodDeep, 90)
    $g.FillRectangle($br, $rect); $br.Dispose()

    $rnd = New-Object System.Random($seed)
    for ($i = 0; $i -lt 420; $i++) {
        $gy = $y + $rnd.Next(0, $h)
        $a  = $rnd.Next(6, 26)
        $light = $rnd.Next(0, 2)
        if ($light -eq 1) { $col = C $WoodLite.R $WoodLite.G $WoodLite.B $a }
        else              { $col = C $WoodDeep.R $WoodDeep.G $WoodDeep.B ($a + 14) }
        $pen = New-Object System.Drawing.Pen($col, $rnd.Next(1, 3))
        $x1 = $x + $rnd.Next(-40, $w)
        $len = $rnd.Next(60, 300)
        $g.DrawBezier($pen, $x1, $gy, $x1 + $len * 0.33, $gy - $rnd.Next(0, 4),
                            $x1 + $len * 0.66, $gy + $rnd.Next(0, 4), $x1 + $len, $gy)
        $pen.Dispose()
    }

    # Vignette: darker at the edges so the cabinet looks rounded
    $vig = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($x, $y, [Math]::Max(1, [int]($w * 0.12)), $h)),
        (C 0 0 0 120), (C 0 0 0 0), 0)
    $g.FillRectangle($vig, $x, $y, [int]($w * 0.12), $h); $vig.Dispose()
    $vig = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle([int]($x + $w * 0.88), $y, [Math]::Max(1, [int]($w * 0.12)), $h)),
        (C 0 0 0 0), (C 0 0 0 120), 0)
    $g.FillRectangle($vig, [int]($x + $w * 0.88), $y, [int]($w * 0.12), $h); $vig.Dispose()
}

# --- Brass knobs --------------------------------------------------------------
# Authored at 256x256 and scaled to 33x34 by RadioSure, matching the stock skin.

function Draw-Knob ($g, [string]$state) {
    $cx = 128; $cy = 128; $r = 106

    # Drop shadow so the knob sits proud of the cabinet
    Draw-Glow $g $cx ($cy + 8) ($r + 14) $Shadow 110

    switch ($state) {
        'normal'  { $outer1 = $Brass;     $outer2 = $BrassDark; $rimGlow = 0 }
        'hot'     { $outer1 = $BrassLite; $outer2 = $Brass;     $rimGlow = 70 }
        'pressed' { $outer1 = $BrassDark; $outer2 = $Brass;     $rimGlow = 40 }
    }
    if ($rimGlow -gt 0) { Draw-Glow $g $cx $cy ($r + 18) $Amber $rimGlow }

    # Knurled rim
    $rect = New-Object System.Drawing.Rectangle(($cx - $r), ($cy - $r), ($r * 2), ($r * 2))
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $outer1, $outer2, 60)
    $g.FillEllipse($br, $rect); $br.Dispose()

    $knurlPen = New-Object System.Drawing.Pen((C 0 0 0 70), 3)
    for ($i = 0; $i -lt 48; $i++) {
        $ang = $i * 7.5 * [Math]::PI / 180
        $x1 = $cx + [Math]::Cos($ang) * ($r - 12)
        $y1 = $cy + [Math]::Sin($ang) * ($r - 12)
        $x2 = $cx + [Math]::Cos($ang) * $r
        $y2 = $cy + [Math]::Sin($ang) * $r
        $g.DrawLine($knurlPen, $x1, $y1, $x2, $y2)
    }
    $knurlPen.Dispose()

    # Inner face, darker, so the icon has contrast to sit on
    $ir = $r - 26
    $irect = New-Object System.Drawing.Rectangle(($cx - $ir), ($cy - $ir), ($ir * 2), ($ir * 2))
    if ($state -eq 'pressed') { $f1 = $WoodDeep; $f2 = $WoodDark }
    else                      { $f1 = $WoodDark; $f2 = $WoodDeep }
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($irect, $f1, $f2, 90)
    $g.FillEllipse($br, $irect); $br.Dispose()

    $pen = New-Object System.Drawing.Pen($BrassLite, 3)
    $g.DrawEllipse($pen, $irect); $pen.Dispose()

    # Specular highlight across the top left
    if ($state -ne 'pressed') {
        $pen = New-Object System.Drawing.Pen((C 255 255 255 46), 6)
        $g.DrawArc($pen, ($cx - $r + 10), ($cy - $r + 10), (($r - 10) * 2), (($r - 10) * 2), 195, 90)
        $pen.Dispose()
    }
}

function Draw-Icon ($g, [string]$icon, $colour, [string]$state) {
    $b = New-Object System.Drawing.SolidBrush($colour)

    if ($state -ne 'pressed') { Draw-Glow $g 128 128 66 $colour 55 }

    switch ($icon) {
        'play' {
            $pts = @(
                (New-Object System.Drawing.PointF(104, 86)),
                (New-Object System.Drawing.PointF(180, 128)),
                (New-Object System.Drawing.PointF(104, 170))
            )
            $g.FillPolygon($b, $pts)
        }
        'stop' {
            $p = New-RoundRect 98 98 60 60 6
            $g.FillPath($b, $p); $p.Dispose()
        }
        'prev' {
            $pts = @(
                (New-Object System.Drawing.PointF(166, 88)),
                (New-Object System.Drawing.PointF(166, 168)),
                (New-Object System.Drawing.PointF(112, 128))
            )
            $g.FillPolygon($b, $pts)
            $p = New-RoundRect 92 88 14 80 5
            $g.FillPath($b, $p); $p.Dispose()
        }
        'next' {
            $pts = @(
                (New-Object System.Drawing.PointF(90,  88)),
                (New-Object System.Drawing.PointF(90,  168)),
                (New-Object System.Drawing.PointF(144, 128))
            )
            $g.FillPolygon($b, $pts)
            $p = New-RoundRect 150 88 14 80 5
            $g.FillPath($b, $p); $p.Dispose()
        }
        'rec'    { $g.FillEllipse($b, 98, 98, 60, 60) }
        'recoff' {
            $pen = New-Object System.Drawing.Pen($colour, 11)
            $g.DrawEllipse($pen, 100, 100, 56, 56)
            $pen.Dispose()
        }
        'heart' {
            $p = New-Object System.Drawing.Drawing2D.GraphicsPath
            $p.AddArc(88,  92, 42, 42, 160, 200)
            $p.AddArc(126, 92, 42, 42, 180, 200)
            $p.AddLine(166, 126, 128, 172)
            $p.CloseFigure()
            $g.FillPath($b, $p); $p.Dispose()
        }
        'speaker' {
            $pts = @(
                (New-Object System.Drawing.PointF(88,  112)),
                (New-Object System.Drawing.PointF(112, 112)),
                (New-Object System.Drawing.PointF(138, 88)),
                (New-Object System.Drawing.PointF(138, 168)),
                (New-Object System.Drawing.PointF(112, 144)),
                (New-Object System.Drawing.PointF(88,  144))
            )
            $g.FillPolygon($b, $pts)
            $pen = New-Object System.Drawing.Pen($colour, 9)
            $g.DrawArc($pen, 132, 100, 36, 56, -60, 120)
            $g.DrawArc($pen, 124, 88,  54, 80, -55, 110)
            $pen.Dispose()
        }
        'mute' {
            $pts = @(
                (New-Object System.Drawing.PointF(80,  112)),
                (New-Object System.Drawing.PointF(104, 112)),
                (New-Object System.Drawing.PointF(130, 88)),
                (New-Object System.Drawing.PointF(130, 168)),
                (New-Object System.Drawing.PointF(104, 144)),
                (New-Object System.Drawing.PointF(80,  144))
            )
            $g.FillPolygon($b, $pts)
            $pen = New-Object System.Drawing.Pen($colour, 11)
            $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawLine($pen, 146, 108, 180, 148)
            $g.DrawLine($pen, 180, 108, 146, 148)
            $pen.Dispose()
        }
        'gear' {
            $g.FillEllipse($b, 108, 108, 40, 40)
            $pen = New-Object System.Drawing.Pen($colour, 14)
            for ($i = 0; $i -lt 8; $i++) {
                $ang = $i * 45 * [Math]::PI / 180
                $x1 = 128 + [Math]::Cos($ang) * 34
                $y1 = 128 + [Math]::Sin($ang) * 34
                $x2 = 128 + [Math]::Cos($ang) * 54
                $y2 = 128 + [Math]::Sin($ang) * 54
                $g.DrawLine($pen, $x1, $y1, $x2, $y2)
            }
            $pen.Dispose()
            $inner = New-Object System.Drawing.SolidBrush($WoodDeep)
            $g.FillEllipse($inner, 118, 118, 20, 20)
            $inner.Dispose()
        }
        'power' {
            $pen = New-Object System.Drawing.Pen($colour, 14)
            $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawArc($pen, 94, 94, 68, 68, -60, 300)
            $g.DrawLine($pen, 128, 78, 128, 122)
            $pen.Dispose()
        }
        'expand' {
            $pen = New-Object System.Drawing.Pen($colour, 16)
            $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawLine($pen, 88, 110, 128, 150)
            $g.DrawLine($pen, 128, 150, 168, 110)
            $pen.Dispose()
        }
        'pin' {
            $pen = New-Object System.Drawing.Pen($colour, 12)
            $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawLine($pen, 128, 130, 128, 180)
            $pen.Dispose()
            $p = New-RoundRect 98 76 60 40 8
            $g.FillPath($b, $p); $p.Dispose()
        }
    }
    $b.Dispose()
}

function Build-Button ([string]$baseName, [string]$icon, $colour) {
    foreach ($state in @('normal', 'hot', 'pressed')) {
        $c = New-Canvas 256 256
        Draw-Knob $c.Graphics $state

        $tint = $colour
        if ($state -eq 'hot') {
            $tint = C ([Math]::Min(255, [int]($colour.R * 1.12))) ([Math]::Min(255, [int]($colour.G * 1.12))) ([Math]::Min(255, [int]($colour.B * 1.20)))
        }
        if ($state -eq 'pressed') {
            $tint = C ([int]($colour.R * 0.78)) ([int]($colour.G * 0.78)) ([int]($colour.B * 0.78))
        }
        if ($state -eq 'pressed') { $c.Graphics.TranslateTransform(0, 4) }

        Draw-Icon $c.Graphics $icon $tint $state

        $suffix = switch ($state) { 'normal' { '' } 'hot' { '-hot' } 'pressed' { '-pressed' } }
        Save-Canvas $c "$baseName$suffix.png"
    }
}

Write-Host "Turning the knobs ..." -ForegroundColor DarkYellow

Build-Button 'Play'      'play'    $Amber
Build-Button 'Play-2'    'stop'    $Amber
Build-Button 'Back'      'prev'    $DialCream
Build-Button 'Next'      'next'    $DialCream
Build-Button 'Rec'       'recoff'  (C 226 96 62)
Build-Button 'Rec-2'     'rec'     (C 255 86 52)
Build-Button 'Favorites' 'heart'   (C 232 116 86)
Build-Button 'Mute'      'speaker' $DialCream
Build-Button 'Mute-2'    'mute'    (C 226 96 62)
Build-Button 'Options'   'gear'    $DialCream
Build-Button 'Exit'      'power'   $DialCream
Build-Button 'Expand'    'expand'  $DialCream
Build-Button 'OnTop'     'pin'     $BrassDark
Build-Button 'OnTop-2'   'pin'     $Amber

# --- Filter magnifier ---------------------------------------------------------
$c = New-Canvas 24 24
$pen = New-Object System.Drawing.Pen($DialCream, 2.4)
$c.Graphics.DrawEllipse($pen, 4, 4, 11, 11)
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$c.Graphics.DrawLine($pen, 14, 14, 20, 20)
$pen.Dispose()
Save-Canvas $c 'FilterLabel.png'
Copy-Item (Join-Path $OutDir 'FilterLabel.png') (Join-Path $OutDir 'FilterLabel-hot.png')
Copy-Item (Join-Path $OutDir 'FilterLabel.png') (Join-Path $OutDir 'FilterLabel-pressed.png')

# --- Sources: a brass nameplate -----------------------------------------------
function Build-Sources ([string]$name, $edge, [int]$glow) {
    $c = New-Canvas 1200 256
    $g = $c.Graphics
    $p = New-RoundRect 16 16 1168 224 26
    $rect = New-Object System.Drawing.Rectangle(16, 16, 1168, 224)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $WoodDark, $WoodDeep, 90)
    $g.FillPath($br, $p); $br.Dispose()
    if ($glow -gt 0) { Draw-Glow $g 600 128 400 $Amber $glow }
    $pen = New-Object System.Drawing.Pen($edge, 7)
    $g.DrawPath($pen, $p); $pen.Dispose()
    $pen = New-Object System.Drawing.Pen((C 255 255 255 30), 2)
    $g.DrawLine($pen, 60, 26, 1140, 26); $pen.Dispose()
    $p.Dispose()
    Save-Canvas $c $name
}
Build-Sources 'Sources.png'         $Brass     0
Build-Sources 'Sources-hot.png'     $BrassLite 40
Build-Sources 'sources-pressed.png' $BrassDark 0

# --- Volume: a brass rail with a knurled slider -------------------------------
$c = New-Canvas 140 33
$g = $c.Graphics
$p = New-RoundRect 4 14 132 6 3
$br = New-Object System.Drawing.SolidBrush($WoodDeep)
$g.FillPath($br, $p); $br.Dispose()
$pen = New-Object System.Drawing.Pen($Brass, 1.5)
$g.DrawPath($pen, $p); $pen.Dispose(); $p.Dispose()
$tick = New-Object System.Drawing.SolidBrush((C $Brass.R $Brass.G $Brass.B 170))
for ($x = 8; $x -le 132; $x += 12) { $g.FillRectangle($tick, $x, 24, 2, 5) }
$tick.Dispose()
Save-Canvas $c 'VolumeChannel.png'

function Build-Thumb ([string]$name, $edge, [int]$glow) {
    $c = New-Canvas 22 22
    $g = $c.Graphics
    if ($glow -gt 0) { Draw-Glow $g 11 11 11 $Amber $glow }
    $p = New-RoundRect 5 2 12 18 3
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle(5, 2, 12, 18)), $BrassLite, $BrassDark, 45)
    $g.FillPath($br, $p); $br.Dispose()
    $pen = New-Object System.Drawing.Pen($edge, 1.6)
    $g.DrawPath($pen, $p); $pen.Dispose()
    $line = New-Object System.Drawing.SolidBrush((C 0 0 0 120))
    for ($i = 0; $i -lt 3; $i++) { $g.FillRectangle($line, (8 + $i * 3), 6, 1, 10) }
    $line.Dispose(); $p.Dispose()
    Save-Canvas $c $name
}
Build-Thumb 'VolumeThumb.png'    $BrassDark 0
Build-Thumb 'VolumeThumbHot.png' $BrassLite 110

Write-Host "Building the cabinet ..." -ForegroundColor DarkYellow

# --- The cabinet --------------------------------------------------------------

function Draw-DialStrip ($g, [int]$w, [int]$x, [int]$y, [int]$h) {
    # Backlit glass tuning scale. The scrolling station text rides on top of it,
    # so this stays low-contrast on purpose.
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $DialCream, $DialWarm, 90)
    $g.FillRectangle($br, $rect); $br.Dispose()

    Draw-Glow $g ($x + $w / 2) ($y + $h / 2) ($w * 0.45) $Amber 60

    # Frequency ticks: tall marks every 10, short ones between
    $tickPen  = New-Object System.Drawing.Pen((C 90 58 24 190), 1)
    $tickPen2 = New-Object System.Drawing.Pen((C 90 58 24 110), 1)
    for ($i = 0; $i -le 40; $i++) {
        $tx = $x + 8 + ($i * (($w - 16) / 40.0))
        if ($i % 5 -eq 0) { $g.DrawLine($tickPen,  $tx, ($y + $h - 7), $tx, ($y + $h - 1)) }
        else              { $g.DrawLine($tickPen2, $tx, ($y + $h - 4), $tx, ($y + $h - 1)) }
    }
    $tickPen.Dispose(); $tickPen2.Dispose()

    # Frequency numerals, kept to the right third so they never fight the
    # scrolling station text that RadioSure draws across the left of the dial.
    $nf = New-Object System.Drawing.Font('Consolas', 6, [System.Drawing.FontStyle]::Bold)
    $nb = New-Object System.Drawing.SolidBrush((C 96 60 24 205))
    $freqs = @('92', '96', '100', '104', '108')
    for ($i = 0; $i -lt $freqs.Count; $i++) {
        $fx = $x + $w - 122 + ($i * 24)
        $g.DrawString($freqs[$i], $nf, $nb, $fx, ($y + 2))
    }
    $nf.Dispose(); $nb.Dispose()

    # Brass bezel
    $pen = New-Object System.Drawing.Pen($BrassDark, 2)
    $g.DrawRectangle($pen, $x, $y, $w, $h); $pen.Dispose()
    $pen = New-Object System.Drawing.Pen((C 255 255 255 60), 1)
    $g.DrawLine($pen, ($x + 1), ($y + 1), ($x + $w - 1), ($y + 1)); $pen.Dispose()
}

function Draw-Grille ($g, [int]$x, [int]$y, [int]$w, [int]$h) {
    # The Radiation King's grille is a row of tall cream slots with rounded
    # ends, sunk into the body - not a woven cloth.
    $frame = New-RoundRect $x $y $w $h 6
    $br = New-Object System.Drawing.SolidBrush((C 30 8 7 210))
    $g.FillPath($br, $frame); $br.Dispose()

    $slotW = 7
    $gap   = 11
    $inset = 7
    $sx = $x + $inset
    while ($sx + $slotW -lt $x + $w - $inset + 1) {
        $slot = New-RoundRect $sx ($y + 5) $slotW ($h - 10) ([single]($slotW / 2))
        $rect = New-Object System.Drawing.Rectangle([int]$sx, [int]($y + 5), [int]$slotW, [int]($h - 10))
        $sb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $DialCream, $DialWarm, 90)
        $g.FillPath($sb, $slot); $sb.Dispose()
        $pen = New-Object System.Drawing.Pen((C 0 0 0 90), 1)
        $g.DrawPath($pen, $slot); $pen.Dispose()
        $slot.Dispose()
        $sx += $gap
    }

    $pen = New-Object System.Drawing.Pen($Brass, 2)
    $g.DrawPath($pen, $frame); $pen.Dispose()
    $frame.Dispose()
}

# The script wordmark and its little crown, drawn rather than typed where it
# matters - the crown is three points over a band, like the badge on the set.
function Draw-Crown ($g, [single]$cx, [single]$cy, [single]$w) {
    $h  = $w * 0.62
    $x0 = $cx - $w / 2
    $x1 = $cx - $w / 4
    $x2 = $cx + $w / 4
    $x3 = $cx + $w / 2
    $yT = $cy - $h / 2
    $yB = $cy + $h / 2

    # Built one point at a time: PowerShell flattens nested array literals in
    # ways that are easy to get wrong and hard to see.
    $pts = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    $pts.Add((New-Object System.Drawing.PointF($x0,  $yB)))
    $pts.Add((New-Object System.Drawing.PointF($x0,  $yT)))
    $pts.Add((New-Object System.Drawing.PointF($x1,  $cy)))
    $pts.Add((New-Object System.Drawing.PointF($cx,  $yT)))
    $pts.Add((New-Object System.Drawing.PointF($x2,  $cy)))
    $pts.Add((New-Object System.Drawing.PointF($x3,  $yT)))
    $pts.Add((New-Object System.Drawing.PointF($x3,  $yB)))

    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddPolygon($pts.ToArray())
    $br = New-Object System.Drawing.SolidBrush($BrassLite)
    $g.FillPath($br, $p)
    $br.Dispose(); $p.Dispose()
}

function Draw-VaultBadge ($g, [single]$cx, [single]$cy, [single]$r) {
    # A small round maker's badge. Original artwork - a cog rim with a "V".
    Draw-Glow $g $cx $cy ($r * 1.6) $Amber 50
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle([int]($cx - $r), [int]($cy - $r), [int]($r * 2), [int]($r * 2))),
        $BrassLite, $BrassDark, 60)
    $g.FillEllipse($br, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2)); $br.Dispose()
    $pen = New-Object System.Drawing.Pen($WoodDeep, 1.4)
    $g.DrawEllipse($pen, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2)); $pen.Dispose()
    # Cog teeth
    $tooth = New-Object System.Drawing.Pen($BrassLite, 1.6)
    for ($i = 0; $i -lt 12; $i++) {
        $ang = $i * 30 * [Math]::PI / 180
        $x1 = $cx + [Math]::Cos($ang) * ($r + 0.5)
        $y1 = $cy + [Math]::Sin($ang) * ($r + 0.5)
        $x2 = $cx + [Math]::Cos($ang) * ($r + 2.6)
        $y2 = $cy + [Math]::Sin($ang) * ($r + 2.6)
        $g.DrawLine($tooth, $x1, $y1, $x2, $y2)
    }
    $tooth.Dispose()
    $f = New-Object System.Drawing.Font('Arial', ($r * 1.1), [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $brT = New-Object System.Drawing.SolidBrush($WoodDeep)
    $g.DrawString('V', $f, $brT, $cx, $cy, $sf)
    $f.Dispose(); $sf.Dispose(); $brT.Dispose()
}

function Draw-Cabinet ($g, [int]$w, [int]$h, [bool]$expanded) {

    Draw-Wood $g 0 0 $w $h 4771

    # Cabinet edge and a highlight along the top, as if the light is above
    $edge = New-RoundRect 1.5 1.5 ($w - 3) ($h - 3) 9
    $pen = New-Object System.Drawing.Pen($WoodDeep, 3)
    $g.DrawPath($pen, $edge); $pen.Dispose()
    $pen = New-Object System.Drawing.Pen((C 255 220 170 40), 1.4)
    $g.DrawPath($pen, $edge); $pen.Dispose()
    $edge.Dispose()

    # Tuning dial across the top
    Draw-DialStrip $g ($w - 22) 11 3 20

    if ($expanded) {
        # The station list is the lit dial glass. Brass bezel, warm inner shadow.
        $bez = New-RoundRect 7 49 476 210 5
        $br = New-Object System.Drawing.SolidBrush($DialCream)
        $g.FillPath($br, $bez); $br.Dispose()
        $pen = New-Object System.Drawing.Pen($BrassDark, 4)
        $g.DrawPath($pen, $bez); $pen.Dispose()
        $pen = New-Object System.Drawing.Pen($BrassLite, 1.4)
        $g.DrawPath($pen, $bez); $pen.Dispose()
        $bez.Dispose()
    }

    # Lower control shelf: a brass rail separating dial from controls
    $shelfY = if ($expanded) { 262 } else { 22 }
    $pen = New-Object System.Drawing.Pen($BrassDark, 2)
    $g.DrawLine($pen, 8, ($shelfY - 6), ($w - 8), ($shelfY - 6)); $pen.Dispose()
    $pen = New-Object System.Drawing.Pen((C 255 220 170 34), 1)
    $g.DrawLine($pen, 8, ($shelfY - 5), ($w - 8), ($shelfY - 5)); $pen.Dispose()

    # Slotted grille behind the knob banks, left and right
    $grilleY = if ($expanded) { 297 } else { 57 }
    Draw-Grille $g 5   $grilleY 141 46
    Draw-Grille $g 344 $grilleY 141 46

    # Maker's badge on the shelf, clear of the readouts
    $badgeY = if ($expanded) { 271 } else { 31 }
    Draw-VaultBadge $g 472 $badgeY 8

    # Warm bloom from the dial glass
    Draw-Glow $g ($w / 2) 12 200 $Amber 26
}

function Draw-Wordmark ($g, [int]$w, [bool]$expanded) {
    # Sits in the sliver below the spectrum, the only clear strip left on the
    # expanded face. Script face if the system has one, italic serif if not.
    # The spectrum is 46 tall rather than the stock 56 precisely to clear this;
    # at 56 the bars are drawn straight over the wordmark.
    $y = if ($expanded) { 329 } else { 87 }

    $family = 'Segoe Script'
    $installed = New-Object System.Drawing.Text.InstalledFontCollection
    $has = $false
    foreach ($ff in $installed.Families) { if ($ff.Name -eq $family) { $has = $true } }
    if ($has) { $f = New-Object System.Drawing.Font($family, 7.5, [System.Drawing.FontStyle]::Bold) }
    else      { $f = New-Object System.Drawing.Font('Georgia', 7.5, ([System.Drawing.FontStyle]::Bold -bor [System.Drawing.FontStyle]::Italic)) }

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center

    # Engraved look: a dark offset copy under a bright one
    $dark = New-Object System.Drawing.SolidBrush((C 0 0 0 150))
    $g.DrawString('Radiation King', $f, $dark, 247, ($y + 1), $sf)
    $dark.Dispose()
    $br = New-Object System.Drawing.SolidBrush($BrassLite)
    $g.DrawString('Radiation King', $f, $br, 246, $y, $sf)
    $br.Dispose()

    # Crown beside the wordmark, not above it - there is no vertical room left
    # once the spectrum takes everything down to y=336.
    Draw-Crown $g 196 ($y + 6) 11

    $f.Dispose(); $sf.Dispose()
}

$c = New-Canvas 490 346
Draw-Cabinet $c.Graphics 490 346 $true
Draw-Wordmark $c.Graphics 490 $true
Save-Canvas $c 'Background.png'

$c = New-Canvas 490 100
Draw-Cabinet $c.Graphics 490 100 $false
Draw-Wordmark $c.Graphics 490 $false
Save-Canvas $c 'Background2.png'

# --- Skin picker preview ------------------------------------------------------
$c = New-Canvas 256 195
$g = $c.Graphics
$src = [System.Drawing.Image]::FromFile((Join-Path $OutDir 'Background.png'))
$g.DrawImage($src, 0, 0, 256, 181)
$src.Dispose()
$f = New-Object System.Drawing.Font('Consolas', 12, [System.Drawing.FontStyle]::Bold)
$br = New-Object System.Drawing.SolidBrush($Amber)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString('RADIATION KING', $f, $br, 128, 88, $sf)
$f.Dispose(); $br.Dispose(); $sf.Dispose()
Save-Canvas $c 'SkinPreview.png'

Write-Host "Writing skin.rsn / skin2.rsn ..." -ForegroundColor DarkYellow

function Argb ($c) { return "$($c.A),$($c.R),$($c.G),$($c.B)" }

# Dark ink on the lit dial glass - the list is meant to look printed on it.
$listBg     = Argb $DialCream
$listText   = Argb $InkBrown
$listHi     = Argb (C 176 116 40)
$listHiText = Argb (C 255 246 226)
# Readouts sit on dark bakelite, so they need to be near-cream to stay legible;
# amber alone disappeared against the red.
$readout    = Argb (C 255 236 200)
$readoutDim = Argb (C 240 200 140)
$dialText   = Argb (C 58 34 12)

function Build-SkinXml ([bool]$collapsed) {
    if ($collapsed) {
        $height = 100; $btnY = 63; $bg = 'Background2.png'
        $listVis = 0; $filterVis = 0; $foundVis = 0; $srcVis = 0
        $specY = 40; $infoY = 22; $bufY = 40; $volY = 26
    } else {
        $height = 346; $btnY = 303; $bg = 'Background.png'
        $listVis = 1; $filterVis = 1; $foundVis = 1; $srcVis = 1
        $specY = 280; $infoY = 262; $bufY = 280; $volY = 266
    }

    $btn = {
        param($name, $x, $y, $img, $alt)
        $s = @"
  <$name>
    <x>$x</x>
    <y>$y</y>
    <width>33</width>
    <height>34</height>
    <visible>1</visible>
    <TextColor>-1</TextColor>
    <Image>
      <Normal>$img.png</Normal>
      <Hot>$img-hot.png</Hot>
      <Pressed>$img-pressed.png</Pressed>
    </Image>
"@
        if ($alt) {
            $s += @"

    <AltImage>
      <Normal>$alt.png</Normal>
      <Hot>$alt-hot.png</Hot>
      <Pressed>$alt-pressed.png</Pressed>
    </AltImage>
"@
        }
        $s += "`n  </$name>"
        return $s
    }

    $xml = @"
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<XMLConfigSettings>
  <Window>
    <text>$SkinName</text>
    <!-- Frame 0 drops the Windows title bar so the cabinet is the whole
         window. Verified: the window can still be dragged by any bare part of
         the cabinet, and the power knob still closes it. -->
    <Frame>0</Frame>
    <x>0</x>
    <y>0</y>
    <width>490</width>
    <height>$height</height>
    <Background>$bg</Background>
    <Rounded>0</Rounded>
  </Window>
$(& $btn 'Exit'      451 $btnY 'Exit'      $null)
$(& $btn 'Options'   418 $btnY 'Options'   $null)
$(& $btn 'Mute'      385 $btnY 'Mute'      'Mute-2')
$(& $btn 'Favorites' 352 $btnY 'Favorites' $null)
$(& $btn 'Rec'       108 $btnY 'Rec'       'Rec-2')
$(& $btn 'Next'      75  $btnY 'Next'      $null)
$(& $btn 'Back'      42  $btnY 'Back'      $null)
$(& $btn 'Play'      9   $btnY 'Play'      'Play-2')
  <Sources>
    <x>350</x>
    <y>24</y>
    <width>131</width>
    <height>26</height>
    <visible>$srcVis</visible>
    <TextColor>$readout</TextColor>
    <Image>
      <Normal>Sources.png</Normal>
      <Hot>Sources-hot.png</Hot>
      <Pressed>sources-pressed.png</Pressed>
    </Image>
  </Sources>
  <FilterLabel>
    <x>141</x>
    <y>26</y>
    <width>24</width>
    <height>24</height>
    <visible>$filterVis</visible>
    <TextColor>-1</TextColor>
    <Image>
      <Normal>FilterLabel.png</Normal>
      <Hot>FilterLabel-hot.png</Hot>
      <Pressed>FilterLabel-pressed.png</Pressed>
    </Image>
  </FilterLabel>
  <Filter>
    <x>11</x>
    <y>27</y>
    <width>126</width>
    <height>21</height>
    <visible>$filterVis</visible>
  </Filter>
  <Minimize>
    <x>464</x>
    <y>24</y>
    <width>20</width>
    <height>20</height>
    <visible>0</visible>
    <TextColor>-1</TextColor>
  </Minimize>
  <List>
    <x>11</x>
    <y>53</y>
    <width>468</width>
    <height>202</height>
    <visible>$listVis</visible>
    <TextColor>$listText</TextColor>
    <BkColor>$listBg</BkColor>
    <HighLightColor>$listHi</HighLightColor>
    <HighLightTextColor>$listHiText</HighLightTextColor>
    <Transparent>0</Transparent>
  </List>
  <FoundNumber>
    <TextColor>$readoutDim</TextColor>
    <GlowColor>0,255,255,255</GlowColor>
    <x>165</x>
    <y>30</y>
    <width>168</width>
    <height>13</height>
    <visible>$foundVis</visible>
    <BkColor>0,0,0,0</BkColor>
    <TextSize>13</TextSize>
    <TextAlign>-1</TextAlign>
  </FoundNumber>
  <Spectrum>
    <x>147</x>
    <y>$specY</y>
    <width>200</width>
    <height>46</height>
    <visible>1</visible>
    <BarColorTop>255,255,196,96</BarColorTop>
    <BarColorBottom>255,186,86,26</BarColorBottom>
    <BkColorTop>255,30,12,8</BkColorTop>
    <BkColorBottom>255,12,6,4</BkColorBottom>
    <BarLineColor>190,0,0,0</BarLineColor>
    <Bars>24</Bars>
    <!-- GlassLevel MUST be 0. It paints a pale "glass" sheen over the top of
         the spectrum well, which on a dark cabinet reads as a grey box sitting
         above the bars. The stock skin hides this because its window is the
         same system grey. -->
    <GlassLevel>0</GlassLevel>
    <Frame>0</Frame>
  </Spectrum>
  <BufferInfo>
    <TextColor>$readoutDim</TextColor>
    <GlowColor>0,255,255,255</GlowColor>
    <x>11</x>
    <y>$infoY</y>
    <width>128</width>
    <height>13</height>
    <visible>1</visible>
    <BkColor>0,0,0,0</BkColor>
    <TextSize>13</TextSize>
    <TextAlign>-1</TextAlign>
  </BufferInfo>
  <!-- Hidden on purpose: BufferIndicator is drawn by Windows as a lime green
       progress bar and takes no colour from the skin, which looks wrong on a
       1950s set. BufferInfo above still reports the buffer as a percentage,
       so nothing is actually lost. -->
  <BufferIndicator>
    <x>11</x>
    <y>$bufY</y>
    <width>128</width>
    <height>12</height>
    <visible>0</visible>
  </BufferIndicator>
  <Status>
    <TextColor>$readout</TextColor>
    <GlowColor>0,255,255,255</GlowColor>
    <x>147</x>
    <y>$infoY</y>
    <width>200</width>
    <height>13</height>
    <visible>1</visible>
    <BkColor>0,0,0,0</BkColor>
    <TextSize>13</TextSize>
    <TextAlign>0</TextAlign>
  </Status>
  <Volume>
    <x>348</x>
    <y>$volY</y>
    <width>140</width>
    <height>33</height>
    <visible>1</visible>
    <ThumbSize>22</ThumbSize>
    <ImageThumb>VolumeThumb.png</ImageThumb>
    <ImageThumbHot>VolumeThumbHot.png</ImageThumbHot>
    <ImageChannel>VolumeChannel.png</ImageChannel>
  </Volume>
  <RotatedInfo>
    <TextColor>$dialText</TextColor>
    <GlowColor>-1</GlowColor>
    <x>16</x>
    <y>6</y>
    <width>330</width>
    <height>13</height>
    <visible>1</visible>
    <BkColor>0,0,0,0</BkColor>
    <TextSize>13</TextSize>
    <TextAlign>-1</TextAlign>
  </RotatedInfo>
$(& $btn 'Expand' 464 4 'Expand' $null)
  <SongTitle>
    <TextColor>-1</TextColor>
    <GlowColor>-1</GlowColor>
    <x>0</x>
    <y>0</y>
    <width>0</width>
    <height>0</height>
    <visible>0</visible>
    <BkColor>0,0,0,0</BkColor>
    <TextSize>13</TextSize>
    <TextAlign>-1</TextAlign>
  </SongTitle>
  <OnTop>
    <x>400</x>
    <y>8</y>
    <width>0</width>
    <height>0</height>
    <visible>1</visible>
    <TextColor>-1</TextColor>
    <Image>
      <Normal>OnTop.png</Normal>
      <Hot>OnTop-hot.png</Hot>
      <Pressed>OnTop-pressed.png</Pressed>
    </Image>
    <AltImage>
      <Normal>OnTop-2.png</Normal>
      <Hot>OnTop-2-hot.png</Hot>
      <Pressed>OnTop-2-pressed.png</Pressed>
    </AltImage>
  </OnTop>
  <Author>
    <Name>Radiation King - fan skin. Fallout and Vault-Tec are trademarks of Bethesda Softworks. Original artwork, no game assets.</Name>
    <URL>https://www.radiosure.fr/</URL>
  </Author>
</XMLConfigSettings>
"@
    return $xml
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin.rsn'),  (Build-SkinXml $false), $utf8)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin2.rsn'), (Build-SkinXml $true),  $utf8)

$count = (Get-ChildItem $OutDir -File).Count
Write-Host ""
Write-Host "  Built '$SkinName' - $count files" -ForegroundColor Green
Write-Host "  $OutDir" -ForegroundColor Green
Write-Host ""
