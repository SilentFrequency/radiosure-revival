# Mechanno skin for RadioSure, built by remapping the finished Gramophone skin:
# copy it, replace backgrounds and key art, rewrite every element's geometry
# from a layout table measured on the source render, validate, write to $Stage.
# Geometry is in NATIVE pixels of the 1456x720 render.
param(
    [string]$Src     = "$PSScriptRoot\source\mechanno.jpg",
    [string]$Base    = "$PSScriptRoot\Gramophone.rsn",
    [string]$Stage   = "$PSScriptRoot\Mechanno.rsn",
    [int]$BayDim     = 90,
    [double]$Scale   = 0.60,   # expanded (main player)
    [double]$ScaleC  = 0.60    # collapsed
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$HQ = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
function Col($a, $r, $g, $b) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }

# ================= source clean-up =================
$raw = [System.Drawing.Image]::FromFile($Src)
$clean = New-Object System.Drawing.Bitmap(1456, 720, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($clean); $g.DrawImage($raw, 0, 0, 1456, 720); $g.Dispose(); $raw.Dispose()

# paste $srcRect of $bmp onto $dst with a feathered edge ($fe px), optionally flipped vertically
function Patch($bmp, $sx, $sy, $w, $h, $dx, $dy, $fe, [switch]$FlipV) {
    $piece = $bmp.Clone((New-Object System.Drawing.Rectangle($sx, $sy, $w, $h)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    if ($FlipV) { $piece.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipY) }
    for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
        $d = [Math]::Min([Math]::Min($x, $w - 1 - $x), [Math]::Min($y, $h - 1 - $y))
        $a = [Math]::Min(1.0, ($d + 1) / $fe)
        $c = $piece.GetPixel($x, $y); $piece.SetPixel($x, $y, (Col ([int](255 * $a)) $c.R $c.G $c.B))
    } }
    $q = [System.Drawing.Graphics]::FromImage($bmp); $q.DrawImage($piece, $dx, $dy, $w, $h); $q.Dispose(); $piece.Dispose()
}
# loose nuts, bolts and Allen key in the bay: cover with the scratched board from higher up
Patch $clean 1030 250 210 160 1030 430 24
Patch $clean 1030 300 210 120 1030 385 24
# Gemini star on the bottom-right corner: mirror of the top-right corner
Patch $clean 1360 22 70 62 1360 632 10 -FlipV

# ================= transforms =================
$E = @{ X0 = 0; Y0 = 0; S = $Scale }
$w1 = [int][Math]::Round(1456 * $Scale); $h1 = [int][Math]::Round(720 * $Scale)
function ToWin($t, $a) {
    @([int][Math]::Round(($a[0] - $t.X0) * $t.S), [int][Math]::Round(($a[1] - $t.Y0) * $t.S),
      [int][Math]::Round($a[2] * $t.S), [int][Math]::Round($a[3] * $t.S))
}

# ---- expanded layout: native px ----
# knobs, left to right on the control plate: Play, Rec, Back, Next, Mute.
# Key rect = 1.25x the knob so the lit ring falls just outside the tyre.
function KnobRect($cx, $cy, $r) { $s = 2 * $r * 1.25; @(($cx - $s / 2), ($cy - $s / 2), $s, $s) }
$Knobs = [ordered]@{
    Play = KnobRect 182 603 48; Rec = KnobRect 319 599 40
    Back = KnobRect 459 598 38; Next = KnobRect 594 595 36; Mute = KnobRect 728 601 46
}
$LE = [ordered]@{
    RotatedInfo = 940,98,404,36
    Sources = 940,138,150,26; Filter = 1096,138,138,26; FoundNumber = 1240,138,104,26
    List = 940,174,404,336
    Spectrum = 940,514,404,40
    Status = 940,558,200,24; BufferInfo = 1146,558,198,24
    Volume = 946,588,350,26
}
foreach ($k in $Knobs.Keys) { $LE[$k] = $Knobs[$k] }
# brass nut keys bolted over the top girder's holes (pitch 44, centre y 21.5 native),
# one on every other hole, with a skipped hole between the two groups
function NutRow($holes, $scale, $size) { $o = [ordered]@{}; $i = 0
    foreach ($k in 'Exit', 'Expand', 'Minimize', 'OnTop', 'Options', 'Favorites') {
        $cx = $holes[$i] * $scale; $cy = 21.5 * $scale
        $o[$k] = @([int][Math]::Round($cx - $size / 2), [int][Math]::Round([Math]::Max(0, $cy - $size / 2)), $size, $size); $i++ }
    $o }
