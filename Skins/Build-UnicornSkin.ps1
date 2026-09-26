# Unicorn skin for RadioSure, built by remapping the finished Gramophone skin:
# copy it, replace the backgrounds, rewrite every element's geometry from a
# layout table measured on the source render, validate, write to $Stage.
# Geometry is in NATIVE pixels of the 1408x768 render; transforms below.
param(
    [string]$Src     = "$PSScriptRoot\source\unicorn.jpg",
    [string]$Base    = "$PSScriptRoot\Gramophone.rsn",
    [string]$Frames  = "$PSScriptRoot\source\stardust",
    [string]$Stage   = "$PSScriptRoot\Unicorn.rsn",
    [int]$GlassDim   = 130,
    [double]$Scale    = 0.72    # 0.72 = the Gramophone's height, which fits 1080p at 150%
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$HQ = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# ---- transforms ----
$E = @{ X0 = 390; Y0 = 0;  W = 995; H = 768; S = $Scale }   # expanded crop
$w1 = [int]($E.W * $E.S); $h1 = [int]($E.H * $E.S)
$C = @{ X0 = 392; Y0 = 60; W = 648; H = 700; S = 0.45; Plate = 58 }  # collapsed crop + nameplate

function ToWin($t, $a) {   # native (x,y,w,h) -> window ints
    @([int][Math]::Round(($a[0] - $t.X0) * $t.S), [int][Math]::Round(($a[1] - $t.Y0) * $t.S),
      [int][Math]::Round($a[2] * $t.S), [int][Math]::Round($a[3] * $t.S))
}

# ---- expanded layout: native px ----
$LE = [ordered]@{
    Play = 637,560,62,72; Mute = 742,557,46,50; Rec = 703,555,33,33
    Back = 617,638,50,50; Next = 742,620,46,52
    Favorites = 892,125,94,85; Options = 988,150,47,58
    RotatedInfo = 1084,88,242,30
    Sources = 1079,122,105,22; Filter = 1189,122,94,22; FoundNumber = 1288,122,44,22
    List = 1076,150,258,370
    Status = 1082,526,130,22; BufferInfo = 1214,526,112,22
    Volume = 1086,550,238,26
    Spectrum = 1094,590,218,76
}
# window-space extras (not on the art): title buttons in the sky above the board
$WE = [ordered]@{ OnTop = ($w1 - 108),8,18,18; Minimize = ($w1 - 86),8,18,18; Expand = ($w1 - 64),8,18,18; Exit = ($w1 - 42),8,18,18 }

# ---- collapsed: collar keys in native px, the rest in window px on the nameplate ----
$LC = [ordered]@{
    Play = 637,560,62,72; Mute = 742,557,46,50; Rec = 703,555,33,33
    Back = 617,638,50,50; Next = 742,620,46,52
    Favorites = 892,125,94,85; Options = 988,150,47,58
}
$cw = [int]($C.W * $C.S); $ch0 = [int]($C.H * $C.S); $ch = $ch0 + $C.Plate
$WC = [ordered]@{
    RotatedInfo = 10,($ch0 + 5),($cw - 104),22
    OnTop = ($cw - 88),($ch0 + 7),18,18; Minimize = ($cw - 67),($ch0 + 7),18,18; Expand = ($cw - 46),($ch0 + 7),18,18; Exit = ($cw - 25),($ch0 + 7),18,18
    Volume = 16,($ch0 + 31),($cw - 32),22
}
$HideC = 'Sources','Filter','FilterLabel','FoundNumber','List','Status','BufferInfo','BufferIndicator','Spectrum','SongTitle'

# ---- palette (A,R,G,B) ----  NOT $P: PowerShell names are case-insensitive, $p is reused for a GraphicsPath below
$Pal = @{
    Title = '255,255,206,236'; Text = '255,236,222,246'; Dim = '255,214,196,230'
    Hi = '255,120,30,100'; HiText = '255,255,214,240'
}

# ================= build =================
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item "$Base\*" $Stage
Remove-Item "$Stage\SkinPreview.png"

$img = [System.Drawing.Image]::FromFile($Src)

# 32bpp ARGB like every other skin - a 24bpp background crashed RadioSure on
# load. Cleared opaque first so edge alpha stays 255 (no pale fringe).
function NewBg($w, $h) {
    $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $q = [System.Drawing.Graphics]::FromImage($b); $q.Clear([System.Drawing.Color]::FromArgb(14, 6, 24)); $q.Dispose(); $b
}
function DrawCrop($g, $t, $w, $h) {
    $ia = New-Object System.Drawing.Imaging.ImageAttributes; $ia.SetWrapMode('TileFlipXY')
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), $t.X0, $t.Y0, $t.W, $t.H, 'Pixel', $ia); $ia.Dispose()
}

