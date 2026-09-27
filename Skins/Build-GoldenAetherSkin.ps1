# Golden Aether skin for RadioSure. The radio from VisionFX render #2 is composited, larger,
# into the clean Nano Banana scene (stone wall, gold-framed glass panel, desk), then the
# finished Mechanno skin is remapped onto it: new backgrounds, new key art, new geometry.
# Geometry is in SCENE px of the 1376x768 composite.
param(
    [string]$Scene  = "$PSScriptRoot\source\golden-aether-scene.jpg",
    [string]$Radio  = "$PSScriptRoot\source\golden-aether-radio.png",
    [string]$Base   = "$PSScriptRoot\Mechanno.rsn",
    [string]$Stage  = "$PSScriptRoot\Golden Aether.rsn",
    [double]$Scale  = 0.72,   # expanded
    [double]$ScaleC = 0.60,   # collapsed
    [int]$ScreenDim = 120,    # smoke over the radio's gold screen so the spectrum reads
    [double]$RK = 0.75,       # radio size against its source render
    [int]$PanelL = -1,        # glass panel left edge; -1 = just clear of the radio's right edge
    [int]$PanelR = 1380       # ... and widened to here (past 1376 the wall is padded by mirroring)
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$HQ = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
function Col($a, $r, $g, $b) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function Pt($x, $y) { New-Object System.Drawing.PointF($x, $y) }

# ================= composite =================
$SW = [Math]::Max(1376, $PanelR + 24)
$comp = New-Object System.Drawing.Bitmap($SW, 768, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$raw = [System.Drawing.Image]::FromFile($Scene)
$g = [System.Drawing.Graphics]::FromImage($comp); $g.DrawImage($raw, 0, 0, 1376, 768); $raw.Dispose()
if ($SW -gt 1376) {   # pad the stone wall on the right with its own mirror image
    $pad = $comp.Clone((New-Object System.Drawing.Rectangle((1376 - ($SW - 1376)), 0, ($SW - 1376), 768)), $comp.PixelFormat)
    $pad.RotateFlip('RotateNoneFlipX'); $g.DrawImage($pad, 1376, 0, ($SW - 1376), 768); $pad.Dispose()
}
$RL = 40; $rR = $RL + [int](948 * $RK)
if ($PanelL -lt 0) { $PanelL = $rR + 6 }
# ---- widen the glass panel: cut at two plain slices either side of the top ornament and stretch
#      only those, so gears and medallions keep their shape; then move it left to the radio ----
$P0 = 855; $P1 = 1287; $PT = 12; $PB = 592; $PW = $P1 - $P0
$Sl = 1025, 1050; $Sr = 1105, 1130     # the horizontal pipes either side of the top-bar centre piece
$D = ($PanelR - $PanelL) - $PW; $dl = [Math]::Floor($D / 2); $dr = $D - $dl
function PanelX($x) { if ($x -le $Sl[0]) { $PanelL + ($x - $P0) } elseif ($x -le $Sr[0]) { $PanelL + ($x - $P0) + $dl } else { $PanelL + ($x - $P0) + $dl + $dr } }
$pan = $comp.Clone((New-Object System.Drawing.Rectangle($P0, $PT, $PW, ($PB - $PT))), $comp.PixelFormat)
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
$dx = $PanelL
foreach ($pc in @(@($P0, $Sl[0], ($Sl[0] - $P0)), @($Sl[0], $Sl[1], ($Sl[1] - $Sl[0] + $dl)), @($Sl[1], $Sr[0], ($Sr[0] - $Sl[1])), @($Sr[0], $Sr[1], ($Sr[1] - $Sr[0] + $dr)), @($Sr[1], $P1, ($P1 - $Sr[1])))) {
    # 1:1 pieces copy pixel for pixel; stretched pieces are smoothed (pixel copy turns pipes blocky and the
    # glass reflection into stair-steps), with mirrored edge sampling so the smoothing cannot fade the edges
    $stretch = $pc[2] -ne ($pc[1] - $pc[0])
    $g.InterpolationMode = if ($stretch) { 'HighQualityBicubic' } else { 'NearestNeighbor' }
    $ia = New-Object System.Drawing.Imaging.ImageAttributes; $ia.SetWrapMode('TileFlipXY')
    $g.DrawImage($pan, (New-Object System.Drawing.Rectangle($dx, $PT, $pc[2], ($PB - $PT))), ($pc[0] - $P0), 0, ($pc[1] - $pc[0]), ($PB - $PT), 'Pixel', $ia); $dx += $pc[2]
}
$pan.Dispose(); $g.PixelOffsetMode = 'Default'
$rad = [System.Drawing.Bitmap]::FromFile($Radio)
# radio silhouette in RADIO px: chamfered body, two top rails, four feet
$sil = New-Object System.Drawing.Drawing2D.GraphicsPath
$sil.AddPolygon(@((Pt 240 175), (Pt 1128 176), (Pt 1159 203), (Pt 1157 572), (Pt 1123 600), (Pt 240 598), (Pt 212 573), (Pt 212 203)))
$sil.AddPolygon(@((Pt 440 176), (Pt 444 170), (Pt 628 169), (Pt 634 176)))
$sil.AddPolygon(@((Pt 785 176), (Pt 792 169), (Pt 924 169), (Pt 931 176)))
foreach ($fx in 280, 445, 900, 1080) { $sil.AddRectangle((New-Object System.Drawing.RectangleF($fx, 596, 50, 20))) }
$sil.FillMode = 'Winding'
$RT = 670 - [int](448 * $RK)    # radio top-left in the scene; feet stay on the desk at 670
# the small radio's feet would peek under the new body: clone clean desk rows over them
$strip = $comp.Clone((New-Object System.Drawing.Rectangle(140, 676, 600, 26)), $comp.PixelFormat)
$g.DrawImage($strip, 140, 648, 600, 26); $strip.Dispose()
$nw = [int](948 * $RK)
for ($i = 0; $i -lt 14; $i++) {
    $g.FillEllipse((New-Object System.Drawing.SolidBrush((Col ([int](70 * (1 - $i / 14.0))) 8 5 2))), ($RL - 10 - 2 * $i), (660 - $i / 2), ($nw + 20 + 4 * $i), (20 + $i))
}
$m = New-Object System.Drawing.Drawing2D.Matrix; $m.Translate($RL, $RT); $m.Scale($RK, $RK); $m.Translate(-212, -169)
$sil.Transform($m)
$g.InterpolationMode = $HQ; $g.SmoothingMode = 'AntiAlias'
$tex = New-Object System.Drawing.TextureBrush($rad); $tex.Transform = $m
$g.FillPath($tex, $sil); $rad.Dispose()
# radio px -> scene px, for measuring features on the sharp source
function RadioToScene($x, $y) { @(($RL + ($x - 212) * $RK), ($RT + ($y - 169) * $RK)) }
$scr = RadioToScene 578 322
$g.FillRectangle((New-Object System.Drawing.SolidBrush((Col $ScreenDim 14 8 2))), $scr[0], $scr[1], (206 * $RK), (172 * $RK))
# Status window: the left slot's interior is pale chrome swirl, which drowns the text. Paint a real dark display
# inside the slot only (it once ran left over the bezel and clipped the Options knob), with a thin bronze rim.
$SW0 = RadioToScene 403 222; $SWw = (518 - 403) * $RK; $SWh = (252 - 222) * $RK
$win = New-Object System.Drawing.Drawing2D.GraphicsPath; $winR = 4 * $RK * 1.5
$win.AddArc($SW0[0], $SW0[1], 2 * $winR, 2 * $winR, 180, 90); $win.AddArc(($SW0[0] + $SWw - 2 * $winR), $SW0[1], 2 * $winR, 2 * $winR, 270, 90)
$win.AddArc(($SW0[0] + $SWw - 2 * $winR), ($SW0[1] + $SWh - 2 * $winR), 2 * $winR, 2 * $winR, 0, 90); $win.AddArc($SW0[0], ($SW0[1] + $SWh - 2 * $winR), 2 * $winR, 2 * $winR, 90, 90); $win.CloseFigure()
$gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.RectangleF($SW0[0], $SW0[1], $SWw, $SWh)), (Col 250 6 4 2), (Col 250 26 16 6), 90.0)
$g.FillPath($gb, $win)
$g.DrawPath((New-Object System.Drawing.Pen((Col 230 150 104 40), 1.6)), $win)
$g.Dispose()

