################################################################################
#  Build-HallowsEveSkin.ps1                                                    #
#                                                                              #
#  A vertical RadioSure skin: a 1930s "tombstone" cabinet - the upright style  #
#  with arched shoulders that the trade really did call a tombstone - in       #
#  ebonised walnut and tarnished brass, lit from inside by candle amber.       #
#                                                                              #
#  The season is in the furniture and in the fretwork, not stuck on the front. #
#  There are things in the grille that only show up close. Leave them for      #
#  people to find; do not put them in the readme.                              #
#                                                                              #
#  Every pixel is drawn here with System.Drawing. No downloads, no traced art, #
#  no game or film assets. Change the palette block and re-run for a different #
#  colourway - close RadioSure first, it holds the PNGs open.                  #
################################################################################

[CmdletBinding()]
param(
    [string] $OutDir   = "$env:LOCALAPPDATA\RadioSure\Skins\Hallows Eve.rsn",
    [string] $SkinName = 'Hallows Eve',
    # Leave everything outside the stone at alpha 0, to find out whether
    # RadioSure honours per-pixel alpha or only clips to a rounded rectangle.
    [switch] $TransparentGround,

    # Version 2 route: use a photograph as the whole background instead of
    # drawing the stone. No fretwork is drawn over it - the photo carries
    # everything, including its own carved lettering.
    [string] $Photo,
    # Where to take the portrait crop from, as a fraction of the photo width
    [single] $PhotoCentre = 0.5,
    # How hard to push it toward night. 0 = untouched, 1 = black.
    [single] $PhotoNight = 0.42
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function C ([int]$r, [int]$g, [int]$b, [int]$a = 255) {
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

# --- Palette: weathered granite, tarnished brass, candlelight -------------------
# The stone is cold and nearly colourless and the brass has gone green with age,
# so the only warm colour in the skin is the light itself. That contrast is the
# whole design: everything warm is lit, everything else is dead.

$Night      = C  10   9  12   # the ground the cabinet stands against
$NightLite  = C  26  23  28
$StoneDeep  = C  18  20  19   # granite, not timber: everything here is cold
$StoneDark  = C  41  45  42
$StoneMid   = C  96 102  95
$StoneLite  = C 148 156 145
$Lichen     = C 118 130 100   # what grows on a stone nobody visits
$LichenPal  = C 148 156 130
$MossDark   = C  42  54  34
$Moss       = C  60  76  46
$Brass      = C 146 114  64
$BrassLite  = C 206 170 106
$BrassDark  = C  74  56  30
$Bone       = C 228 216 192   # the key faces
$BoneDim    = C 184 172 150
$Amber      = C 255 170  74   # candlelight
$AmberDeep  = C 218 112  30
$Ember      = C 255 120  40
$Moon       = C 214 214 198
$Ink        = C   8   7   9

$W = 430          # window
$H = 780
$HC = 104         # collapsed height: two rows, and the spectrum stays small

# --- Layout -------------------------------------------------------------------
# One set of numbers for both the artwork and the XML. They were separate at
# first and immediately drifted - a panel painted where no control sat.
$L = @{
    ArchCy    = 120        # centre of the fretwork inside the arched head
    ArchR     = 88
    Moulding  = 214        # the line dividing head from body
    TitleY    = 172        # station name: the most important readout on the
    TitleH    = 34         # face, so it gets a deep panel and 12pt type
    RowY      = 228        # sources / filter / found
    ListY     = 264        # the list well
    ListH     = 288
    MetaY     = 564        # status / buffer / the vial
    DialY     = 580        # dial glass
    DialH     = 74
    VolY      = 662
    KeyY      = 706        # the one row of keys. Sits clear of the slider:
                           # at 692 the two overlapped by 2px and the thumb
                           # clipped the top of the keys.
    KeySize   = 44
}

# --- Canvas helpers -----------------------------------------------------------

function New-Canvas ([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return @{ Bitmap = $bmp; Graphics = $g }
}

function Seal-Edge ($canvas, $colour) {
    # The ground is filled with SmoothingMode = AntiAlias, which antialiases the
    # fill's OWN outer edge and leaves the outermost row and column at roughly
    # half alpha. RadioSure composites that against its light window background,
    # and the result is the thin pale line visible around the whole window on
    # every skin built this way. Stamp the ring fully opaque with smoothing off.
    $g   = $canvas.Graphics
    $old = $g.SmoothingMode
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, $colour.R, $colour.G, $colour.B)), 1
    $g.DrawRectangle($pen, 0, 0, ($canvas.Bitmap.Width - 1), ($canvas.Bitmap.Height - 1))
    $pen.Dispose()
    $g.SmoothingMode = $old
}

function Save-Canvas ($canvas, [string]$name) {
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Bitmap.Dispose()
}

function New-RoundRect ([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x,           $y,           $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y,           $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d,   0, 90)
    $p.AddArc($x,           $y + $h - $d, $d, $d,  90, 90)
    $p.CloseFigure()
    return $p
}

# The tombstone outline: a rectangle whose top is a half-round arch. Real
# cabinets of the style are exactly this - the arch is the whole reason the
# trade nicknamed them tombstones.
function New-TombstonePath ([single]$x, [single]$y, [single]$w, [single]$h, [single]$foot) {
    # Cut by hand, not turned on a lathe. A mathematically clean semicircle on
    # straight sides is a door; a headstone has a nibbled edge and sides that
    # wander by a pixel or two. Seeded so the silhouette never changes.
    $p    = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rand = New-Object System.Random(1935)
    $cx   = $x + ($w / 2)
    $cy   = $y + ($w / 2)
    $r    = $w / 2
    $pts  = New-Object System.Collections.ArrayList

    # The head, left round to right, with the odd chip taken out of it
    for ($a = 180; $a -le 360; $a += 4) {
        $rad = ($a * [math]::PI) / 180
        $jit = $rand.Next(5) - 3
        if ($rand.Next(11) -eq 0) { $jit -= 3 + $rand.Next(5) }
        $rr = $r + $jit
        [void]$pts.Add((New-Object System.Drawing.PointF(
            [single]($cx + ($rr * [math]::Cos($rad))), [single]($cy + ($rr * [math]::Sin($rad))))))
    }
    # Right flank down
    for ($yy = $cy + 24; $yy -lt $y + $h - $foot; $yy += 30) {
        [void]$pts.Add((New-Object System.Drawing.PointF(
            [single]($x + $w + ($rand.Next(3) - 2)), [single]$yy)))
    }
    # Foot, buried in the earth, so barely shaped at all
    [void]$pts.Add((New-Object System.Drawing.PointF([single]($x + $w), [single]($y + $h))))
    [void]$pts.Add((New-Object System.Drawing.PointF([single]$x, [single]($y + $h))))
    # Left flank back up
    for ($yy = $y + $h - $foot; $yy -gt $cy + 24; $yy -= 30) {
        [void]$pts.Add((New-Object System.Drawing.PointF(
            [single]($x + ($rand.Next(3) - 2)), [single]$yy)))
    }

    $p.AddPolygon([System.Drawing.PointF[]]($pts.ToArray([System.Drawing.PointF])))
    return $p
}

function Draw-Glow ($g, [single]$cx, [single]$cy, [single]$rx, [single]$ry, $colour, [int]$alpha) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse($cx - $rx, $cy - $ry, $rx * 2, $ry * 2)
    $br = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $br.CenterColor    = [System.Drawing.Color]::FromArgb($alpha, $colour.R, $colour.G, $colour.B)
    $br.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $colour.R, $colour.G, $colour.B))
    $g.FillPath($br, $path)
    $br.Dispose(); $path.Dispose()
}

# Ebonised walnut: near-black, but the grain still catches light or it reads as
# painted card rather than wood.
function Draw-SoftBlob ($g, [single]$cx, [single]$cy, [single]$rx, [single]$ry, $colour, [int]$alpha) {
    # A solid ellipse at low alpha is still a hard-edged disc, and a field of
    # them reads as bokeh rather than stone. This fades to nothing at the rim.
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(($cx - $rx), ($cy - $ry), ($rx * 2), ($ry * 2))
    $pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $pgb.CenterColor = [System.Drawing.Color]::FromArgb($alpha, $colour.R, $colour.G, $colour.B)
    $pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $colour.R, $colour.G, $colour.B))
    $g.FillPath($pgb, $path)
    $pgb.Dispose(); $path.Dispose()
}

