################################################################################
#  Build-HighContrastSkin.ps1                                                  #
#                                                                              #
#  An accessible RadioSure skin. Unlike the others in this series it is not     #
#  illustration - every choice below is a constraint.                           #
#                                                                              #
#  Yellow on black is 19.6:1, well past WCAG's 7:1 AAA threshold, and is the    #
#  convention low-vision users know from Windows' own High Contrast Black.      #
#  State changes invert completely rather than glowing, because a subtle        #
#  highlight is invisible to the people this is for.                           #
#                                                                              #
#  600x360 deliberately. RadioSure is DPI-unaware, so Windows hands it a        #
#  virtual screen of resolution/scaling - and high scaling, which is exactly    #
#  what this audience runs, SHRINKS that screen. At 1080p and 250% the usable   #
#  height is only 384px. A big skin would be unusable for the people who most   #
#  need it.                                                                     #
################################################################################

[CmdletBinding()]
param(
    [string] $OutDir = '',
    [string] $SkinName = 'High Contrast'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not $OutDir) { throw "Pass -OutDir, e.g. -OutDir 'D:\...\High Contrast.rsn'" }
if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# --- palette. Every pair here was measured, not chosen by eye ----------------
$BLACK  = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$YELLOW = [System.Drawing.Color]::FromArgb(255, 255, 255, 0)   # 19.6:1 on black
$WHITE  = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) # 21.0:1 on black
$yellowS = '255,255,255,0'
$whiteS  = '255,255,255,255'
$blackS  = '255,0,0,0'
$clear   = '0,0,0,0'

$W = 600; $H = 360
$HC = 104

$L = @{
    Pad      = 12
    TitleY   = 12;  TitleH  = 46      # now playing - the biggest thing here
    RowY     = 68;  RowH    = 34      # sources / filter / found
    ListY    = 110; ListH   = 160
    MetaY    = 278; MetaH   = 30       # deep enough for 16pt readouts
    KeyY     = 314; KeyH    = 38; KeyW = 52; KeyGap = 8
}

function New-Canvas ([int]$w, [int]$h) {
    $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    return @{ Bitmap = $b; Graphics = $g }
}
function Save-Canvas ($c, [string]$name) {
    # seal the outer ring opaque - antialiased fills leave it part-transparent,
    # and RadioSure composites that against a light background as a pale line
    $b = $c.Bitmap
    for ($x = 0; $x -lt $b.Width; $x++) { foreach ($y in 0, ($b.Height-1)) {
        $p = $b.GetPixel($x,$y); if ($p.A -lt 255) { $b.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,$p.R,$p.G,$p.B)) } } }
    for ($y = 0; $y -lt $b.Height; $y++) { foreach ($x in 0, ($b.Width-1)) {
        $p = $b.GetPixel($x,$y); if ($p.A -lt 255) { $b.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,$p.R,$p.G,$p.B)) } } }
    $c.Graphics.Dispose()
    $b.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
}
function Box ($g, [int]$x, [int]$y, [int]$w, [int]$h, $fill, $edge, [int]$thick) {
    # flat fill, thick hard border. No gradient, no rounding, no texture:
    # every one of those blurs an edge, and a blurred edge is the problem.
    $b = New-Object System.Drawing.SolidBrush $fill
    $g.FillRectangle($b, $x, $y, $w, $h); $b.Dispose()
    if ($thick -gt 0) {
        $p = New-Object System.Drawing.Pen $edge, $thick
        $p.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Inset
        $g.DrawRectangle($p, $x, $y, $w, $h); $p.Dispose()
    }
}