# ================= layout (scene px) =================
function KeyAt($x, $y, $r) { $c = RadioToScene $x $y; $s = 2 * $r * $RK * 1.25; @(($c[0] - $s / 2), ($c[1] - $s / 2), $s, $s) }
function Box($x, $y, $w, $h) { $c = RadioToScene $x $y; @($c[0], $c[1], ($w * $RK), ($h * $RK)) }
$Keys = [ordered]@{
    Play = KeyAt 370 393 46; Mute = KeyAt 1005 398 46   # centred on the speaker caps (re-measured on the source)
    Rec = KeyAt 360 515 32; Back = KeyAt 465 512 32; Next = KeyAt 890 515 32; OnTop = KeyAt 1000 515 32
    Favorites = KeyAt 282 235 20; Options = KeyAt 350 235 16; Minimize = KeyAt 960 235 18; Exit = KeyAt 1080 232 20
}
# compact/expand: a copy of the Minimise knob mounted over the dark slot between the Minimise and Exit knobs
$Keys['Expand'] = KeyAt 1016 233 20   # nudged by eye: up 3px, right 2px (window)
$OnRadio = [ordered]@{
    Sources = Box 562 214 202 36; Status = Box 406 223 110 28; BufferInfo = Box 810 220 110 26
    # Spectrum fills the whole screen. Tried with its floor on the glowing line at source y 452; he preferred full ("more is more")
    Spectrum = Box 584 328 194 160; Volume = Box 614 553 216 24
}
# the glass: 925..1218 wide above y 230 and below 460, 945..1198 at the waist between
$Glass = [ordered]@{
    RotatedInfo = @((PanelX 944), 95, ((PanelX 1200) - (PanelX 944)), 24)
    List        = @((PanelX 946), 130, ((PanelX 1198) - (PanelX 946)), 412)
    FoundNumber = @((PanelX 938), 550, 110, 22); Filter = @((PanelX 1054), 550, ((PanelX 1204) - (PanelX 1054)), 22)
}
$Crop  = @{ X0 = 20; Y0 = 8; W = ($PanelR + 17 - 20); H = 682 }   # expanded: radio and panel
$CropC = @{ X0 = 30; Y0 = ($RT - 62); W = ($rR + 11 - 30); H = (690 - $RT + 62) }   # collapsed: radio alone, a strip of wall above it
$NameC = @(60, ($RT - 54), ($rR - 90), 46)                           # collapsed station name, on the wall