function Draw-Stone ($g, $clip, [int]$x, [int]$y, [int]$w, [int]$h, [int]$seed) {
    # The tell for stone is that nothing runs in a line. Timber grain is long,
    # parallel and directional; granite is blotchy at several scales at once,
    # its speckle points nowhere, and the weathering collects where water sits -
    # along the top edge and at the foot. Drawing grain here was the whole
    # reason this read as a planked door rather than a headstone.
    $state = $g.Save()
    $g.SetClip($clip, [System.Drawing.Drawing2D.CombineMode]::Intersect)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($x, $y, $w, $h)), $StoneMid, $StoneDark, 90)
    $g.FillRectangle($br, $x, $y, $w, $h); $br.Dispose()

    # Seeded, so a rebuild produces the same stone and the repo does not churn
    $rand = New-Object System.Random($seed)

    # Broad cloudiness - big soft variations in how light the rock is
    for ($i = 0; $i -lt 90; $i++) {
        $cx = $x + $rand.Next($w); $cy = $y + $rand.Next($h)
        $r  = 34 + $rand.Next(64)
        $a  = 10 + $rand.Next(14)
        $col = switch ($rand.Next(3)) { 0 { $StoneLite } 1 { $StoneMid } default { $StoneDeep } }
        Draw-SoftBlob $g $cx $cy $r ($r * 0.72) $col $a
    }

    # Mid-scale blotches - small, irregular, and hard enough to read as rock
    for ($i = 0; $i -lt 950; $i++) {
        $cx = $x + $rand.Next($w); $cy = $y + $rand.Next($h)
        $r  = 2 + $rand.Next(6)
        $a  = 8 + $rand.Next(20)
        $col = switch ($rand.Next(3)) { 0 { $StoneLite } 1 { $StoneMid } default { $StoneDeep } }
        $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $col.R, $col.G, $col.B))
        $g.FillEllipse($b2, ($cx - $r), ($cy - ($r * 0.8)), ($r * 2), ($r * 1.6)); $b2.Dispose()
    }

    # Grit - fine, directionless, and the single strongest granite cue
    for ($i = 0; $i -lt 6200; $i++) {
        $px = $x + $rand.Next($w); $py = $y + $rand.Next($h)
        $a  = 10 + $rand.Next(48)
        $col = if ($rand.Next(2) -eq 0) { $StoneLite } else { $StoneDeep }
        $sz  = if ($rand.Next(6) -eq 0) { 2 } else { 1 }
        $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $col.R, $col.G, $col.B))
        $g.FillRectangle($b2, $px, $py, $sz, $sz); $b2.Dispose()
    }

    # Lichen - gathers at the head and down the flanks, rarely in the middle
    for ($i = 0; $i -lt 70; $i++) {
        $edge = $rand.Next(3)
        $cx = switch ($edge) {
            0       { $x + $rand.Next($w) }
            1       { $x + $rand.Next([int]($w * 0.22)) }
            default { $x + $w - $rand.Next([int]($w * 0.22)) }
        }
        $cy = if ($edge -eq 0) { $y + $rand.Next([int]($h * 0.30)) } else { $y + $rand.Next($h) }
        $col = if ($rand.Next(3) -eq 0) { $LichenPal } else { $Lichen }
        # A soft stain, then crusty granules on top of it - lichen has texture
        Draw-SoftBlob $g $cx $cy (14 + $rand.Next(18)) (11 + $rand.Next(14)) $col (12 + $rand.Next(14))
        $grains = 30 + $rand.Next(40)
        for ($k = 0; $k -lt $grains; $k++) {
            $r  = 1 + $rand.Next(3)
            $a  = 18 + $rand.Next(40)
            $ox = $cx + $rand.Next(34) - 17
            $oy = $cy + $rand.Next(28) - 14
            $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $col.R, $col.G, $col.B))
            $g.FillEllipse($b2, ($ox - $r), ($oy - $r), ($r * 2), ($r * 2)); $b2.Dispose()
        }
    }

    # Cracks - a dark cut with a lit lower lip, the way a real one catches light
    for ($c = 0; $c -lt 3; $c++) {
        $px = $x + 40 + $rand.Next([int]($w - 80))
        $py = $y + $rand.Next([int]($h * 0.35))
        $pts = New-Object System.Collections.ArrayList
        for ($k = 0; $k -lt 6 + $rand.Next(7); $k++) {
            [void]$pts.Add((New-Object System.Drawing.PointF([single]$px, [single]$py)))
            $px += $rand.Next(34) - 17
            $py += 14 + $rand.Next(30)
            if ($py -gt $y + $h - 10) { break }
        }
        if ($pts.Count -lt 2) { continue }
        $cut = [System.Drawing.PointF[]]($pts.ToArray([System.Drawing.PointF]))
        $lip = [System.Drawing.PointF[]]($pts | ForEach-Object {
            New-Object System.Drawing.PointF([single]$_.X, [single]($_.Y + 1.3)) })
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, $Moon.R, $Moon.G, $Moon.B)), 1.1
        $g.DrawLines($pen, $lip); $pen.Dispose()
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(125, $Ink.R, $Ink.G, $Ink.B)), 1.4
        $g.DrawLines($pen, $cut); $pen.Dispose()
    }

    # Moss at the foot - damp, dark, and it climbs a little way up
    for ($i = 0; $i -lt 40; $i++) {
        $mx = $x + $rand.Next($w)
        $my = $y + $h - $rand.Next(70)
        Draw-SoftBlob $g $mx $my (18 + $rand.Next(26)) (10 + $rand.Next(16)) $MossDark (18 + $rand.Next(22))
    }
    for ($i = 0; $i -lt 1400; $i++) {
        # Weighted to the very bottom: moss climbs, but not far
        $mx = $x + $rand.Next($w)
        $my = $y + $h - [int]([Math]::Pow($rand.NextDouble(), 1.8) * 78)
        $r  = 1 + $rand.Next(4)
        $a  = 16 + $rand.Next(46)
        $col = if ($rand.Next(3) -eq 0) { $Moss } else { $MossDark }
        $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $col.R, $col.G, $col.B))
        $g.FillEllipse($b2, ($mx - $r), ($my - $r), ($r * 2), ($r * 2)); $b2.Dispose()
    }

    # Pits - a stone this old is pocked. Each is a dark hollow with a lit lower
    # lip, which is what stops them reading as flat dots.
    for ($i = 0; $i -lt 320; $i++) {
        $px = $x + $rand.Next($w)
        $py = $y + $rand.Next($h)
        $r  = 1 + $rand.Next(4)
        $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb((40 + $rand.Next(60)), $Ink.R, $Ink.G, $Ink.B))
        $g.FillEllipse($b2, ($px - $r), ($py - $r), ($r * 2), ($r * 2)); $b2.Dispose()
        $b2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb((26 + $rand.Next(40)), $StoneLite.R, $StoneLite.G, $StoneLite.B))
        $g.FillEllipse($b2, ($px - $r), ($py - $r + 1.1), ($r * 2), ($r * 1.5)); $b2.Dispose()
    }

    # Water staining - rain runs off the head and streaks the face below it.
    # Soft, few, and irregular: any regularity here reads as grain again.
    for ($i = 0; $i -lt 14; $i++) {
        $sx = $x + $rand.Next($w)
        $sy = $y + $rand.Next([int]($h * 0.30))
        $sl = 60 + $rand.Next(190)
        $sw = 6 + $rand.Next(20)
        $sa = 8 + $rand.Next(12)
        $col = if ($rand.Next(3) -eq 0) { $Lichen } else { $Ink }
        for ($k = 0; $k -lt $sl; $k += 6) {
            $jitter = $rand.Next(5) - 2
            Draw-SoftBlob $g ($sx + $jitter) ($sy + $k) ($sw / 2) 7 $col $sa
        }
    }

    # Light comes from above. The head takes it; the foot stays dead.
    $topLit = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($x, ($y - 1), $w, 150)),
        [System.Drawing.Color]::FromArgb(30, $Moon.R, $Moon.G, $Moon.B),
        [System.Drawing.Color]::FromArgb(0, $Moon.R, $Moon.G, $Moon.B), 90)
    $g.FillRectangle($topLit, $x, $y - 1, $w, 150); $topLit.Dispose()

    $footDark = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($x, ($y + $h - 170), $w, 171)),
        [System.Drawing.Color]::FromArgb(0, $Ink.R, $Ink.G, $Ink.B),
        [System.Drawing.Color]::FromArgb(74, $Ink.R, $Ink.G, $Ink.B), 90)
    $g.FillRectangle($footDark, $x, $y + $h - 170, $w, 171); $footDark.Dispose()

    $g.Restore($state)
}