# --- backgrounds -------------------------------------------------------------
function Draw-Face ($g, [int]$w, [int]$h, [bool]$expanded) {
    $bg = New-Object System.Drawing.SolidBrush $BLACK
    $g.FillRectangle($bg, 0, 0, $w, $h); $bg.Dispose()
    $outer = New-Object System.Drawing.Pen $YELLOW, 3
    $outer.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Inset
    $g.DrawRectangle($outer, 0, 0, ($w-1), ($h-1)); $outer.Dispose()

    $th = if ($expanded) { $L.TitleH } else { 36 }
    Box $g $L.Pad $L.TitleY ($w - ($L.Pad*2) - 1) $th $BLACK $YELLOW 3
    if ($expanded) {
        Box $g $L.Pad $L.RowY  ($w - ($L.Pad*2) - 1) $L.RowH  $BLACK $YELLOW 2
        Box $g $L.Pad $L.ListY ($w - ($L.Pad*2) - 1) $L.ListH $BLACK $YELLOW 3
        Box $g $L.Pad $L.MetaY ($w - ($L.Pad*2) - 1) $L.MetaH $BLACK $YELLOW 2
    }
}
$c = New-Canvas ($W + 1) ($H + 1); Draw-Face $c.Graphics ($W+1) ($H+1) $true;  Save-Canvas $c 'bg1.png'
$c = New-Canvas ($W + 1) ($HC + 1); Draw-Face $c.Graphics ($W+1) ($HC+1) $false; Save-Canvas $c 'bg2.png'

