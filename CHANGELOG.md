# Changelog

## 2026-09-01 — Hallows Eve fits a 1080 screen, and you can read it

Both Hallows Eve skins are re-cut. **If you installed them before today, replace
the folder** — the old ones ran off the bottom of a 1080-high screen.

### Fixed: the window was taller than the screen

The skins were authored at 430×780. On a display running at 150% scaling that
becomes 1170 physical pixels tall, against a screen only 1080 tall — and
RadioSure does not resize itself to fit, so the bottom of the cabinet simply fell
off, transport buttons included. It was fine at 100% scaling, which is why it got
missed.

Now **366×663** (994 physical at 150%), which clears the taskbar. Nothing was
redrawn — the artwork is authored at full size and resampled once at the end, so
every proportion is exactly as before.

`Build-HallowsEveSkin.ps1` takes a **`-Fit`** parameter for this, default `0.85`.
On a taller screen, `-Fit 1.0` gives you the original size back.

### Fixed: the now-playing line was too small

It was meant to be the one thing readable across the room and it wasn't. The text
box was claiming 19px of a 29px bar. Now it takes the bar's full height, and the
type goes from 12 to **17**.

### Fixed: "Stations found" was invisible

At size 7 you had to lean into the screen to see it. Now **11**, in a box grown
from 12 to 20px tall.

13 would be better still, and the box was set there first — but the label
RadioSure writes is `Stations found: NNNNN`, and at 13 the count truncated. The
filter strip only gives this control 112px and there is exactly **1 pixel** spare
to its right, so 11 is the ceiling without taking width off the filter input
beside it. Left as-is deliberately.

### Also

- Rounding in the fit pass is pinned to `AwayFromZero`, and `-Fit` is a `[double]`
  rather than a `[single]`. As float32, 0.85 stores fractionally *above* 0.85,
  which flipped any measurement landing exactly on a .5 midpoint — so two runs
  could disagree by a pixel. Rebuilds are reproducible now.
- Button art is untouched by the fit pass on purpose. RadioSure scales button
  images to their element rectangle, so the 256×256 sources stay sharp at any
  `-Fit` value. This is why the skins can be re-cut without redrawing anything.

### A note on the photo skin

The headstone photo was cropped at the authoring machine's screen size so the
skin would sit over the matching wallpaper and blend into it. Re-cutting to 85%
breaks that alignment — the skin no longer lines up with the wallpaper behind it.
That is a deliberate trade: fitting the screen and being usable beats the overlay
trick, and the wallpaper still ships for anyone who wants it.

### Also fixed: the script wrote to a folder that usually doesn't exist

`Build-HallowsEveSkin.ps1` defaulted `-OutDir` to `%LOCALAPPDATA%\RadioSure\Skins`.
RadioSure is portable and keeps its settings next to the executable, so on most
machines that folder is not there.

With no `-OutDir` it now writes `<SkinName>.rsn` **beside the script** — which is
where the built skins live in this repo, so a rebuild simply refreshes the
published copy — and prints where to copy it. To build straight into the player,
pass the path:

```powershell
.\Build-HallowsEveSkin.ps1 -OutDir "D:\RadioSure\Skins\Hallows Eve.rsn"
```