# --- The fretwork in the arch -------------------------------------------------
# Bare branches across a moon, and three things that are not branches. Nobody
# who glances at it will see them, which is the point.

function Draw-Bat ($g, [single]$cx, [single]$cy, [single]$span, [single]$tilt, $colour) {
    # Wingspan is 2 x span. Built as one closed silhouette: a leading edge that
    # sweeps tip to tip over the shoulders and head, then a trailing edge that
    # comes back in scallops. The scallops are what make it read as a bat at a
    # glance rather than as a bird or a smudge.
    # Flat and wide. The first version was about 1:2 deep-to-wide with heavy
    # scallops, which rendered as a notched block; a bat silhouette needs to be
    # nearer 1:4.5, with the scallops shallow enough to read as a trailing edge
    # rather than as teeth.
    $lead = @(
        @(-1.00,  0.00), @(-0.66, -0.20), @(-0.34, -0.22), @(-0.12, -0.12),
        @( 0.00, -0.20),
        @( 0.12, -0.12), @( 0.34, -0.22), @( 0.66, -0.20), @( 1.00,  0.00))
    $trail = @(
        @( 0.76,  0.10), @( 0.58,  0.02), @( 0.42,  0.14), @( 0.26,  0.04),
        @( 0.10,  0.20), @( 0.00,  0.22), @(-0.10,  0.20),
        @(-0.26,  0.04), @(-0.42,  0.14), @(-0.58,  0.02), @(-0.76,  0.10))

    $cos = [Math]::Cos($tilt); $sin = [Math]::Sin($tilt)
    $pts = New-Object System.Collections.ArrayList
    foreach ($set in @($lead, $trail)) {
        foreach ($q in $set) {
            $px = $q[0] * $span; $py = $q[1] * $span
            [void]$pts.Add((New-Object System.Drawing.PointF(
                [single]($cx + ($px * $cos) - ($py * $sin)),
                [single]($cy + ($px * $sin) + ($py * $cos)))))
        }
    }

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddClosedCurve([System.Drawing.PointF[]]($pts.ToArray([System.Drawing.PointF])), 0.5)
    $br = New-Object System.Drawing.SolidBrush $colour
    $g.FillPath($br, $path); $br.Dispose()

    # Ears, too small to model in the curve without it going lumpy
    foreach ($d in -1, 1) {
        $ex = $cx + (($d * 0.08 * $span) * $cos) - ((-0.19 * $span) * $sin)
        $ey = $cy + (($d * 0.08 * $span) * $sin) + ((-0.19 * $span) * $cos)
        $er = $span * 0.07
        $eb = New-Object System.Drawing.SolidBrush $colour
        $g.FillEllipse($eb, ($ex - $er), ($ey - $er), ($er * 2), ($er * 2.4)); $eb.Dispose()
    }
    $path.Dispose()
}