# --- buttons: inversion, not glow -------------------------------------------
# normal  = yellow glyph on black, thick yellow border
# hot     = FULL INVERSION, black glyph on solid yellow
# pressed = inverted, glyph nudged down
function Draw-Glyph ($g, [string]$kind, $ink, [int]$cy) {
    $b = New-Object System.Drawing.SolidBrush $ink
    $p = New-Object System.Drawing.Pen $ink, 22
    switch ($kind) {
        'plain' { }
        'play' { $g.FillPolygon($b, [System.Drawing.PointF[]]@(
                    (New-Object System.Drawing.PointF(88,($cy-62))),
                    (New-Object System.Drawing.PointF(88,($cy+62))),
                    (New-Object System.Drawing.PointF(184,$cy)))) }
        'stop' { $g.FillRectangle($b, 90, ($cy-56), 112, 112) }
        'prev' { $g.FillRectangle($b, 76, ($cy-56), 24, 112)
                 $g.FillPolygon($b, [System.Drawing.PointF[]]@(
                    (New-Object System.Drawing.PointF(190,($cy-56))),
                    (New-Object System.Drawing.PointF(190,($cy+56))),
                    (New-Object System.Drawing.PointF(106,$cy)))) }
        'next' { $g.FillRectangle($b, 168, ($cy-56), 24, 112)
                 $g.FillPolygon($b, [System.Drawing.PointF[]]@(
                    (New-Object System.Drawing.PointF(78,($cy-56))),
                    (New-Object System.Drawing.PointF(78,($cy+56))),
                    (New-Object System.Drawing.PointF(162,$cy)))) }
        'rec'  { $g.FillEllipse($b, 76, ($cy-58), 116, 116) }
        'heart'{ $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                 $path.AddBezier(134,($cy+58), 40,($cy-6), 78,($cy-72), 134,($cy-24))
                 $path.AddBezier(134,($cy-24), 190,($cy-72), 228,($cy-6), 134,($cy+58))
                 $g.FillPath($b, $path); $path.Dispose() }
        'spkr' { $g.FillPolygon($b, [System.Drawing.PointF[]]@(
                    (New-Object System.Drawing.PointF(72,($cy-26))),
                    (New-Object System.Drawing.PointF(112,($cy-26))),
                    (New-Object System.Drawing.PointF(152,($cy-62))),
                    (New-Object System.Drawing.PointF(152,($cy+62))),
                    (New-Object System.Drawing.PointF(112,($cy+26))),
                    (New-Object System.Drawing.PointF(72,($cy+26)))))
                 $p2 = New-Object System.Drawing.Pen $ink, 14
                 $g.DrawArc($p2, 160, ($cy-44), 56, 88, -60, 120); $p2.Dispose() }
        'mutex'{ $g.FillPolygon($b, [System.Drawing.PointF[]]@(
                    (New-Object System.Drawing.PointF(72,($cy-26))),
                    (New-Object System.Drawing.PointF(112,($cy-26))),
                    (New-Object System.Drawing.PointF(152,($cy-62))),
                    (New-Object System.Drawing.PointF(152,($cy+62))),
                    (New-Object System.Drawing.PointF(112,($cy+26))),
                    (New-Object System.Drawing.PointF(72,($cy+26)))))
                 $p3 = New-Object System.Drawing.Pen $ink, 16
                 $g.DrawLine($p3, 170, ($cy-34), 218, ($cy+34))
                 $g.DrawLine($p3, 218, ($cy-34), 170, ($cy+34)); $p3.Dispose() }
        'gear' { $p4 = New-Object System.Drawing.Pen $ink, 26
                 $g.DrawEllipse($p4, 82, ($cy-52), 104, 104); $p4.Dispose()
                 for ($i=0; $i -lt 8; $i++) {
                    $a = $i*45*[Math]::PI/180
                    $p5 = New-Object System.Drawing.Pen $ink, 20
                    $g.DrawLine($p5, (134+[Math]::Cos($a)*62), ($cy+[Math]::Sin($a)*62),
                                     (134+[Math]::Cos($a)*96), ($cy+[Math]::Sin($a)*96)); $p5.Dispose() } }
        'x'    { $p6 = New-Object System.Drawing.Pen $ink, 26
                 $g.DrawLine($p6, 78,($cy-56), 190,($cy+56))
                 $g.DrawLine($p6, 190,($cy-56), 78,($cy+56)); $p6.Dispose() }
        'min'  { $g.FillRectangle($b, 76, ($cy-12), 116, 24) }
        'exp'  { $p7 = New-Object System.Drawing.Pen $ink, 26
                 $g.DrawLine($p7, 76,($cy-28), 134,($cy+30))
                 $g.DrawLine($p7, 192,($cy-28), 134,($cy+30)); $p7.Dispose() }
        'pin'  { $g.FillEllipse($b, 100, ($cy-56), 68, 68)
                 $g.FillRectangle($b, 124, ($cy+6), 20, 56) }
    }
    $b.Dispose(); $p.Dispose()
}
function Build-Key ([string]$file, [string]$kind, [string]$state) {
    $c = New-Canvas 256 256
    $g = $c.Graphics
    $inverted = ($state -ne 'normal')
    $fill = if ($inverted) { $YELLOW } else { $BLACK }
    $ink  = if ($inverted) { $BLACK }  else { $YELLOW }
    Box $g 4 4 247 247 $fill $YELLOW 10
    $cy = if ($state -eq 'pressed') { 134 } else { 128 }
    Draw-Glyph $g $kind $ink $cy
    Save-Canvas $c $file
}
$keys = @{
    'Play' = 'play'; 'Play-2' = 'stop'; 'Back' = 'prev'; 'Next' = 'next'
    'Rec' = 'rec'; 'Rec-2' = 'rec'; 'Favorites' = 'heart'
    'Mute' = 'spkr'; 'Mute-2' = 'mutex'; 'Options' = 'gear'
    'Exit' = 'x'; 'Minimize' = 'min'; 'Expand' = 'exp'
    'OnTop' = 'pin'; 'OnTop-2' = 'pin'; 'Sources' = 'plain'
}
foreach ($k in $keys.Keys) {
    Build-Key "$k.png"         $keys[$k] 'normal'
    Build-Key "$k-hot.png"     $keys[$k] 'hot'
    Build-Key "$k-pressed.png" $keys[$k] 'pressed'
}
# filter label: a blank spacer, hidden in the XML
$c = New-Canvas 24 24; Save-Canvas $c 'FilterLabel.png'
Copy-Item (Join-Path $OutDir 'FilterLabel.png') (Join-Path $OutDir 'FilterLabel-hot.png')
Copy-Item (Join-Path $OutDir 'FilterLabel.png') (Join-Path $OutDir 'FilterLabel-pressed.png')

# volume: a thick yellow channel, unmissable thumb
$c = New-Canvas 512 40
Box $c.Graphics 0 12 511 16 $BLACK $YELLOW 3
Save-Canvas $c 'VolumeChannel.png'
$c = New-Canvas 40 64; Box $c.Graphics 2 2 35 59 $YELLOW $YELLOW 0; Save-Canvas $c 'VolumeThumb.png'
$c = New-Canvas 40 64; Box $c.Graphics 2 2 35 59 $WHITE  $WHITE  0; Save-Canvas $c 'VolumeThumbHot.png'

# preview, matching the skin's own aspect
$c = New-Canvas 360 216
Draw-Face $c.Graphics 360 216 $true
Save-Canvas $c 'SkinPreview.png'

"  artwork written"