# bg1: crop, then smoke the board's glass so the list reads
$b1 = NewBg $w1 $h1; $g = [System.Drawing.Graphics]::FromImage($b1)
$g.InterpolationMode = $HQ; $g.SmoothingMode = 'AntiAlias'
DrawCrop $g $E $w1 $h1
$gx = (1070 - $E.X0) * $E.S; $gy = 80 * $E.S; $gw = 266 * $E.S; $gh = 498 * $E.S; $r = 64 * $E.S
$p = New-Object System.Drawing.Drawing2D.GraphicsPath
$p.AddArc($gx, $gy, $r, $r, 180, 90); $p.AddArc($gx + $gw - $r, $gy, $r, $r, 270, 90)
$p.AddLine(($gx + $gw), ($gy + $gh), $gx, ($gy + $gh)); $p.CloseFigure()
$g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($GlassDim, 6, 2, 14))), $p)
$g.Dispose(); $b1.Save("$Stage\bg1.png", [System.Drawing.Imaging.ImageFormat]::Png)

# bg2: the medallion, with a glass nameplate under it
$b2 = NewBg $cw $ch; $g = [System.Drawing.Graphics]::FromImage($b2)
$g.InterpolationMode = $HQ; $g.SmoothingMode = 'None'
$g.Clear([System.Drawing.Color]::FromArgb(14, 6, 24))
DrawCrop $g $C $cw $ch0
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(222, 176, 72))), 0, $ch0, $cw, 2)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 130, 210))), 0, ($ch0 + 2), $cw, 1)
$g.Dispose(); $b2.Save("$Stage\bg2.png", [System.Drawing.Imaging.ImageFormat]::Png)

# SkinPreview: 360 wide at the expanded aspect
$pw = 360; $ph = [int][Math]::Round($pw * $h1 / $w1)
$pv = New-Object System.Drawing.Bitmap($pw, $ph); $g = [System.Drawing.Graphics]::FromImage($pv); $g.InterpolationMode = $HQ
$g.DrawImage($b1, 0, 0, $pw, $ph); $g.Dispose(); $pv.Save("$Stage\SkinPreview.png", [System.Drawing.Imaging.ImageFormat]::Png); $pv.Dispose()
$b1.Dispose(); $b2.Dispose(); $img.Dispose()

# heart and ghost ARE the buttons: no glyph at rest, stardust on hover/press
function Dust($frame, $alpha, $out) {
    $f = [System.Drawing.Image]::FromFile("$Frames\$frame.png")
    $b = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b); $g.InterpolationMode = $HQ
    if ($alpha -gt 0) {
        $cm = New-Object System.Drawing.Imaging.ColorMatrix; $cm.Matrix33 = [single]$alpha
        $ia = New-Object System.Drawing.Imaging.ImageAttributes; $ia.SetColorMatrix($cm)
        $g.DrawImage($f, (New-Object System.Drawing.Rectangle(0, 0, 256, 256)), 0, 0, $f.Width, $f.Height, 'Pixel', $ia)
    }
    $g.Dispose(); $f.Dispose(); $b.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
foreach ($k in 'Favorites', 'Options') {
    Dust 'frame5' 0   "$Stage\$k.png"
    Dust 'frame5' 1.0 "$Stage\$k-hot.png"
    Dust 'frame3' 0.6 "$Stage\$k-pressed.png"
}