function Draw-Fretwork ($g, [single]$cx, [single]$cy, [single]$r) {
    # The moon, low and full behind the trees
    Draw-Glow $g $cx ($cy + 6) ($r * 1.15) ($r * 1.15) $Amber 44
    $moonR = $r * 0.52
    $mb = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF(($cx - $moonR), ($cy - $moonR), ($moonR * 2), ($moonR * 2))),
        $Moon, (C 150 146 132), 60)
    $g.FillEllipse($mb, $cx - $moonR, $cy - $moonR, $moonR * 2, $moonR * 2); $mb.Dispose()
    # Craters, faint
    $cr = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(26, 60, 56, 50))
    $g.FillEllipse($cr, $cx - ($moonR * 0.42), $cy - ($moonR * 0.30), $moonR * 0.38, $moonR * 0.34)
    $g.FillEllipse($cr, $cx + ($moonR * 0.10), $cy + ($moonR * 0.22), $moonR * 0.30, $moonR * 0.26)
    $g.FillEllipse($cr, $cx + ($moonR * 0.28), $cy - ($moonR * 0.44), $moonR * 0.20, $moonR * 0.18)
    $cr.Dispose()

    # Bare branches reaching up and across the moon from either side. Thin, and
    # a lot of them - the first attempt used few thick strokes and read as a
    # squid rather than winter wood.
    $rand = New-Object System.Random(9)
    function Branch ($g, $x1, $y1, $x2, $y2, $wdt, $depth, $rand, $ink) {
        if ($depth -le 0 -or $wdt -lt 0.35) { return }
        $pen = New-Object System.Drawing.Pen $ink, ([single]$wdt)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
        $mx = ($x1 + $x2) / 2 + ($rand.NextDouble() - 0.5) * 9
        $my = ($y1 + $y2) / 2 + ($rand.NextDouble() - 0.5) * 9
        $g.DrawCurve($pen, @(
            (New-Object System.Drawing.PointF($x1, $y1)),
            (New-Object System.Drawing.PointF($mx, $my)),
            (New-Object System.Drawing.PointF($x2, $y2))))
        $pen.Dispose()
        $ang0 = [Math]::Atan2($y2 - $y1, $x2 - $x1)
        for ($i = 0; $i -lt 3; $i++) {
            if ($rand.NextDouble() -lt 0.25) { continue }
            $ang = $ang0 + (($rand.NextDouble() - 0.5) * 1.5)
            $len = (14 + $rand.Next(15)) * ($depth / 5.0)
            Branch $g $x2 $y2 ($x2 + [Math]::Cos($ang) * $len) ($y2 + [Math]::Sin($ang) * $len) `
                   ($wdt * 0.66) ($depth - 1) $rand $ink
        }
    }
    # Six short boughs reaching in from the sides. Short first segments: long
    # ones came out as straight ropes across the whole head.
    foreach ($d in -1, 1) {
        Branch $g ($cx + $d * $r * 1.05) ($cy + $r * 0.70) ($cx + $d * $r * 0.62) ($cy + $r * 0.30) 2.8 5 $rand $Ink
        Branch $g ($cx + $d * $r * 1.02) ($cy + $r * 0.15) ($cx + $d * $r * 0.58) ($cy - $r * 0.10) 2.4 5 $rand $Ink
        Branch $g ($cx + $d * $r * 0.80) ($cy - $r * 0.55) ($cx + $d * $r * 0.40) ($cy - $r * 0.70) 2.0 4 $rand $Ink
    }

    # Two bats. The near one is large and deliberately crosses the moon's rim,
    # so part of the silhouette sits on lit disc and part on dark sky - that
    # contrast is what makes it definite rather than a shape among the twigs.
    # The far one is small and higher, and gives the sky some depth.
    $moonR = $r * 0.52
    # Placed low and left, clear of the branch tangle over the top of the moon:
    # at the original position the wings merged into the twigs and the shape was
    # unreadable. Here it straddles the rim - lit disc behind one wing, grey
    # stone behind the other.
    Draw-Bat $g ($cx - ($moonR * 0.66)) ($cy + ($moonR * 0.34)) ($moonR * 0.82) (-0.12) $Ink
    Draw-Bat $g ($cx + ($r * 0.66))     ($cy - ($r * 0.60))     ($r * 0.10)     (0.28)  $Ink

    # A spider, down a thread from the top of the arch. Its own brush: this
    # used to borrow $ib from the bat block above it.
    $ib = New-Object System.Drawing.SolidBrush $Ink
    # A spider, down a thread from the top of the arch
    $sx = $cx - $r * 0.62; $sy = $cy - $r * 0.62
    $th = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 20, 18, 16)), 1
    $g.DrawLine($th, $sx, $cy - $r * 1.30, $sx, $sy - 4); $th.Dispose()
    $lp = New-Object System.Drawing.Pen $Ink, 1.2
    foreach ($d in -1, 1) {
        for ($k = 0; $k -lt 3; $k++) {
            $g.DrawCurve($lp, @(
                (New-Object System.Drawing.PointF($sx, $sy)),
                (New-Object System.Drawing.PointF(($sx + $d * (5 + $k * 2)), ($sy - 3 + $k * 3))),
                (New-Object System.Drawing.PointF(($sx + $d * (7 + $k * 2)), ($sy + 4 + $k * 2)))))
        }
    }
    $lp.Dispose()
    $g.FillEllipse($ib, $sx - 3.2, $sy - 2.4, 6.4, 6.0)
    $ib.Dispose()
}

# --- Keys ---------------------------------------------------------------------
# Bone-coloured key faces set into brass bezels. The bezel is what makes the
# hover state read: it gives the highlight a rim to catch.

function Draw-Key ($g, [string]$state) {
    $inset = 14
    $sz    = 256 - ($inset * 2)

    $shadow = New-RoundRect ($inset + 3) ($inset + 6) $sz $sz 34
    $sb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $g.FillPath($sb, $shadow); $sb.Dispose(); $shadow.Dispose()

    # Bezel
    $bez = New-RoundRect $inset $inset $sz $sz 34
    $bcol = switch ($state) {
        'hot'     { $BrassLite }
        'pressed' { $BrassDark }
        default   { $Brass }
    }
    $bb = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($inset, $inset, $sz, $sz)),
        $bcol, $BrassDark, 90)
    $g.FillPath($bb, $bez); $bb.Dispose()
    $bp = New-Object System.Drawing.Pen $BrassDark, 3
    $g.DrawPath($bp, $bez); $bp.Dispose(); $bez.Dispose()

    # Key face, recessed inside the bezel
    $fi = $inset + 16
    $fs = 256 - ($fi * 2)
    $face = New-RoundRect $fi $fi $fs $fs 24
    $fcol = switch ($state) {
        'hot'     { $Bone }
        'pressed' { C 150 140 122 }
        default   { $BoneDim }
    }
    $fb = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($fi, $fi, $fs, $fs)),
        $fcol, (C ([int]($fcol.R * 0.72)) ([int]($fcol.G * 0.72)) ([int]($fcol.B * 0.70))), 90)
    $g.FillPath($fb, $face); $fb.Dispose()

    if ($state -eq 'hot') {
        # The candle catches the rim
        Draw-Glow $g 128 128 118 118 $Amber 46
    }
    $face.Dispose()
}

function Draw-Icon ($g, [string]$icon, $colour, [string]$state) {
    $b = New-Object System.Drawing.SolidBrush $colour
    $p = New-Object System.Drawing.Pen $colour, 13
    $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $p.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $p.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    switch ($icon) {
        'play' {
            $pts = @((New-Object System.Drawing.PointF(104, 92)),
                     (New-Object System.Drawing.PointF(104, 164)),
                     (New-Object System.Drawing.PointF(166, 128)))
            $g.FillPolygon($b, $pts)
        }
        'stop'  { $g.FillRectangle($b, 100, 100, 56, 56) }
        'prev'  {
            $g.FillRectangle($b, 96, 96, 13, 64)
            $pts = @((New-Object System.Drawing.PointF(162, 96)),
                     (New-Object System.Drawing.PointF(162, 160)),
                     (New-Object System.Drawing.PointF(114, 128)))
            $g.FillPolygon($b, $pts)
        }
        'next'  {
            $g.FillRectangle($b, 147, 96, 13, 64)
            $pts = @((New-Object System.Drawing.PointF(94, 96)),
                     (New-Object System.Drawing.PointF(94, 160)),
                     (New-Object System.Drawing.PointF(142, 128)))
            $g.FillPolygon($b, $pts)
        }
        'recoff' { $g.FillEllipse($b, 100, 100, 56, 56) }
        'rec'    {
            Draw-Glow $g 128 128 62 62 $Ember 150
            $g.FillEllipse($b, 96, 96, 64, 64)
        }
        'heart' {
            $h = New-Object System.Drawing.Drawing2D.GraphicsPath
            $h.AddArc(94,  96, 34, 34, 180, 180)
            $h.AddArc(128, 96, 34, 34, 180, 180)
            $h.AddLine(162, 122, 128, 166)
            $h.AddLine(128, 166, 94, 122)
            $h.CloseFigure()
            $g.FillPath($b, $h); $h.Dispose()
        }
        'speaker' {
            $pts = @((New-Object System.Drawing.PointF(96, 112)),
                     (New-Object System.Drawing.PointF(116, 112)),
                     (New-Object System.Drawing.PointF(138, 92)),
                     (New-Object System.Drawing.PointF(138, 164)),
                     (New-Object System.Drawing.PointF(116, 144)),
                     (New-Object System.Drawing.PointF(96, 144)))
            $g.FillPolygon($b, $pts)
            $ap = New-Object System.Drawing.Pen $colour, 8
            $g.DrawArc($ap, 128, 100, 40, 56, -55, 110)
            $ap.Dispose()
        }
        'mute' {
            $pts = @((New-Object System.Drawing.PointF(90, 112)),
                     (New-Object System.Drawing.PointF(110, 112)),
                     (New-Object System.Drawing.PointF(132, 92)),
                     (New-Object System.Drawing.PointF(132, 164)),
                     (New-Object System.Drawing.PointF(110, 144)),
                     (New-Object System.Drawing.PointF(90, 144)))
            $g.FillPolygon($b, $pts)
            $xp = New-Object System.Drawing.Pen $colour, 10
            $xp.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $xp.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawLine($xp, 146, 110, 176, 146)
            $g.DrawLine($xp, 176, 110, 146, 146)
            $xp.Dispose()
        }
        'gear' {
            # A cog, but drawn as a rose window - it is the options button on a
            # cabinet that wants to look like architecture.
            $g.DrawEllipse($p, 92, 92, 72, 72)
            for ($i = 0; $i -lt 8; $i++) {
                $a  = $i * [Math]::PI / 4
                $x1 = 128 + [Math]::Cos($a) * 20; $y1 = 128 + [Math]::Sin($a) * 20
                $x2 = 128 + [Math]::Cos($a) * 46; $y2 = 128 + [Math]::Sin($a) * 46
                $sp = New-Object System.Drawing.Pen $colour, 9
                $sp.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                $sp.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
                $g.DrawLine($sp, $x1, $y1, $x2, $y2); $sp.Dispose()
            }
            $g.FillEllipse($b, 114, 114, 28, 28)
        }
        'power' {
            $ap = New-Object System.Drawing.Pen $colour, 14
            $ap.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $ap.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $g.DrawArc($ap, 92, 92, 72, 72, -60, 300)
            $g.DrawLine($ap, 128, 82, 128, 122)
            $ap.Dispose()
        }
        'expand' {
            $ap = New-Object System.Drawing.Pen $colour, 14
            $ap.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $ap.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
            $ap.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
            $g.DrawLines($ap, @((New-Object System.Drawing.PointF(96, 112)),
                                (New-Object System.Drawing.PointF(128, 148)),
                                (New-Object System.Drawing.PointF(160, 112))))
            $ap.Dispose()
        }
        'minimise' { $g.FillRectangle($b, 96, 120, 64, 13) }
        'pin' {
            $g.FillEllipse($b, 108, 88, 40, 40)
            $g.FillRectangle($b, 122, 124, 12, 46)
        }
    }
    $b.Dispose(); $p.Dispose()
}

# The four window buttons are not keys. Given bone faces they became the
# brightest thing on a near-black cabinet and pulled the eye straight to the
# corner. These are dark chips with a brass rim instead - present, not shouting.
function Draw-Chip ($g, [string]$state) {
    $inset = 22
    $sz    = 256 - ($inset * 2)
    $r = New-RoundRect $inset $inset $sz $sz 40
    $face = switch ($state) {
        'hot'     { $StoneMid }
        'pressed' { $StoneDeep }
        default   { $StoneDark }
    }
    $b = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle($inset, $inset, $sz, $sz)), $face, $StoneDeep, 90)
    $g.FillPath($b, $r); $b.Dispose()
    $rim = switch ($state) { 'hot' { $BrassLite } 'pressed' { $BrassDark } default { $Brass } }
    $p = New-Object System.Drawing.Pen $rim, 8
    $g.DrawPath($p, $r); $p.Dispose(); $r.Dispose()
    if ($state -eq 'hot') { Draw-Glow $g 128 128 110 110 $Amber 40 }
}

function Build-Chip ([string]$baseName, [string]$icon, $colour) {
    foreach ($state in @('normal', 'hot', 'pressed')) {
        $c = New-Canvas 256 256
        Draw-Chip $c.Graphics $state
        $tint = if ($state -eq 'hot') { $Amber } else { $colour }
        if ($state -eq 'pressed') { $c.Graphics.TranslateTransform(0, 5) }
        Draw-Icon $c.Graphics $icon $tint $state
        $suffix = switch ($state) { 'normal' { '' } 'hot' { '-hot' } 'pressed' { '-pressed' } }
        Save-Canvas $c "$baseName$suffix.png"
    }
}

function Build-Button ([string]$baseName, [string]$icon, $colour) {
    foreach ($state in @('normal', 'hot', 'pressed')) {
        $c = New-Canvas 256 256
        Draw-Key $c.Graphics $state

        $tint = $colour
        if ($state -eq 'hot') {
            $tint = C ([Math]::Min(255, [int]($colour.R * 1.15))) `
                      ([Math]::Min(255, [int]($colour.G * 1.15))) `
                      ([Math]::Min(255, [int]($colour.B * 1.10)))
        }
        if ($state -eq 'pressed') {
            $tint = C ([int]($colour.R * 0.70)) ([int]($colour.G * 0.70)) ([int]($colour.B * 0.70))
            $c.Graphics.TranslateTransform(0, 5)
        }
        Draw-Icon $c.Graphics $icon $tint $state

        $suffix = switch ($state) { 'normal' { '' } 'hot' { '-hot' } 'pressed' { '-pressed' } }
        Save-Canvas $c "$baseName$suffix.png"
    }
}

# The key faces are bone, so the glyphs have to be dark - cut into the key the
# way the legend on a piano key or a typewriter is. Bone-on-bone was the first
# attempt and the buttons came out blank.
$Glyph    = C  52  38  28
$GlyphLit = C 176  84  16

Write-Host "Building the keys ..." -ForegroundColor DarkYellow
Build-Button 'Play'      'play'     $GlyphLit
Build-Button 'Play-2'    'stop'     $GlyphLit
Build-Button 'Back'      'prev'     $Glyph
Build-Button 'Next'      'next'     $Glyph
Build-Button 'Rec'       'recoff'   (C 150 58 34)
Build-Button 'Rec-2'     'rec'      (C 206 48 26)
Build-Button 'Favorites' 'heart'    (C 176 56 40)
Build-Button 'Mute'      'speaker'  $Glyph
Build-Button 'Mute-2'    'mute'     (C 176 56 40)
Build-Button 'Options'   'gear'     $Glyph
Build-Chip   'Exit'      'power'    $BoneDim
Build-Chip   'Expand'    'expand'   $BoneDim
Build-Chip   'Minimize'  'minimise' $BoneDim
Build-Chip   'OnTop'     'pin'      $BrassDark
Build-Chip   'OnTop-2'   'pin'      $Amber

# --- Small parts ---------------------------------------------------------------

function Build-Sources ([string]$name, $edge, [int]$glow) {
    $c = New-Canvas 210 42
    $r = New-RoundRect 2 2 206 38 18
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle(2, 2, 206, 38)), $StoneMid, $StoneDeep, 90)
    $c.Graphics.FillPath($bg, $r); $bg.Dispose()
    if ($glow -gt 0) { Draw-Glow $c.Graphics 105 21 100 22 $Amber $glow }
    $p = New-Object System.Drawing.Pen $edge, 2
    $c.Graphics.DrawPath($p, $r); $p.Dispose(); $r.Dispose()
    Save-Canvas $c $name
}
Build-Sources 'Sources.png'         $Brass      0
Build-Sources 'Sources-hot.png'     $BrassLite 44
Build-Sources 'sources-pressed.png' $BrassDark  0

function Build-Thumb ([string]$name, $edge, [int]$glow) {
    $c = New-Canvas 26 34
    if ($glow -gt 0) { Draw-Glow $c.Graphics 13 17 15 19 $Amber $glow }
    $r = New-RoundRect 5 3 16 28 5
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle(5, 3, 16, 28)), $BrassLite, $BrassDark, 0)
    $c.Graphics.FillPath($bg, $r); $bg.Dispose()
    $p = New-Object System.Drawing.Pen $edge, 1.5
    $c.Graphics.DrawPath($p, $r); $p.Dispose(); $r.Dispose()
    Save-Canvas $c $name
}
Build-Thumb 'VolumeThumb.png'    $BrassDark  0
Build-Thumb 'VolumeThumbHot.png' $BrassLite 120

# Volume channel: a shallow groove routed into the wood
$c = New-Canvas 240 10
$r = New-RoundRect 0 3 240 4 2
$b = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190, 6, 5, 6))
$c.Graphics.FillPath($b, $r); $b.Dispose()
$p = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, $BrassDark.R, $BrassDark.G, $BrassDark.B)), 1
$c.Graphics.DrawPath($p, $r); $p.Dispose(); $r.Dispose()
Save-Canvas $c 'VolumeChannel.png'

# FilterLabel is a spacer in this layout - transparent, but all three states
# must exist or the hover paints nothing. The original generator learned this
# the hard way.
foreach ($n in 'FilterLabel.png', 'FilterLabel-hot.png', 'FilterLabel-pressed.png') {
    $c = New-Canvas 24 24
    Save-Canvas $c $n
}

# --- The cabinet ---------------------------------------------------------------

function Draw-ChiselledEdge ($g, $outer, [single]$cx, [single]$cy, [int]$band, [int]$seed) {
    # A headstone is not a flat cut-out. Its margin is rock-pitched - chiselled
    # back in facets that each catch the light differently - and that band of
    # broken angles is most of what tells you the thing has thickness. Without
    # it the silhouette reads as a prop no matter how good the surface is.
    $rand = New-Object System.Random($seed)
    $flat = $outer.Clone()
    $flat.Flatten()
    $raw = $flat.PathPoints
    if ($raw.Length -lt 8) { $flat.Dispose(); return }

    # Resample the outline at a fixed spacing. Walking the raw path does not
    # work: Flatten only subdivides curves, so the arch arrives as 4px steps
    # while the foot is one 398px segment - and that single segment becomes one
    # facet the width of the whole stone, straight across the face.
    $res = New-Object System.Collections.ArrayList
    for ($k = 0; $k -lt $raw.Length; $k++) {
        $a = $raw[$k]; $b = $raw[(($k + 1) % $raw.Length)]
        $dx = $b.X - $a.X; $dy = $b.Y - $a.Y
        $len = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
        if ($len -lt 0.01) { continue }
        $n = [Math]::Max(1, [int]([Math]::Floor($len / 7.0)))
        for ($t = 0; $t -lt $n; $t++) {
            $f = $t / $n
            [void]$res.Add((New-Object System.Drawing.PointF(
                [single]($a.X + ($dx * $f)), [single]($a.Y + ($dy * $f)))))
        }
    }
    $pts = [System.Drawing.PointF[]]($res.ToArray([System.Drawing.PointF]))
    if ($pts.Length -lt 8) { $flat.Dispose(); return }

    $st = $g.Save()
    $g.SetClip($outer, [System.Drawing.Drawing2D.CombineMode]::Intersect)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Light sits above and a little to the left, same as everywhere else here
    $lx = -0.48; $ly = -0.88

    $i = 0
    while ($i -lt $pts.Length) {
        $step = 2 + $rand.Next(3)
        $j = ($i + $step) % $pts.Length
        $a = $pts[$i]; $b = $pts[$j]

        $dx = $b.X - $a.X; $dy = $b.Y - $a.Y
        $len = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
        if ($len -lt 0.5) { $i = $j; continue }

        # inward normal, turned to face the middle of the stone
        $nx = -$dy / $len; $ny = $dx / $len
        if (((($cx - $a.X) * $nx) + (($cy - $a.Y) * $ny)) -lt 0) { $nx = -$nx; $ny = -$ny }

        $d1 = $band + $rand.Next(11) - 5     # the facet is deeper in some places
        $d2 = $band + $rand.Next(11) - 5
        $quad = [System.Drawing.PointF[]]@(
            (New-Object System.Drawing.PointF([single]$a.X, [single]$a.Y)),
            (New-Object System.Drawing.PointF([single]$b.X, [single]$b.Y)),
            (New-Object System.Drawing.PointF([single]($b.X + ($nx * $d2)), [single]($b.Y + ($ny * $d2)))),
            (New-Object System.Drawing.PointF([single]($a.X + ($nx * $d1)), [single]($a.Y + ($ny * $d1))))
        )

        # How square-on this facet is to the light decides whether it is a
        # highlight or a shadow. Jitter it, or the bevel looks machined.
        # Note the sign: the quad is built along the INWARD normal, but a pitched
        # margin slopes away from the face, so its surface faces OUTWARD. Using
        # the inward normal here lit the underside of the stone and shadowed the
        # crown, which turned the whole visible frame dark.
        $dot = -(($nx * $lx) + ($ny * $ly))
        $tone = [int]((26 * $dot) + $rand.Next(16) - 8)
        if ($tone -ge 0) {
            $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(([Math]::Min(58, (8 + $tone))), $Moon.R, $Moon.G, $Moon.B))
        } else {
            $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(([Math]::Min(104, (12 - $tone))), $Ink.R, $Ink.G, $Ink.B))
        }
        $g.FillPolygon($br, $quad); $br.Dispose()

        # The chisel line between one facet and the next
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb((30 + $rand.Next(50)), $Ink.R, $Ink.G, $Ink.B)), 1
        $g.DrawLine($pen, $a.X, $a.Y, ($a.X + ($nx * $d1)), ($a.Y + ($ny * $d1)))
        $pen.Dispose()

        # Seat the facet where it breaks onto the flat of the face. Done per
        # facet, so the boundary stays ragged - a continuous line here reads as
        # a drawn outline rather than a broken edge.
        $seat = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb((26 + $rand.Next(38)), $Ink.R, $Ink.G, $Ink.B)), 1.6
        $g.DrawLine($seat, ($a.X + ($nx * $d1)), ($a.Y + ($ny * $d1)),
                           ($b.X + ($nx * $d2)), ($b.Y + ($ny * $d2)))
        $seat.Dispose()

        $i += $step
    }

    $g.Restore($st)
    $flat.Dispose()
}

function Draw-PhotoGround ($g, [int]$w, [int]$h, [string]$path, [single]$centre, [single]$night, [int]$forceCropW = 0, [single]$bandY = 0.5) {
    # Fill the window with a photograph. The source is landscape and the window
    # is portrait, so take the tallest portrait crop the photo allows and slide
    # it horizontally to sit over the subject - never squash it to fit.
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        $targetAspect = $w / $h
        if ($forceCropW -gt 0) {
            # The collapsed strip is four times wider than it is tall. Letting it
            # take the widest crop available means the whole graveyard scaled to
            # 30%, which shares no visible surface with the expanded window.
            # Pinning the crop width to the expanded one instead takes a band of
            # the same stone, at the same scale, so the two states match.
            $cropW = [Math]::Min($forceCropW, $img.Width)
            $cropH = [int]([Math]::Round($cropW / $targetAspect))
        } else {
            $cropH = $img.Height
            $cropW = [int]([Math]::Round($cropH * $targetAspect))
            if ($cropW -gt $img.Width) {
                $cropW = $img.Width
                $cropH = [int]([Math]::Round($cropW / $targetAspect))
            }
        }
        $cropX = [int]([Math]::Round(($img.Width * $centre) - ($cropW / 2)))
        $cropX = [Math]::Max(0, [Math]::Min($cropX, ($img.Width - $cropW)))
        $cropY = [int]([Math]::Round(($img.Height * $bandY) - ($cropH / 2)))
        $cropY = [Math]::Max(0, [Math]::Min($cropY, ($img.Height - $cropH)))

        Write-Host ("    photo {0}x{1}, crop {2}x{3} at {4},{5} -> {6}x{7} ({8:P1} scale)" -f `
            $img.Width, $img.Height, $cropW, $cropH, $cropX, $cropY, $w, $h, ($w / $cropW)) -ForegroundColor DarkGray

        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img,
            (New-Object System.Drawing.Rectangle(0, 0, $w, $h)),
            (New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)),
            [System.Drawing.GraphicsUnit]::Pixel)
    } finally { $img.Dispose() }

    # Grade it for night. The source is an overcast daylight photograph and the
    # rest of the skin is lit by one amber source, so without this the artwork
    # and the readouts look like they come from two different places.
    $flat = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb([int](210 * $night), $Ink.R, $Ink.G, $Ink.B))
    $g.FillRectangle($flat, 0, 0, $w, $h); $flat.Dispose()

    # Heavier at the foot than the head, so the light still reads as from above
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Rectangle(0, 0, $w, $h)),
        [System.Drawing.Color]::FromArgb(0, $Ink.R, $Ink.G, $Ink.B),
        [System.Drawing.Color]::FromArgb([int](150 * $night), $Ink.R, $Ink.G, $Ink.B), 90)
    $g.FillRectangle($grad, 0, 0, $w, $h); $grad.Dispose()

    # Vignette, drawn as four edge gradients rather than a radial brush so the
    # centre of the stone stays completely untouched
    $v = [int](130 * $night)
    $edges = @(
        @{ r = (New-Object System.Drawing.Rectangle(0, 0, $w, 90));                a = 0; b = 90 },
        @{ r = (New-Object System.Drawing.Rectangle(0, ($h - 120), $w, 120));      a = 270; b = 90 },
        @{ r = (New-Object System.Drawing.Rectangle(0, 0, 70, $h));                a = 0; b = 0 },
        @{ r = (New-Object System.Drawing.Rectangle(($w - 70), 0, 70, $h));        a = 180; b = 0 })
    for ($i = 0; $i -lt 4; $i++) {
        $e = $edges[$i]
        $angle = if ($i -lt 2) { 90 } else { 0 }
        $c1 = [System.Drawing.Color]::FromArgb($v, $Ink.R, $Ink.G, $Ink.B)
        $c2 = [System.Drawing.Color]::FromArgb(0, $Ink.R, $Ink.G, $Ink.B)
        $from = if ($i -eq 1 -or $i -eq 3) { $c2 } else { $c1 }
        $to   = if ($i -eq 1 -or $i -eq 3) { $c1 } else { $c2 }
        $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($e.r, $from, $to, $angle)
        $g.FillRectangle($br, $e.r); $br.Dispose()
    }
}