# --- the XML -----------------------------------------------------------------
$pad = $L.Pad; $inner = $W - ($pad*2)
$kx = @(); $x = $pad
for ($i = 0; $i -lt 7; $i++) { $kx += $x; $x += ($L.KeyW + $L.KeyGap) }
$wbW = 34; $wbY = 318
$wb = @(); $x = $W - $pad - $wbW
for ($i = 0; $i -lt 4; $i++) { $wb += $x; $x -= ($wbW + 6) }

function Emit ([string]$file, [bool]$expanded) {
    $h = if ($expanded) { $H } else { $HC }
    $bg = if ($expanded) { 'bg1.png' } else { 'bg2.png' }
    $vis = { param($e) if ($expanded) { '1' } else { '0' } }
    $listVis = if ($expanded) { '1' } else { '0' }
    $keyY = if ($expanded) { $L.KeyY } else { 54 }
    $titleH = if ($expanded) { $L.TitleH } else { 36 }
    $titleSize = if ($expanded) { 20 } else { 18 }
    # the text box has to be tall enough for the type, or the line vanishes
    # entirely - compact was a 14px box holding 14pt, which needs about 18px
    $titleTextH = if ($expanded) { $titleH - 16 } else { 26 }
    $titleTextY = if ($expanded) { $L.TitleY + 8 } else { $L.TitleY + 5 }
@"
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!-- High Contrast - an accessible skin. Yellow on black is 19.6:1, WCAG AAA.
     State changes invert rather than glow. Nothing is hidden or decorative. -->
<XMLConfigSettings>
  <Window>
    <Frame>0</Frame><x>0</x><y>0</y>
    <width>$W</width><height>$h</height>
    <Background>$bg</Background><Rounded>0</Rounded>
  </Window>
  <RotatedInfo>
    <x>$($pad+8)</x><y>$($titleTextY)</y><width>406</width><height>$($titleTextH)</height>
    <visible>1</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>$titleSize</TextSize><TextAlign>0</TextAlign>
  </RotatedInfo>
  <SongTitle><x>0</x><y>0</y><width>0</width><height>0</height><visible>0</visible>
    <TextColor>$yellowS</TextColor><BkColor>$clear</BkColor><GlowColor>$clear</GlowColor>
    <TextSize>10</TextSize><TextAlign>0</TextAlign></SongTitle>
  <Sources>
    <x>$($pad+6)</x><y>$($L.RowY+5)</y><width>124</width><height>24</height>
    <visible>$listVis</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>12</TextSize><TextAlign>0</TextAlign>
    <Image><Normal>Sources.png</Normal><Hot>Sources-hot.png</Hot><Pressed>Sources-pressed.png</Pressed></Image>
  </Sources>
  <FilterLabel><x>0</x><y>0</y><width>1</width><height>1</height><visible>0</visible>
    <TextColor>$yellowS</TextColor><BkColor>$clear</BkColor><GlowColor>$clear</GlowColor>
    <TextSize>10</TextSize><TextAlign>0</TextAlign>
    <Image><Normal>FilterLabel.png</Normal><Hot>FilterLabel-hot.png</Hot><Pressed>FilterLabel-pressed.png</Pressed></Image>
  </FilterLabel>
  <Filter>
    <x>$($pad+146)</x><y>$($L.RowY+6)</y><width>158</width><height>22</height>
    <visible>$listVis</visible><TextColor>$whiteS</TextColor><BkColor>$blackS</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>10</TextSize><TextAlign>0</TextAlign>
  </Filter>
  <FoundNumber>
    <x>$($pad+320)</x><y>$($L.RowY+5)</y><width>244</width><height>24</height>
    <visible>$listVis</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>14</TextSize><TextAlign>1</TextAlign>
  </FoundNumber>
  <List>
    <x>$($pad+4)</x><y>$($L.ListY+4)</y><width>$($inner-8)</width><height>$($L.ListH-8)</height>
    <visible>$listVis</visible>
    <TextColor>$whiteS</TextColor><BkColor>$blackS</BkColor>
    <HighLightColor>$yellowS</HighLightColor><HighLightTextColor>$blackS</HighLightTextColor>
    <Transparent>0</Transparent>
  </List>
  <Status>
    <x>$($pad+8)</x><y>$($L.MetaY+3)</y><width>260</width><height>24</height>
    <visible>$listVis</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>16</TextSize><TextAlign>0</TextAlign>
  </Status>
  <BufferInfo>
    <x>$($pad+300)</x><y>$($L.MetaY+3)</y><width>264</width><height>24</height>
    <visible>$listVis</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>16</TextSize><TextAlign>1</TextAlign>
  </BufferInfo>
  <BufferIndicator><x>0</x><y>0</y><width>1</width><height>1</height><visible>0</visible></BufferIndicator>
  <Spectrum><x>0</x><y>0</y><width>1</width><height>1</height><visible>0</visible>
    <BarColorTop>$yellowS</BarColorTop><BarColorBottom>$yellowS</BarColorBottom>
    <BkColorTop>$clear</BkColorTop><BkColorBottom>$clear</BkColorBottom>
    <BarLineColor>$clear</BarLineColor><Bars>20</Bars><GlassLevel>0</GlassLevel><Frame>0</Frame>
  </Spectrum>
  <Volume>
    <x>432</x><y>$($keyY + 8)</y><width>156</width><height>24</height>
    <visible>1</visible><ThumbSize>22</ThumbSize>
    <Image><Channel>VolumeChannel.png</Channel><Thumb>VolumeThumb.png</Thumb><ThumbHot>VolumeThumbHot.png</ThumbHot></Image>
  </Volume>
"@ + $(
  $order = @('Play','Back','Next','Rec','Favorites','Mute','Options')
  $out = ''
  for ($i = 0; $i -lt 7; $i++) {
    $t = $order[$i]
    $alt = if ($t -eq 'Play') { "<ImageAlt><Normal>Play-2.png</Normal><Hot>Play-2-hot.png</Hot><Pressed>Play-2-pressed.png</Pressed></ImageAlt>" }
           elseif ($t -eq 'Rec') { "<ImageAlt><Normal>Rec-2.png</Normal><Hot>Rec-2-hot.png</Hot><Pressed>Rec-2-pressed.png</Pressed></ImageAlt>" }
           elseif ($t -eq 'Mute') { "<ImageAlt><Normal>Mute-2.png</Normal><Hot>Mute-2-hot.png</Hot><Pressed>Mute-2-pressed.png</Pressed></ImageAlt>" }
           else { '' }
    $out += @"
  <$t>
    <x>$($kx[$i])</x><y>$keyY</y><width>$($L.KeyW)</width><height>$($L.KeyH)</height>
    <visible>1</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>10</TextSize><TextAlign>0</TextAlign>
    <Image><Normal>$t.png</Normal><Hot>$t-hot.png</Hot><Pressed>$t-pressed.png</Pressed></Image>$alt
  </$t>

"@
  }
  $wbNames = @('Exit','Expand','Minimize','OnTop')
  for ($i = 0; $i -lt 4; $i++) {
    $t = $wbNames[$i]
    $alt = if ($t -eq 'OnTop') { "<ImageAlt><Normal>OnTop-2.png</Normal><Hot>OnTop-2-hot.png</Hot><Pressed>OnTop-2-pressed.png</Pressed></ImageAlt>" } else { '' }
    $out += @"
  <$t>
    <x>$($wb[$i])</x><y>$($L.TitleY + 6)</y><width>$wbW</width><height>$wbW</height>
    <visible>1</visible><TextColor>$yellowS</TextColor><BkColor>$clear</BkColor>
    <GlowColor>$clear</GlowColor><TextSize>10</TextSize><TextAlign>0</TextAlign>
    <Image><Normal>$t.png</Normal><Hot>$t-hot.png</Hot><Pressed>$t-pressed.png</Pressed></Image>$alt
  </$t>

"@
  }
  $out
) + @"
  <Author><Name>High Contrast - accessible skin</Name><URL>https://github.com/SilentFrequency/radiosure-revival</URL></Author>
</XMLConfigSettings>
"@
}
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin.rsn'),  (Emit 'skin.rsn'  $true),  $enc)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin2.rsn'), (Emit 'skin2.rsn' $false), $enc)

"  Built '$SkinName' - $((Get-ChildItem $OutDir).Count) files, ${W}x${H} / ${W}x${HC}"