# ---- palette (A,R,G,B) ----
$Pal = @{
    Title = '255,255,212,128'; Text = '255,236,222,194'; Dim = '255,214,186,120'
    Ink = '255,46,28,8'                                 # dark bronze, for text on bright gold or lit stone
    Hi = '255,120,80,20'; HiText = '255,255,236,190'
    BarTop = '240,255,236,170'; BarBot = '36,255,170,60'
}

# ================= build =================
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item "$Base\*" $Stage
Remove-Item "$Stage\SkinPreview.png" -ErrorAction SilentlyContinue

function Render($crop, $s, $file) {
    $w = [int][Math]::Round($crop.W * $s); $h = [int][Math]::Round($crop.H * $s)
    $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.InterpolationMode = $HQ; $q.PixelOffsetMode = 'HighQuality'
    $q.DrawImage($comp, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), $crop.X0, $crop.Y0, $crop.W, $crop.H, 'Pixel'); $q.Dispose()
    # seal the edge: opaque all round, so no pale fringe
    for ($x = 0; $x -lt $w; $x++) { foreach ($y in 0, ($h - 1)) { $c = $b.GetPixel($x, $y); $b.SetPixel($x, $y, (Col 255 $c.R $c.G $c.B)) } }
    for ($y = 0; $y -lt $h; $y++) { foreach ($x in 0, ($w - 1)) { $c = $b.GetPixel($x, $y); $b.SetPixel($x, $y, (Col 255 $c.R $c.G $c.B)) } }
    $b.Save("$Stage\$file", [System.Drawing.Imaging.ImageFormat]::Png); $b
}
$b1 = Render $Crop $Scale 'bg1.png'; $w1 = $b1.Width; $h1 = $b1.Height
$b2 = Render $CropC $ScaleC 'bg2.png'; $cw = $b2.Width; $ch = $b2.Height
$pw = 360; $ph = [int][Math]::Round($pw * $h1 / $w1)
$pv = New-Object System.Drawing.Bitmap($pw, $ph); $q = [System.Drawing.Graphics]::FromImage($pv); $q.InterpolationMode = $HQ
$q.DrawImage($b1, 0, 0, $pw, $ph); $q.Dispose(); $pv.Save("$Stage\SkinPreview.png", [System.Drawing.Imaging.ImageFormat]::Png); $pv.Dispose()
$b1.Dispose(); $b2.Dispose(); $comp.Dispose()