$WE = NutRow @(1386, 1298, 1210, 1122, 992, 904) $Scale 26

# ---- collapsed: top girder + display band + control rows, composed in native px ----
$CL = 880; $CR = 1400                  # left part 0..880, right cap 1400..1456
$cwN = $CL + (1456 - $CR)              # 936
$topH = 46; $bandH = 84; $ctlY = 470; $ctlH = 720 - $ctlY
$chN = $topH + $bandH + $ctlH
$cw = [int][Math]::Round($cwN * $ScaleC); $ch = [int][Math]::Round($chN * $ScaleC)
$Cmap = @{ X0 = 0; Y0 = ($ctlY - $topH - $bandH); S = $ScaleC }   # control rows keep native x
$LC = [ordered]@{}; foreach ($k in $Knobs.Keys) { $LC[$k] = $Knobs[$k] }
$bandTop = [int][Math]::Round($topH * $ScaleC); $bandPx = [int][Math]::Round($bandH * $ScaleC)
$WC = NutRow @(860, 772, 685, 598, 466, 378) $ScaleC 26
$nameW = [int]($cw * 0.6)
$WC['RotatedInfo'] = @(40, ($bandTop + [int](($bandPx - 28) / 2)), $nameW, 28)   # 20pt needs >= 1.35x
$WC['Volume'] = @((52 + $nameW), ($bandTop + [int](($bandPx - 20) / 2)), ($cw - 52 - $nameW - 36), 20)
$HideC = 'Sources','Filter','FilterLabel','FoundNumber','List','Status','BufferInfo','BufferIndicator','Spectrum','SongTitle'

# ---- palette (A,R,G,B): warm valve-amber on the black board ----
$Pal = @{
    Title = '255,255,196,104'; Text = '255,238,226,200'; Dim = '255,214,196,156'
    Hi = '255,122,62,20'; HiText = '255,255,226,170'
    BarTop = '235,255,184,80'; BarBot = '30,200,90,20'
}

# ================= build =================
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item "$Base\*" $Stage
Remove-Item "$Stage\SkinPreview.png"

function NewBg($w, $h) {
    $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.Clear((Col 255 20 14 10)); $q.Dispose(); $b
}
# bg1: the whole radio, board smoked a little so the list reads
$b1 = NewBg $w1 $h1; $g = [System.Drawing.Graphics]::FromImage($b1); $g.InterpolationMode = $HQ
$g.DrawImage($clean, 0, 0, $w1, $h1)
$g.FillRectangle((New-Object System.Drawing.SolidBrush((Col $BayDim 4 3 2))), [int](926 * $Scale), [int](90 * $Scale), [int](430 * $Scale), [int](532 * $Scale))
$g.Dispose(); $b1.Save("$Stage\bg1.png", [System.Drawing.Imaging.ImageFormat]::Png)