function Draw-Cabinet ($g, [int]$w, [int]$h, [bool]$expanded) {
    # Night behind it - unless we are testing a shaped window, in which case
    # the ground stays transparent and only the stone is painted.
    if (-not $TransparentGround) {
        $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), $NightLite, $Night, 90)
        $g.FillRectangle($bg, 0, 0, $w, $h); $bg.Dispose()
    }

    $m    = 16
    $cw   = $w - ($m * 2)
    $ch   = $h - ($m * 2)
    # Collapsed, there is no room for the arch - a 398-wide half-round is 199
    # tall and the whole window is 104. Shrunk down it just looks broken, so the
    # collapsed state is a plain lintel of the same stone.
    $stone = if ($expanded) { New-TombstonePath $m $m $cw $ch 10 }
             else           { New-RoundRect     $m $m $cw $ch 10 }

    # Body
    Draw-Stone $g $stone $m $m $cw $ch 7

    # The pitched margin. This replaces the two flat rim strokes that used to
    # be here - a 2px highlight and a 4px dark outline gave a clean edge, which
    # was exactly the problem: clean edges belong on props, not on cut stone.
    $band = if ($expanded) { 13 } else { 9 }
    Draw-ChiselledEdge $g $stone ($m + ($cw / 2)) ($m + ($ch / 2)) $band 21
    $edge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(105, 0, 0, 0)), 1.5
    $g.DrawPath($edge, $stone); $edge.Dispose()

    if ($expanded) {
        # Clip the fretwork to the head. Twigs are grown recursively and will
        # happily wander down over the panels otherwise.
        $st = $g.Save()
        $g.SetClip((New-Object System.Drawing.RectangleF($m, $m, $cw, ($L.Moulding - $m - 8))),
                   [System.Drawing.Drawing2D.CombineMode]::Intersect)
        $g.SetClip($stone, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        Draw-Fretwork $g ($w / 2) $L.ArchCy $L.ArchR
        $g.Restore($st)

        # A moulding line under the head, dividing it from the body
        $mp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, $Brass.R, $Brass.G, $Brass.B)), 1.5
        $g.DrawLine($mp, $m + 26, $L.Moulding,     $w - $m - 26, $L.Moulding)
        $g.DrawLine($mp, $m + 26, $L.Moulding + 4, $w - $m - 26, $L.Moulding + 4)
        $mp.Dispose()
    }
}