function ToWin($crop, $s, $r) {
    @([int][Math]::Round(($r[0] - $crop.X0) * $s), [int][Math]::Round(($r[1] - $crop.Y0) * $s),
      [int][Math]::Round($r[2] * $s), [int][Math]::Round($r[3] * $s))
}

# ================= key art (256x256, drawn) =================
# The radio's own knobs and speakers are the buttons, so keys are transparent: a glowing glyph,
# a ring of light on hover, and toggles lit at rest when on (the Deluxe jewels).
function Glyph($q, $kind, $cx, $cy, $s, $brush) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    switch ($kind) {
        'play'  { $path.AddPolygon(@((Pt ($cx - 0.38 * $s) ($cy - 0.5 * $s)), (Pt ($cx + 0.5 * $s) $cy), (Pt ($cx - 0.38 * $s) ($cy + 0.5 * $s)))) }
        'stop'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.4 * $s), ($cy - 0.4 * $s), (0.8 * $s), (0.8 * $s)))) }
        'rec'   { $path.AddEllipse(($cx - 0.42 * $s), ($cy - 0.42 * $s), (0.84 * $s), (0.84 * $s)) }
        'back'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.5 * $s), ($cy - 0.45 * $s), (0.16 * $s), (0.9 * $s))))
                  $path.AddPolygon(@((Pt ($cx + 0.5 * $s) ($cy - 0.45 * $s)), (Pt ($cx - 0.3 * $s) $cy), (Pt ($cx + 0.5 * $s) ($cy + 0.45 * $s)))) }
        'next'  { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx + 0.34 * $s), ($cy - 0.45 * $s), (0.16 * $s), (0.9 * $s))))
                  $path.AddPolygon(@((Pt ($cx - 0.5 * $s) ($cy - 0.45 * $s)), (Pt ($cx + 0.3 * $s) $cy), (Pt ($cx - 0.5 * $s) ($cy + 0.45 * $s)))) }
        { $_ -in 'mute', 'muted' } {
                  $path.AddPolygon(@((Pt ($cx - 0.5 * $s) ($cy - 0.18 * $s)), (Pt ($cx - 0.25 * $s) ($cy - 0.18 * $s)), (Pt ($cx + 0.08 * $s) ($cy - 0.5 * $s)), (Pt ($cx + 0.08 * $s) ($cy + 0.5 * $s)), (Pt ($cx - 0.25 * $s) ($cy + 0.18 * $s)), (Pt ($cx - 0.5 * $s) ($cy + 0.18 * $s)))) }
        'minus' { $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.45 * $s), ($cy - 0.1 * $s), (0.9 * $s), (0.2 * $s)))) }
        'pin'   { $path.AddEllipse(($cx - 0.22 * $s), ($cy - 0.5 * $s), (0.44 * $s), (0.44 * $s)); $path.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.06 * $s), ($cy - 0.1 * $s), (0.12 * $s), (0.6 * $s)))) }
        'heart' { $path.AddArc(($cx - 0.5 * $s), ($cy - 0.45 * $s), (0.52 * $s), (0.52 * $s), 150, 210); $path.AddArc(($cx - 0.02 * $s), ($cy - 0.45 * $s), (0.52 * $s), (0.52 * $s), 180, 210); $path.AddLine(($cx + 0.46 * $s), ($cy - 0.02 * $s), $cx, ($cy + 0.5 * $s)); $path.CloseFigure() }
        'cog'   { for ($i = 0; $i -lt 8; $i++) { $mm = New-Object System.Drawing.Drawing2D.Matrix; $mm.RotateAt(45 * $i, (Pt $cx $cy))
                      $t = New-Object System.Drawing.Drawing2D.GraphicsPath; $t.AddRectangle((New-Object System.Drawing.RectangleF(($cx - 0.12 * $s), ($cy - 0.52 * $s), (0.24 * $s), (0.3 * $s)))); $t.Transform($mm); $path.AddPath($t, $false) } }
    }
    $path.FillMode = 'Winding'; $q.FillPath($brush, $path)
    if ($kind -eq 'cog') { $pen = New-Object System.Drawing.Pen($brush, (0.2 * $s)); $q.DrawEllipse($pen, ($cx - 0.28 * $s), ($cy - 0.28 * $s), (0.56 * $s), (0.56 * $s)) }
    if ($kind -eq 'muted') { $pen = New-Object System.Drawing.Pen($brush, (0.13 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
        $q.DrawLine($pen, ($cx + 0.22 * $s), ($cy - 0.22 * $s), ($cx + 0.52 * $s), ($cy + 0.22 * $s)); $q.DrawLine($pen, ($cx + 0.52 * $s), ($cy - 0.22 * $s), ($cx + 0.22 * $s), ($cy + 0.22 * $s)) }
    if ($kind -eq 'chev') { $pen = New-Object System.Drawing.Pen($brush, (0.16 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
        $q.DrawLines($pen, @((Pt ($cx - 0.4 * $s) ($cy - 0.18 * $s)), (Pt $cx ($cy + 0.22 * $s)), (Pt ($cx + 0.4 * $s) ($cy - 0.18 * $s)))) }
    if ($kind -eq 'power') { $pen = New-Object System.Drawing.Pen($brush, (0.14 * $s)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
        $q.DrawArc($pen, ($cx - 0.4 * $s), ($cy - 0.36 * $s), (0.8 * $s), (0.8 * $s), -60, 300); $q.DrawLine($pen, $cx, ($cy - 0.5 * $s), $cx, ($cy - 0.02 * $s)) }
}
function Save256($b, $name) { $b.Save("$Stage\$name.png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose() }
function New256 { $b = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.SmoothingMode = 'AntiAlias'; $q.Clear([System.Drawing.Color]::Transparent); @($b, $q) }
function Ring($q, $rgb, $peak) {
    for ($i = 0; $i -lt 26; $i++) { $rr = 102 + $i; $t = 1 - [Math]::Abs($i - 7) / 19.0; if ($t -le 0) { continue }
        $pen = New-Object System.Drawing.Pen((Col ([int]($peak * $t)) $rgb[0] $rgb[1] $rgb[2]), 1.6); $q.DrawEllipse($pen, (128 - $rr), (128 - $rr), (2 * $rr), (2 * $rr)) }
}
# a glyph that glows: dark halo so it reads on gold, then a light core
function Lit($q, $kind, $size, $dy, $core, $haloA) {
    for ($k = 4; $k -ge 1; $k--) {
        $mm = New-Object System.Drawing.Drawing2D.Matrix; $sc = 1 + 0.07 * $k; $mm.Translate(128, (128 + $dy)); $mm.Scale($sc, $sc); $mm.Translate(-128, -(128 + $dy))
        $q.Transform = $mm; Glyph $q $kind 128 (128 + $dy) $size (New-Object System.Drawing.SolidBrush((Col ([int]($haloA / 2)) 20 10 0)))
    }
    $q.ResetTransform(); Glyph $q $kind 128 (128 + $dy) $size (New-Object System.Drawing.SolidBrush($core))
}
$Amber = 255, 150, 30; $Red = 255, 60, 40
function Key($name, $kind, $ringRgb, $lit, $size) {
    $restCore = if ($lit) { Col 255 ($ringRgb[0]) ($ringRgb[1]) ($ringRgb[2]) } else { Col 150 255 240 210 }
    $b, $q = New256; if ($lit) { Ring $q $ringRgb 230 }; Lit $q $kind $size 0 $restCore 110; $q.Dispose(); Save256 $b $name
    $b, $q = New256; Ring $q $ringRgb 255; Lit $q $kind ($size * 1.06) 0 (Col 255 255 248 226) 170; $q.Dispose(); Save256 $b "$name-hot"
    $b, $q = New256; Ring $q $ringRgb 150; Lit $q $kind ($size * 0.96) 5 (Col 255 255 190 90) 140; $q.Dispose(); Save256 $b "$name-pressed"
}
Key 'Play' 'play' $Amber $false 76;   Key 'Play-2' 'stop' $Amber $true 70
Key 'Mute' 'mute' $Amber $false 76;   Key 'Mute-2' 'muted' $Red $true 76
Key 'Rec' 'rec' $Red $false 64;       Key 'Rec-2' 'rec' $Red $true 64
Key 'Back' 'back' $Amber $false 80;   Key 'Next' 'next' $Amber $false 80
Key 'OnTop' 'pin' $Amber $false 96;   Key 'OnTop-2' 'pin' $Amber $true 96
Key 'Favorites' 'heart' $Amber $false 104; Key 'Options' 'cog' $Amber $false 110
Key 'Minimize' 'minus' $Amber $false 110;  Key 'Exit' 'power' $Red $false 110
# a real knob lifted from the render (the brass Minimise knob, centre 959,237 r24), circle-masked with a
# feathered rim, so the extra button is one of the radio's own; chevron and ring drawn over it as on the others
function CloneKnob($q) {
    $src = [System.Drawing.Bitmap]::FromFile($Radio); $cx = 959; $cy = 237; $r = 24
    $cut = New-Object System.Drawing.Bitmap((2 * $r), (2 * $r), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 2 * $r; $y++) { for ($x = 0; $x -lt 2 * $r; $x++) {
        $d = [Math]::Sqrt([Math]::Pow($x + 0.5 - $r, 2) + [Math]::Pow($y + 0.5 - $r, 2)); $a = [Math]::Max(0.0, [Math]::Min(1.0, ($r - $d) / 1.5))
        $c = $src.GetPixel(($cx - $r + $x), ($cy - $r + $y)); $cut.SetPixel($x, $y, (Col ([int](255 * $a)) $c.R $c.G $c.B)) } }
    $src.Dispose()
    $q.InterpolationMode = $HQ; $q.DrawImage($cut, 28, 28, 200, 200); $cut.Dispose()
}
function KnobKey($name, $kind) {
    $b, $q = New256; CloneKnob $q; Ring $q $Amber 150; Lit $q $kind 64 0 (Col 190 255 240 210) 120; $q.Dispose(); Save256 $b $name
    $b, $q = New256; CloneKnob $q; Ring $q $Amber 255; Lit $q $kind 68 0 (Col 255 255 248 226) 170; $q.Dispose(); Save256 $b "$name-hot"
    $b, $q = New256; CloneKnob $q; Ring $q $Amber 170; Lit $q $kind 62 5 (Col 255 255 190 90) 140; $q.Dispose(); Save256 $b "$name-pressed"
}
KnobKey 'Expand' 'chev'
# OnTop-2 hot/pressed come from Key above; Mechanno's base also ships -2 hot/pressed for Play/Mute/Rec under the same names

# volume thumb: a knurled gold knob
foreach ($st in @(@('VolumeThumb', 0), @('VolumeThumbHot', 1))) {
    $b = New-Object System.Drawing.Bitmap(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.SmoothingMode = 'AntiAlias'; $q.Clear([System.Drawing.Color]::Transparent)
    $q.FillEllipse((New-Object System.Drawing.SolidBrush((Col 90 10 5 0))), 6, 8, 54, 54)
    $hi = if ($st[1]) { Col 255 255 236 160 } else { Col 255 236 200 110 }
    $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0, 0, 64, 64)), $hi, (Col 255 120 80 24), 60)
    $q.FillEllipse($gb, 4, 4, 54, 54)
    for ($i = 0; $i -lt 24; $i++) { $a = [Math]::PI * 2 * $i / 24
        $q.DrawLine((New-Object System.Drawing.Pen((Col 150 70 44 10), 1.5)), (31 + 22 * [Math]::Cos($a)), (31 + 22 * [Math]::Sin($a)), (31 + 27 * [Math]::Cos($a)), (31 + 27 * [Math]::Sin($a))) }
    $ring = if ($st[1]) { Col 255 255 150 30 } else { Col 255 90 60 16 }
    $q.DrawEllipse((New-Object System.Drawing.Pen($ring, 2.5)), 4, 4, 54, 54)
    $q.Dispose(); $b.Save("$Stage\$($st[0]).png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
# the base ships a lowercase sources-pressed.png; Windows names ignore case, so remove it BEFORE drawing
Remove-Item "$Stage\sources-pressed.png" -ErrorAction SilentlyContinue
# Sources sits on the bright gold strip: bare at rest, a dark underline on hover
foreach ($st in @(@('Sources', 0), @('Sources-hot', 200), @('Sources-pressed', 130))) {
    $b = New-Object System.Drawing.Bitmap(210, 42, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.Clear([System.Drawing.Color]::Transparent)
    if ($st[1]) { $q.FillRectangle((New-Object System.Drawing.SolidBrush((Col $st[1] 60 34 6))), 10, 36, 190, 3) }
    $q.Dispose(); $b.Save("$Stage\$($st[0]).png", [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
if (-not (Test-Path "$Stage\Sources-pressed.png")) { throw 'Sources-pressed.png missing' }

# ================= XML =================
function Set-Tag([ref]$xml, $el, $tag, $val) {
    # stay inside <$el>: a plain .*? runs on into the next element when $el lacks $tag, and edits THAT one
    $re = "(?s)(<$el>(?:(?!</$el>).)*?<$tag>)[^<]*(</$tag>)"
    if ([regex]::IsMatch($xml.Value, $re)) { $xml.Value = [regex]::Replace($xml.Value, $re, "`${1}$val`${2}", 1) }
    elseif ($xml.Value -match "<$el>") { $xml.Value = [regex]::Replace($xml.Value, "(<$el>)", "`${1}<$tag>$val</$tag>", 1) }
    else { throw "element $el missing" }
}
function Place([ref]$xml, $el, $r) { Set-Tag $xml $el 'x' $r[0]; Set-Tag $xml $el 'y' $r[1]; Set-Tag $xml $el 'width' $r[2]; Set-Tag $xml $el 'height' $r[3]; Set-Tag $xml $el 'visible' 1 }
function Style([ref]$xml) {
    Set-Tag $xml 'Window' 'text' 'Golden Aether'
    Set-Tag $xml 'Window' 'Rounded' 0
    Set-Tag $xml 'Author' 'Name' 'Claude - Golden Aether, VisionFX and Nano Banana art'
    Set-Tag $xml 'Sources' 'TextColor' $Pal.Ink
    Set-Tag $xml 'FoundNumber' 'TextColor' $Pal.Title
    foreach ($e in 'Status', 'BufferInfo') { Set-Tag $xml $e 'TextColor' $Pal.Dim }
    Set-Tag $xml 'List' 'TextColor' $Pal.Text; Set-Tag $xml 'List' 'HighLightColor' $Pal.Hi; Set-Tag $xml 'List' 'HighLightTextColor' $Pal.HiText
    Set-Tag $xml 'Spectrum' 'BarColorTop' $Pal.BarTop; Set-Tag $xml 'Spectrum' 'BarColorBottom' $Pal.BarBot
}
$enc = New-Object System.Text.UTF8Encoding($false)
$TS = @{ RotatedInfo = 17; Status = 11; BufferInfo = 11; FoundNumber = 12; Sources = 10 }
$MinH = @{ Filter = 20; Volume = 20 }
function Lay([ref]$xml, $crop, $s, $table) {
    foreach ($k in $table.Keys) {
        $r = ToWin $crop $s $table[$k]
        if ($TS.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], [int][Math]::Ceiling(1.35 * $TS[$k])); Set-Tag $xml $k 'TextSize' $TS[$k] }
        if ($MinH.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], $MinH[$k]) }
        Place $xml $k $r
    }
}

$x1 = [IO.File]::ReadAllText("$Base\skin.rsn")
Set-Tag ([ref]$x1) 'Window' 'width' $w1; Set-Tag ([ref]$x1) 'Window' 'height' $h1
Lay ([ref]$x1) $Crop $Scale $Keys; Lay ([ref]$x1) $Crop $Scale $OnRadio; Lay ([ref]$x1) $Crop $Scale $Glass
Set-Tag ([ref]$x1) 'RotatedInfo' 'TextColor' $Pal.Title
# no bold tag exists in the format. GlowColor was tried (amber / bronze halo) and he preferred plain text: the art is already backlit
Set-Tag ([ref]$x1) 'Status' 'TextAlign' 0   # centred: with the language file's Playing word blanked it shows only the running time
Set-Tag ([ref]$x1) 'Volume' 'ThumbSize' 18
Style ([ref]$x1)
$x1 = $x1.Replace('sources-pressed.png', 'Sources-pressed.png')
[IO.File]::WriteAllText("$Stage\skin.rsn", $x1, $enc)

$x2 = [IO.File]::ReadAllText("$Base\skin2.rsn")
Set-Tag ([ref]$x2) 'Window' 'width' $cw; Set-Tag ([ref]$x2) 'Window' 'height' $ch
Lay ([ref]$x2) $CropC $ScaleC $Keys
$vol = ToWin $CropC $ScaleC $OnRadio.Volume; $vol[3] = [Math]::Max($vol[3], 20); Place ([ref]$x2) 'Volume' $vol
$nm = ToWin $CropC $ScaleC $NameC; Place ([ref]$x2) 'RotatedInfo' $nm
Place ([ref]$x2) 'Spectrum' (ToWin $CropC $ScaleC $OnRadio.Spectrum)   # the screen stays alive when collapsed
Set-Tag ([ref]$x2) 'RotatedInfo' 'TextSize' 20
Set-Tag ([ref]$x2) 'RotatedInfo' 'TextColor' $Pal.Ink
# the radio's three readouts stay live in the compact view too: bitrate, running time, buffer
$TSC = @{ Sources = 9; Status = 9; BufferInfo = 8 }
# a box shorter than ~16px renders these small sizes as NOTHING (not clipped), so give each 16px, centred on its slot
foreach ($k in $TSC.Keys) { $r = ToWin $CropC $ScaleC $OnRadio[$k]; if ($r[3] -lt 16) { $r[1] -= [int][Math]::Floor((16 - $r[3]) / 2); $r[3] = 16 }; Place ([ref]$x2) $k $r; Set-Tag ([ref]$x2) $k 'TextSize' $TSC[$k] }
Set-Tag ([ref]$x2) 'Status' 'TextAlign' 0
# hidden in the base's compact view, so their backgrounds were never set: unset paints Windows grey
foreach ($k in $TSC.Keys) { Set-Tag ([ref]$x2) $k 'BkColor' '0,0,0,0'; Set-Tag ([ref]$x2) $k 'GlowColor' '0,0,0,0' }
foreach ($k in 'Filter','FilterLabel','FoundNumber','List','BufferIndicator','SongTitle') {
    if ($x2 -match "<$k>") { Set-Tag ([ref]$x2) $k 'visible' 0 } }
Set-Tag ([ref]$x2) 'Volume' 'ThumbSize' 16
Style ([ref]$x2)
$x2 = $x2.Replace('sources-pressed.png', 'Sources-pressed.png')
[IO.File]::WriteAllText("$Stage\skin2.rsn", $x2, $enc)

# ---- validate: every visible element inside its window, no overlaps, no missing art, no empty tags ----
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
    }
    # text elements: a box under 15px rendered NOTHING at TextSize 8-9 (13px failed, 15px works), and an unset
    # background paints a Windows-grey bar behind the text. Filter is a native control and is exempt.
    foreach ($e in $els) {
        if (-not $e.TextSize -or $e.Name -eq 'Filter') { continue }
        if ([int]$e.height -lt 15) { "SMALL $($f[0]) $($e.Name) is $($e.height)px tall: renders blank below 15"; $bad++ }
        if (-not $e.BkColor -or $e.BkColor -eq '-1') { "GREYBG $($f[0]) $($e.Name) has no BkColor: RadioSure paints grey behind it"; $bad++ }
    }
    foreach ($n in $x.SelectNodes('//*[contains(text(), ".png")]')) { if (-not (Test-Path "$Stage\$($n.InnerText)")) { "MISSING $($n.InnerText)"; $bad++ } }
    foreach ($mt in [regex]::Matches((Get-Content "$Stage\$($f[0])" -Raw), '<(\w+)></\1>')) { "EMPTY $($f[0]) <$($mt.Groups[1].Value)>"; $bad++ }
    "{0}: {1} visible elements" -f $f[0], $els.Count
}
"expanded ${w1}x${h1}, collapsed ${cw}x${ch}; problems: $bad"