# ---- XML ----
function Set-Tag([ref]$xml, $el, $tag, $val) {
    $re = "(?s)(<$el>.*?<$tag>)[^<]*(</$tag>)"
    if ([regex]::IsMatch($xml.Value, $re)) { $xml.Value = [regex]::Replace($xml.Value, $re, "`${1}$val`${2}", 1) }
    elseif ($xml.Value -match "<$el>") { $xml.Value = [regex]::Replace($xml.Value, "(<$el>)", "`${1}<$tag>$val</$tag>", 1) }
    else { throw "element $el missing" }
}
function Place([ref]$xml, $el, $r) { Set-Tag $xml $el 'x' $r[0]; Set-Tag $xml $el 'y' $r[1]; Set-Tag $xml $el 'width' $r[2]; Set-Tag $xml $el 'height' $r[3]; Set-Tag $xml $el 'visible' 1 }
function Style([ref]$xml) {
    Set-Tag $xml 'Window' 'text' 'Unicorn'
    Set-Tag $xml 'Author' 'Name' 'Claude - Unicorn, Nano Banana art'
    Set-Tag $xml 'RotatedInfo' 'TextColor' $Pal.Title
    foreach ($e in 'Sources', 'FoundNumber') { Set-Tag $xml $e 'TextColor' $Pal.Title }
    foreach ($e in 'Status', 'BufferInfo') { Set-Tag $xml $e 'TextColor' $Pal.Dim }
    Set-Tag $xml 'List' 'TextColor' $Pal.Text; Set-Tag $xml 'List' 'HighLightColor' $Pal.Hi; Set-Tag $xml 'List' 'HighLightTextColor' $Pal.HiText
}
$enc = New-Object System.Text.UTF8Encoding($false)

$x1 = [IO.File]::ReadAllText("$Base\skin.rsn")
Set-Tag ([ref]$x1) 'Window' 'width' $w1; Set-Tag ([ref]$x1) 'Window' 'height' $h1
# text sizes are NOT scaled with the art - smaller window, relatively bigger type.
# A box shorter than ~1.35x its TextSize renders nothing, so boxes grow to fit.
$TSE = @{ RotatedInfo = 15; Status = 12; BufferInfo = 12; FoundNumber = 12; Sources = 9 }
$MinH = @{ Filter = 20; Volume = 20 }
foreach ($k in $LE.Keys) {
    $r = ToWin $E $LE[$k]
    if ($TSE.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], [int][Math]::Ceiling(1.35 * $TSE[$k])); Set-Tag ([ref]$x1) $k 'TextSize' $TSE[$k] }
    if ($MinH.ContainsKey($k)) { $r[3] = [Math]::Max($r[3], $MinH[$k]) }
    Place ([ref]$x1) $k $r
}
foreach ($k in $WE.Keys) { Place ([ref]$x1) $k $WE[$k] }
Set-Tag ([ref]$x1) 'Volume' 'ThumbSize' 16
Style ([ref]$x1)
[IO.File]::WriteAllText("$Stage\skin.rsn", $x1, $enc)

$x2 = [IO.File]::ReadAllText("$Base\skin2.rsn")
Set-Tag ([ref]$x2) 'Window' 'width' $cw; Set-Tag ([ref]$x2) 'Window' 'height' $ch
foreach ($k in $LC.Keys) { Place ([ref]$x2) $k (ToWin $C $LC[$k]) }
foreach ($k in $WC.Keys) { Place ([ref]$x2) $k $WC[$k] }
foreach ($k in $HideC) { if ($x2 -match "<$k>") { Set-Tag ([ref]$x2) $k 'visible' 0 } }
Set-Tag ([ref]$x2) 'RotatedInfo' 'TextSize' 13
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
        # images referenced must exist
        foreach ($n in $e.SelectNodes('.//*[contains(., ".png")]')) { if ($n.ChildNodes.Count -eq 1 -and -not (Test-Path "$Stage\$($n.InnerText)")) { "MISSING $($n.InnerText)"; $bad++ } }
    }
    # an empty value (e.g. <TextColor></TextColor>) crashes RadioSure on load
    foreach ($m in [regex]::Matches((Get-Content "$Stage\$($f[0])" -Raw), '<(\w+)></\1>')) { "EMPTY $($f[0]) <$($m.Groups[1].Value)>"; $bad++ }
    "{0}: {1} visible elements" -f $f[0], $els.Count
}
"expanded ${w1}x${h1}, collapsed ${cw}x${ch}; problems: $bad"