# A recessed panel: everything that holds data sits in one of these, so the
# readouts look inlaid rather than printed on.
function Draw-Panel ($g, [single]$x, [single]$y, [single]$w, [single]$h, [int]$radius) {
    $r = New-RoundRect $x $y $w $h $radius
    $b = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(215, 5, 4, 5))
    $g.FillPath($b, $r); $b.Dispose()
    $p = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, $BrassDark.R, $BrassDark.G, $BrassDark.B)), 2
    $g.DrawPath($p, $r); $p.Dispose()
    $hl = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, $BrassLite.R, $BrassLite.G, $BrassLite.B)), 1
    $g.DrawLine($hl, $x + $radius, $y + 1, $x + $w - $radius, $y + 1); $hl.Dispose()
    $r.Dispose()
}

# The dial glass: the spectrum sits in here, lit from behind by the candle.
function Draw-DialWell ($g, [single]$x, [single]$y, [single]$w, [single]$h) {
    Draw-Panel $g $x $y $w $h 8
    Draw-Glow $g ($x + $w / 2) ($y + $h * 0.62) ($w * 0.46) ($h * 0.60) $AmberDeep 96
    Draw-Glow $g ($x + $w / 2) ($y + $h * 0.70) ($w * 0.24) ($h * 0.40) $Amber 84
    # Hairline scale across the top of the glass
    $tp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(110, $BrassLite.R, $BrassLite.G, $BrassLite.B)), 1
    for ($i = 0; $i -le 20; $i++) {
        $tx = $x + 10 + ($i * (($w - 20) / 20))
        $len = if ($i % 5 -eq 0) { 8 } else { 4 }
        $g.DrawLine($tp, $tx, $y + 5, $tx, $y + 5 + $len)
    }
    $tp.Dispose()
}