# bg2: composed in native px, then scaled once
$cn = New-Object System.Drawing.Bitmap($cwN, $chN, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($cn)
function Blit($sx, $sy, $w, $h, $dx, $dy) { $g.DrawImage($clean, (New-Object System.Drawing.Rectangle($dx, $dy, $w, $h)), $sx, $sy, $w, $h, 'Pixel') }
Blit 0 0 $CL $topH 0 0;                       Blit $CR 0 (1456 - $CR) $topH $CL 0
Blit 0 150 50 $bandH 0 $topH;                 Blit 1406 150 50 $bandH ($cwN - 50) $topH
$bw = $cwN - 100; $tile = 400
for ($x = 0; $x -lt $bw; $x += $tile) { $w = [Math]::Min($tile, $bw - $x); Blit 940 110 $w $bandH (50 + $x) $topH }
$g.FillRectangle((New-Object System.Drawing.SolidBrush((Col $BayDim 4 3 2))), 50, $topH, $bw, $bandH)
Blit 0 $ctlY $CL $ctlH 0 ($topH + $bandH);    Blit $CR $ctlY (1456 - $CR) $ctlH $CL ($topH + $bandH)
$g.Dispose()
$b2 = NewBg $cw $ch; $g = [System.Drawing.Graphics]::FromImage($b2); $g.InterpolationMode = $HQ
$g.DrawImage($cn, 0, 0, $cw, $ch); $g.Dispose(); $cn.Dispose()
$b2.Save("$Stage\bg2.png", [System.Drawing.Imaging.ImageFormat]::Png)

$pw = 360; $ph = [int][Math]::Round($pw * $h1 / $w1)
$pv = New-Object System.Drawing.Bitmap($pw, $ph); $g = [System.Drawing.Graphics]::FromImage($pv); $g.InterpolationMode = $HQ
$g.DrawImage($b1, 0, 0, $pw, $ph); $g.Dispose(); $pv.Save("$Stage\SkinPreview.png", [System.Drawing.Imaging.ImageFormat]::Png); $pv.Dispose()
$b1.Dispose(); $b2.Dispose()

# ================= key art (256x256, drawn) =================
function Glyph($q, $kind, $cx, $cy, $s, $brush) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    switch ($kind) {
        'play'  { $path.AddPolygon(@((New-Object System.Drawing.PointF(($cx - 0.38 * $s), ($cy - 0.5 * $s))), (New-Object System.Drawing.PointF(($cx + 0.5 * $s), $cy)), (New-Object System.Drawing.PointF(($cx - 0.38 * $s), ($cy + 0.5 * $s))))) }
        'stop'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.4 * $s), ($cy - 0.4 * $s), (0.8 * $s), (0.8 * $s)))) }
        'rec'   { $path.AddEllipse(($cx - 0.42 * $s), ($cy - 0.42 * $s), (0.84 * $s), (0.84 * $s)) }
        'back'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.5 * $s), ($cy - 0.45 * $s), (0.16 * $s), (0.9 * $s))))
                  $path.AddPolygon(@((New-Object System.Drawing.PointF(($cx + 0.5 * $s), ($cy - 0.45 * $s))), (New-Object System.Drawing.PointF(($cx - 0.3 * $s), $cy)), (New-Object System.Drawing.PointF(($cx + 0.5 * $s), ($cy + 0.45 * $s))))) }
        'next'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx + 0.34 * $s), ($cy - 0.45 * $s), (0.16 * $s), (0.9 * $s))))
                  $path.AddPolygon(@((New-Object System.Drawing.PointF(($cx - 0.5 * $s), ($cy - 0.45 * $s))), (New-Object System.Drawing.PointF(($cx + 0.3 * $s), $cy)), (New-Object System.Drawing.PointF(($cx - 0.5 * $s), ($cy + 0.45 * $s))))) }
        { $_ -in 'mute', 'muted' } {
                  $path.AddPolygon(@((New-Object System.Drawing.PointF(($cx - 0.5 * $s), ($cy - 0.18 * $s))), (New-Object System.Drawing.PointF(($cx - 0.25 * $s), ($cy - 0.18 * $s))), (New-Object System.Drawing.PointF(($cx + 0.08 * $s), ($cy - 0.5 * $s))), (New-Object System.Drawing.PointF(($cx + 0.08 * $s), ($cy + 0.5 * $s))), (New-Object System.Drawing.PointF(($cx - 0.25 * $s), ($cy + 0.18 * $s))), (New-Object System.Drawing.PointF(($cx - 0.5 * $s), ($cy + 0.18 * $s))))) }
        'minus' { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.45 * $s), ($cy - 0.1 * $s), (0.9 * $s), (0.2 * $s)))) }
        'pin'   { $path.AddEllipse(($cx - 0.22 * $s), ($cy - 0.5 * $s), (0.44 * $s), (0.44 * $s)); $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.06 * $s), ($cy - 0.1 * $s), (0.12 * $s), (0.6 * $s)))) }
        'heart' { $path.AddArc(($cx - 0.5 * $s), ($cy - 0.45 * $s), (0.52 * $s), (0.52 * $s), 150, 210); $path.AddArc(($cx - 0.02 * $s), ($cy - 0.45 * $s), (0.52 * $s), (0.52 * $s), 180, 210); $path.AddLine(($cx + 0.46 * $s), ($cy - 0.02 * $s), $cx, ($cy + 0.5 * $s)); $path.CloseFigure() }
        'cog'   { for ($i = 0; $i -lt 8; $i++) { $m = New-Object System.Drawing.Drawing2D.Matrix; $m.RotateAt(45 * $i, (New-Object System.Drawing.PointF($cx, $cy)))
                      $t = New-Object System.Drawing.Drawing2D.GraphicsPath; $t.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.12 * $s), ($cy - 0.52 * $s), (0.24 * $s), (0.3 * $s)))); $t.Transform($m); $path.AddPath($t, $false) } }
    }
    $path.FillMode = 'Winding'; $q.FillPath($brush, $path)
    # cog body is a thick ring, so the centre hole shows the nut face through it
    if ($kind -eq 'cog') { $pen = New-Object System.Drawing.Pen($brush, (0.2 * $s)); $q.DrawEllipse($pen, ($cx - 0.28 * $s), ($cy - 0.28 * $s), (0.56 * $s), (0.56 * $s)) }
    if ($kind -eq 'muted') { $pen = New-Object System.Drawing.Pen($brush, (0.13 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
        $q.DrawLine($pen, ($cx + 0.22 * $s), ($cy - 0.22 * $s), ($cx + 0.52 * $s), ($cy + 0.22 * $s)); $q.DrawLine($pen, ($cx + 0.52 * $s), ($cy - 0.22 * $s), ($cx + 0.22 * $s), ($cy + 0.22 * $s)) }
    if ($kind -eq 'chev') { $pen = New-Object System.Drawing.Pen($brush, (0.16 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
        $q.DrawLines($pen, @((New-Object System.Drawing.PointF(($cx - 0.4 * $s), ($cy - 0.18 * $s))), (New-Object System.Drawing.PointF($cx, ($cy + 0.22 * $s))), (New-Object System.Drawing.PointF(($cx + 0.4 * $s), ($cy - 0.18 * $s))))) }
    if ($kind -eq 'power') { $pen = New-Object System.Drawing.Pen($brush, (0.14 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
        $q.DrawArc($pen, ($cx - 0.4 * $s), ($cy - 0.36 * $s), (0.8 * $s), (0.8 * $s), -60, 300); $q.DrawLine($pen, $cx, ($cy - 0.5 * $s), $cx, ($cy - 0.02 * $s)) }
}
function Save256($b, $name) { $b.Save("$Stage\$name.png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose() }
function New256 { $b = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.SmoothingMode = 'AntiAlias'; $q.Clear([System.Drawing.Color]::Transparent); @($b, $q) }
# soft ring just outside the tyre (radius 0.8..1.0 of the half-rect)
function Ring($q, $rgb, $peak) {
    for ($i = 0; $i -lt 26; $i++) { $rr = 102 + $i; $t = 1 - [Math]::Abs($i - 7) / 19.0; if ($t -le 0) { continue }
        $pen = New-Object System.Drawing.Pen((Col ([int]($peak * $t)) $rgb[0] $rgb[1] $rgb[2]), 1.6); $q.DrawEllipse($pen, (128 - $rr), (128 - $rr), (2 * $rr), (2 * $rr)) }
}
# deep valve-orange: plain amber vanished on the yellow plate
$Amber = 255, 118, 14; $Red = 255, 56, 40
# stamped: dark glyph with a light lip below-right, as if punched into the cap
function Stamp($q, $kind, $size, $dy, $ink) {
    Glyph $q $kind 131 (131 + $dy) $size (New-Object System.Drawing.SolidBrush((Col 110 255 236 190)))
    Glyph $q $kind 128 (128 + $dy) $size (New-Object System.Drawing.SolidBrush($ink))
}
function Knob($name, $kind, $ringRgb, $lit) {
    # lit = the "on" state of a toggle (like the Deluxe jewels): ring glows at rest too
    $restRing = if ($lit) { 230 } else { 0 }
    $inkRest = if ($lit) { Col 255 ($ringRgb[0]) ($ringRgb[1]) ($ringRgb[2]) } else { Col 225 34 24 16 }
    $b, $q = New256; if ($lit) { Ring $q $ringRgb $restRing }; Stamp $q $kind 72 0 $inkRest; $q.Dispose(); Save256 $b $name
    $b, $q = New256; Ring $q $ringRgb 255; Stamp $q $kind 76 0 (Col 255 255 214 130); $q.Dispose(); Save256 $b "$name-hot"
    $b, $q = New256; Ring $q $ringRgb 150; Stamp $q $kind 70 5 (Col 255 150 96 40); $q.Dispose(); Save256 $b "$name-pressed"
}
Knob 'Play'  'play'  $Amber $false;  Knob 'Play-2' 'stop'  $Amber $true
Knob 'Mute'  'mute'  $Amber $false;  Knob 'Mute-2' 'muted' $Red   $true
Knob 'Rec'   'rec'   $Red   $false;  Knob 'Rec-2'  'rec'   $Red   $true
Knob 'Back'  'back'  $Amber $false;  Knob 'Next'   'next'  $Amber $false

# brass hex nut with a stamped glyph
function NutKey($name, $kind, $lit) {
    foreach ($st in '', '-hot', '-pressed') {
        $b, $q = New256
        # drop shadow first, so the nut stands proud of the yellow girder
        for ($i = 6; $i -ge 1; $i--) {
            $sp = 0..5 | ForEach-Object { $a = [Math]::PI / 3 * $_ + [Math]::PI / 6; New-Object System.Drawing.PointF((136 + (100 + 2 * $i) * [Math]::Cos($a)), (138 + (100 + 2 * $i) * [Math]::Sin($a))) }
            $q.FillPolygon((New-Object System.Drawing.SolidBrush((Col 34 30 16 4))), $sp) }
        $pts = 0..5 | ForEach-Object { $a = [Math]::PI / 3 * $_ + [Math]::PI / 6; New-Object System.Drawing.PointF((126 + 100 * [Math]::Cos($a)), (124 + 100 * [Math]::Sin($a))) }
        $top = if ($st -eq '-pressed') { Col 255 128 96 44 } elseif ($st -eq '-hot') { Col 255 246 206 120 } else { Col 255 196 150 70 }
        $bot = if ($st -eq '-pressed') { Col 255 72 50 20 } else { Col 255 104 70 26 }
        $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0, 0, 256, 256)), $top, $bot, 60)
        $edge = if ($st -eq '-hot' -or $lit) { Col 255 255 118 14 } else { Col 255 58 38 14 }
        $q.FillPolygon($gb, $pts); $q.DrawPolygon((New-Object System.Drawing.Pen($edge, 14)), $pts)
        $q.DrawEllipse((New-Object System.Drawing.Pen((Col 120 70 48 20), 5)), 48, 46, 156, 156)
        $ink = if ($lit) { Col 255 200 40 20 } else { Col 240 48 32 16 }
        Stamp $q $kind 120 ($(if ($st -eq '-pressed') { 4 } else { 0 })) $ink
        $q.Dispose(); Save256 $b "$name$st"
    }
}
NutKey 'Exit' 'power' $false; NutKey 'Expand' 'chev' $false; NutKey 'Minimize' 'minus' $false
NutKey 'OnTop' 'pin' $false;  NutKey 'OnTop-2' 'pin' $true
NutKey 'Favorites' 'heart' $false; NutKey 'Options' 'cog' $false

# volume thumb: a nut riding in the channel
foreach ($st in @(@('VolumeThumb', 0), @('VolumeThumbHot', 1))) {
    $b = New-Object System.Drawing.Bitmap(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.SmoothingMode = 'AntiAlias'; $q.Clear([System.Drawing.Color]::Transparent)
    $pts = 0..5 | ForEach-Object { $a = [Math]::PI / 3 * $_; New-Object System.Drawing.PointF((32 + 29 * [Math]::Cos($a)), (32 + 29 * [Math]::Sin($a))) }
    $hi = if ($st[1]) { Col 255 255 222 140 } else { Col 255 222 190 112 }
    $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0, 0, 64, 64)), $hi, (Col 255 124 90 40), 60)
    $q.FillPolygon($gb, $pts); $q.DrawPolygon((New-Object System.Drawing.Pen((Col 255 70 50 24), 2.5)), $pts)
    $q.FillEllipse((New-Object System.Drawing.SolidBrush((Col 255 40 28 14))), 21, 21, 22, 22)
    $q.DrawEllipse((New-Object System.Drawing.Pen((Col 255 150 112 50), 2)), 21, 21, 22, 22)
    $q.Dispose(); $b.Save("$Stage\$($st[0]).png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
# Sources: bare at rest, a brass underline on hover
foreach ($st in @(@('Sources', 0), @('Sources-hot', 170), @('sources-pressed', 110))) {
    $b = New-Object System.Drawing.Bitmap(210, 42, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.Clear([System.Drawing.Color]::Transparent)
    if ($st[1]) { $q.FillRectangle((New-Object System.Drawing.SolidBrush((Col $st[1] 255 176 64))), 10, 36, 190, 3) }
    $q.Dispose(); $b.Save("$Stage\$($st[0]).png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
$clean.Dispose()

# ================= XML =================
function Set-Tag([ref]$xml, $el, $tag, $val) {
    $re = "(?s)(<$el>.*?<$tag>)[^<]*(</$tag>)"
    if ([regex]::IsMatch($xml.Value, $re)) { $xml.Value = [regex]::Replace($xml.Value, $re, "`${1}$val`${2}", 1) }
    elseif ($xml.Value -match "<$el>") { $xml.Value = [regex]::Replace($xml.Value, "(<$el>)", "`${1}<$tag>$val</$tag>", 1) }
    else { throw "element $el missing" }
}
function Place([ref]$xml, $el, $r) { Set-Tag $xml $el 'x' $r[0]; Set-Tag $xml $el 'y' $r[1]; Set-Tag $xml $el 'width' $r[2]; Set-Tag $xml $el 'height' $r[3]; Set-Tag $xml $el 'visible' 1 }
function Style([ref]$xml) {
    Set-Tag $xml 'Window' 'text' 'Mechanno'
    Set-Tag $xml 'Window' 'Rounded' 0
    Set-Tag $xml 'Author' 'Name' 'Claude - Mechanno, Nano Banana art'
    Set-Tag $xml 'RotatedInfo' 'TextColor' $Pal.Title
    foreach ($e in 'Sources', 'FoundNumber') { Set-Tag $xml $e 'TextColor' $Pal.Title }
    foreach ($e in 'Status', 'BufferInfo') { Set-Tag $xml $e 'TextColor' $Pal.Dim }
    Set-Tag $xml 'List' 'TextColor' $Pal.Text; Set-Tag $xml 'List' 'HighLightColor' $Pal.Hi; Set-Tag $xml 'List' 'HighLightTextColor' $Pal.HiText
    Set-Tag $xml 'Spectrum' 'BarColorTop' $Pal.BarTop; Set-Tag $xml 'Spectrum' 'BarColorBottom' $Pal.BarBot
}
$enc = New-Object System.Text.UTF8Encoding($false)

$x1 = [IO.File]::ReadAllText("$Base\skin.rsn")
Set-Tag ([ref]$x1) 'Window' 'width' $w1; Set-Tag ([ref]$x1) 'Window' 'height' $h1
$TSE = @{ RotatedInfo = 15; Status = 12; BufferInfo = 12; FoundNumber = 12; Sources = 9 }
$MinH = @{ Filter = 20; Volume = 20 }
foreach ($k in $LE.Keys) {
    $r = ToWin $E $LE[$k]
    if ($TSE.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], [int][Math]::Ceiling(1.35 * $TSE[$k])); Set-Tag ([ref]$x1) $k 'TextSize' $TSE[$k] }
    if ($MinH.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], $MinH[$k]) }
    Place ([ref]$x1) $k $r
}
foreach ($k in $WE.Keys) { Place ([ref]$x1) $k $WE[$k] }
Set-Tag ([ref]$x1) 'Volume' 'ThumbSize' 18
Style ([ref]$x1)
[IO.File]::WriteAllText("$Stage\skin.rsn", $x1, $enc)

$x2 = [IO.File]::ReadAllText("$Base\skin2.rsn")
Set-Tag ([ref]$x2) 'Window' 'width' $cw; Set-Tag ([ref]$x2) 'Window' 'height' $ch
foreach ($k in $LC.Keys) { Place ([ref]$x2) $k (ToWin $Cmap $LC[$k]) }
foreach ($k in $WC.Keys) { Place ([ref]$x2) $k $WC[$k] }
foreach ($k in $HideC) { if ($x2 -match "<$k>") { Set-Tag ([ref]$x2) $k 'visible' 0 } }
Set-Tag ([ref]$x2) 'RotatedInfo' 'TextSize' 20
Set-Tag ([ref]$x2) 'Volume' 'ThumbSize' 18
Style ([ref]$x2)
[IO.File]::WriteAllText("$Stage\skin2.rsn", $x2, $enc)

# ---- validate: every visible element inside its window, no overlaps ----
$bad = 0
foreach ($f in @(@('skin.rsn', $w1, $h1), @('skin2.rsn', $cw, $ch))) {
    [xml]$x = Get-Content "$Stage\$($f[0])" -Raw
    $els = @($x.XMLConfigSettings.ChildNodes | Where-Object { $_.visible -eq '1' -and $_.width })
    foreach ($e in $els) {
        $ex = [int]$e.x; $ey = [int]$e.y; $ew = [int]$e.width; $eh = [int]$e.height
        if ($ex -lt 0 -or $ey -lt 0 -or ($ex + $ew) -gt $f[1] -or ($ey + $eh) -gt $f[2]) { "OUT  $($f[0]) $($e.Name) $ex,$ey ${ew}x$eh"; $bad++ }
        foreach ($o in $els) {
            if ($o.Name -le $e.Name) { continue }
            $ox = [int]$o.x; $oy = [int]$o.y
            if ($ex -lt ($ox + [int]$o.width) -and $ox -lt ($ex + $ew) -and $ey -lt ($oy + [int]$o.height) -and $oy -lt ($ey + $eh)) { "OVER $($f[0]) $($e.Name) x $($o.Name)"; $bad++ }
        }
        foreach ($n in $e.SelectNodes('.//*[contains(., ".png")]')) { if ($n.ChildNodes.Count -eq 1 -and -not (Test-Path "$Stage\$($n.InnerText)")) { "MISSING $($n.InnerText)"; $bad++ } }
    }
    foreach ($m in [regex]::Matches((Get-Content "$Stage\$($f[0])" -Raw), '<(\w+)></\1>')) { "EMPTY $($f[0]) <$($m.Groups[1].Value)>"; $bad++ }
    "{0}: {1} visible elements" -f $f[0], $els.Count
}
"expanded ${w1}x${h1}, collapsed ${cw}x${ch}; problems: $bad"