# Small engraved caps, letterspaced, for labelling a well. Same cut-and-lit
# trick as the big inscription, just smaller.
function Draw-EngravedLabel ($g, [string]$text, [single]$cx, [single]$y, [single]$size,
                             [string]$align = 'center', [bool]$letterspace = $true) {
    $spaced = if ($letterspace) { ($text.ToCharArray() -join ' ') } else { $text }
    try { $f = New-Object System.Drawing.Font('Georgia', $size) }
    catch { $f = New-Object System.Drawing.Font('Times New Roman', $size) }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = if ($align -eq 'near') { [System.Drawing.StringAlignment]::Near }
                    else                   { [System.Drawing.StringAlignment]::Center }
    $cut = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 0, 0, 0))
    $lit = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, $Brass.R, $Brass.G, $Brass.B))
    $g.DrawString($spaced, $f, $cut, $cx, $y, $sf)
    $g.DrawString($spaced, $f, $lit, $cx, $y + 1, $sf)
    $f.Dispose(); $sf.Dispose(); $cut.Dispose(); $lit.Dispose()
}

Write-Host "Building the cabinet ..." -ForegroundColor DarkYellow

function Draw-Face ($g) {
    if ($Photo) {
        # The photo is the whole background: no drawn stone, and no fretwork
        # over it either - the moon, branches and bats are clip art by any other
        # name and would sit on a photograph like stickers.
        Draw-PhotoGround $g ($W + 1) ($H + 1) $Photo $PhotoCentre $PhotoNight
    } else {
        Draw-Cabinet $g ($W + 1) ($H + 1) $true
    }
    # No backing plate behind the control stack over a photograph. It was tried:
    # it covers the carved inscription cleanly and looks more finished, but it
    # turns the controls into a slab lying ON the photo instead of wells cut
    # INTO the stone, and the inset reading is the whole point. The inscription
    # showing between the panels is the stone, and that is correct.
    Draw-Panel   $g 34 $L.TitleY 362 $L.TitleH 7       # station name
    Draw-Panel   $g 34 ($L.RowY - 6) 362 34 6          # the filter strip
    Draw-Panel   $g 34 $L.ListY  362 $L.ListH   8      # the station list well
    # The buffer bar is painted lime green by Windows and takes no colour from
    # the skin. Every other skin either hides it or builds it a housing; here it
    # gets a glass vial and a label, because on a tombstone cabinet an
    # uncontrollable sickly green readout is not a defect, it is ectoplasm.
    Draw-Panel         $g 232 ($L.MetaY - 4) 162 20 6
    Draw-EngravedLabel $g 'ECTOPLASM' 239 ($L.MetaY - 3) 6.5 'near' $false
    Draw-DialWell $g 34 $L.DialY 362 $L.DialH
    # No name on the stone. It is a tombstone with no other lettering, so an
    # engraved title reads as a mistake rather than a signature.
}

# Expanded
$c = New-Canvas ($W + 1) ($H + 1)
Draw-Face $c.Graphics
Seal-Edge $c $Night
Save-Canvas $c 'bg1.png'

# Collapsed
$c = New-Canvas ($W + 1) ($HC + 1)
if ($Photo) {
    # 424 is the crop width the expanded face uses, so both states show the
    # stone at the same magnification. 0.60 puts the band below the inscription.
    Draw-PhotoGround $c.Graphics ($W + 1) ($HC + 1) $Photo $PhotoCentre $PhotoNight 424 0.60
} else {
    Draw-Cabinet $c.Graphics ($W + 1) ($HC + 1) $false
}
Draw-Panel   $c.Graphics 26 12 172 26 6
Draw-DialWell $c.Graphics 204 12 130 26
Seal-Edge $c $Night
Save-Canvas $c 'bg2.png'

# Preview for the skin picker
$full = New-Canvas ($W + 1) ($H + 1)
Draw-Face $full.Graphics
$prev = New-Canvas 215 390
$prev.Graphics.DrawImage($full.Bitmap, 0, 0, 215, 390)
Save-Canvas $prev 'SkinPreview.png'
$full.Graphics.Dispose(); $full.Bitmap.Dispose()

# --- The XML -------------------------------------------------------------------

function Argb ($c) { return "$($c.A),$($c.R),$($c.G),$($c.B)" }

function Build-SkinXml ([bool]$collapsed) {
    if ($collapsed) {
        $height = $HC; $bg = 'bg2.png'
        $listVis = 0; $filterVis = 0; $foundVis = 0; $srcVis = 0
        $statusVis = 0; $bufVis = 0
        # Two rows. The spectrum stays a small well rather than running the
        # width of the strip - collapsed, it should not be a ticker.
        $titleY = 18; $rowY = 52; $keySize = 36; $wbSize = 16
        $titleX = 32; $titleW = 160; $titleSize = 12
        $specX = 210; $specY = 16; $specW = 118; $specH = 20
        $volX = 310; $volY = 58; $volW = 104
        $winBtnY = 17
    } else {
        $height = $H; $bg = 'bg1.png'
        $listVis = 1; $filterVis = 1; $foundVis = 1; $srcVis = 1
        $statusVis = 1; $bufVis = 1
        $titleY = $L.TitleY + 8; $rowY = $L.KeyY; $keySize = $L.KeySize; $wbSize = 26
        $titleX = 38; $titleW = 354; $titleSize = 14
        $specX = 44; $specY = $L.DialY + 12; $specW = 342; $specH = ($L.DialH - 20)
        $volX = 44; $volY = $L.VolY; $volW = 220
        $winBtnY = 20
    }

    $btn = {
        param($name, $x, $y, $sz, $img, $alt)
        $s = @"
  <$name>
    <x>$x</x>
    <y>$y</y>
    <width>$sz</width>
    <height>$sz</height>
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

    # Seven keys in one row: transport on the left, the rest on the right, with
    # a wider gap between the two groups so they read as two jobs.
    $k    = $keySize
    $step = if ($collapsed) { $k + 4 } else { $k + 6 }
    $x0   = if ($collapsed) { 26 } else { 36 }
    $gap  = if ($collapsed) { 0 } else { 18 }
    $keys = @(
        (& $btn 'Play'      $x0                         $rowY $k 'Play'      'Play-2'),
        (& $btn 'Back'      ($x0 + $step)               $rowY $k 'Back'      $null),
        (& $btn 'Next'      ($x0 + $step * 2)           $rowY $k 'Next'      $null),
        (& $btn 'Rec'       ($x0 + $step * 3)           $rowY $k 'Rec'       'Rec-2'),
        (& $btn 'Favorites' ($x0 + $step * 4 + $gap)    $rowY $k 'Favorites' $null),
        (& $btn 'Mute'      ($x0 + $step * 5 + $gap)    $rowY $k 'Mute'      'Mute-2'),
        (& $btn 'Options'   ($x0 + $step * 6 + $gap)    $rowY $k 'Options'   $null)
    ) -join "`n"

    # 20px was too small: the bezel ate the glyph and they read as blank chips.
    $wb   = $wbSize
    $wbX  = 414 - $wb
    $wbSt = if ($collapsed) { $wb + 2 } else { $wb + 6 }
    $winBtns = @(
        (& $btn 'OnTop'    ($wbX - $wbSt * 3) $winBtnY $wb 'OnTop'    'OnTop-2'),
        (& $btn 'Minimize' ($wbX - $wbSt * 2) $winBtnY $wb 'Minimize' $null),
        (& $btn 'Expand'   ($wbX - $wbSt)     $winBtnY $wb 'Expand'   $null),
        (& $btn 'Exit'     $wbX               $winBtnY $wb 'Exit'     $null)
    ) -join "`n"

    $amber   = Argb $Amber
    $bone    = Argb $Bone
    $boneDim = Argb $BoneDim
    $clear   = '0,0,0,0'

    $xml = @"
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!-- $SkinName - a tombstone cabinet for Radio? Sure! Drawn in code. -->
<XMLConfigSettings>
  <Window>
    <text>$SkinName</text>
    <!-- Frame 0 drops the Windows title bar so the cabinet is the whole window.
         It can still be dragged by any bare part of the stone. -->
    <Frame>0</Frame>
    <x>0</x>
    <y>0</y>
    <width>$W</width>
    <height>$height</height>
    <Background>$bg</Background>
    <Rounded>14</Rounded>
  </Window>
$winBtns
$keys
  <Sources>
    <x>44</x>
    <y>$($L.RowY)</y>
    <width>105</width>
    <height>21</height>
    <visible>$srcVis</visible>
    <TextColor>$amber</TextColor>
    <BkColor>$clear</BkColor>
    <TextSize>8</TextSize>
    <TextAlign>0</TextAlign>
    <Image>
      <Normal>Sources.png</Normal>
      <Hot>Sources-hot.png</Hot>
      <Pressed>sources-pressed.png</Pressed>
    </Image>
  </Sources>
  <FilterLabel>
    <x>150</x>
    <y>$($L.RowY + 1)</y>
    <width>19</width>
    <height>19</height>
    <visible>$filterVis</visible>
    <TextColor>$boneDim</TextColor>
    <BkColor>$clear</BkColor>
    <TextSize>9</TextSize>
    <TextAlign>-1</TextAlign>
    <Image>
      <Normal>FilterLabel.png</Normal>
      <Hot>FilterLabel-hot.png</Hot>
      <Pressed>FilterLabel-pressed.png</Pressed>
    </Image>
  </FilterLabel>
  <Filter>
    <x>172</x>
    <y>$($L.RowY + 1)</y>
    <width>104</width>
    <height>19</height>
    <visible>$filterVis</visible>
    <TextColor>$bone</TextColor>
    <BkColor>-1</BkColor>
    <TextSize>9</TextSize>
    <TextAlign>-1</TextAlign>
  </Filter>
  <FoundNumber>
    <x>282</x>
    <y>$($L.RowY + 3)</y>
    <width>112</width>
    <height>14</height>
    <visible>$foundVis</visible>
    <TextColor>$amber</TextColor>
    <BkColor>$clear</BkColor>
    <TextSize>8</TextSize>
    <TextAlign>1</TextAlign>
  </FoundNumber>
  <List>
    <x>40</x>
    <y>$($L.ListY + 6)</y>
    <width>350</width>
    <height>$($L.ListH - 12)</height>
    <visible>$listVis</visible>
    <TextColor>$amber</TextColor>
    <BkColor>255,10,8,9</BkColor>
    <HighLightColor>255,86,44,14</HighLightColor>
    <HighLightTextColor>255,255,206,140</HighLightTextColor>
    <Transparent>0</Transparent>
    <TextSize>9</TextSize>
  </List>
  <RotatedInfo>
    <x>$titleX</x>
    <y>$titleY</y>
    <width>$titleW</width>
    <height>22</height>
    <visible>1</visible>
    <TextColor>$amber</TextColor>
    <GlowColor>$clear</GlowColor>
    <BkColor>$clear</BkColor>
    <TextSize>$titleSize</TextSize>
    <!-- Centred. This control reveals each string with a short animation, so
         a screenshot taken mid-reveal looks like the text is being clipped -
         it is not. TextSize 14 shows a 53-character song line in full at this
         width; it does not need a wider window. -->
    <TextAlign>0</TextAlign>
  </RotatedInfo>
  <Status>
    <x>40</x>
    <y>$($L.MetaY)</y>
    <width>112</width>
    <height>12</height>
    <visible>$statusVis</visible>
    <TextColor>$boneDim</TextColor>
    <BkColor>$clear</BkColor>
    <TextSize>8</TextSize>
    <TextAlign>-1</TextAlign>
  </Status>
  <BufferInfo>
    <x>158</x>
    <y>$($L.MetaY)</y>
    <width>44</width>
    <height>12</height>
    <visible>$bufVis</visible>
    <TextColor>$boneDim</TextColor>
    <BkColor>$clear</BkColor>
    <TextSize>8</TextSize>
    <TextAlign>1</TextAlign>
  </BufferInfo>
  <BufferIndicator>
    <x>298</x>
    <y>$($L.MetaY + 1)</y>
    <width>92</width>
    <height>10</height>
    <visible>$bufVis</visible>
  </BufferIndicator>
  <Spectrum>
    <x>$specX</x>
    <y>$specY</y>
    <width>$specW</width>
    <height>$specH</height>
    <visible>1</visible>
    <!-- The bar colours are BarColorTop/Bottom. There is no <BarColor>; give it
         one and RadioSure ignores it, fills in BarColorTop as -1, and paints
         the bars system green. -->
    <BarColorTop>235,255,196,110</BarColorTop>
    <BarColorBottom>200,214,112,30</BarColorBottom>
    <BkColorTop>0,0,0,0</BkColorTop>
    <BkColorBottom>0,0,0,0</BkColorBottom>
    <BarLineColor>90,20,14,10</BarLineColor>
    <Bars>26</Bars>
    <!-- GlassLevel 0, or a pale sheen is painted over the top of the well and
         reads as a grey box sitting on the dial glass. Frame 0, or the well
         gets a system border around the artwork. -->
    <GlassLevel>0</GlassLevel>
    <Frame>0</Frame>
  </Spectrum>
  <Volume>
    <x>$volX</x>
    <y>$volY</y>
    <width>$volW</width>
    <height>26</height>
    <visible>1</visible>
    <!-- Flat ImageThumb/ImageChannel tags, not a nested <Image> block - the
         nested form is silently ignored for this control. -->
    <ThumbSize>22</ThumbSize>
    <ImageThumb>VolumeThumb.png</ImageThumb>
    <ImageThumbHot>VolumeThumbHot.png</ImageThumbHot>
    <ImageChannel>VolumeChannel.png</ImageChannel>
  </Volume>
  <Author>
    <Name>Claude - $SkinName, a tombstone cabinet</Name>
    <URL>https://github.com/SilentFrequency/radiosure-revival</URL>
  </Author>
</XMLConfigSettings>
"@
    return $xml
}

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin.rsn'),  (Build-SkinXml $false), $enc)
[System.IO.File]::WriteAllText((Join-Path $OutDir 'skin2.rsn'), (Build-SkinXml $true),  $enc)

$n = (Get-ChildItem $OutDir -File).Count
Write-Host "Built '$SkinName' - $n files in $OutDir" -ForegroundColor Green
