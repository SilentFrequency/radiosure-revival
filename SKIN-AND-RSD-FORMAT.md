# RadioSure file formats — field notes

Everything below was worked out by inspecting the files RadioSure ships with and
testing against the running application (2.2.1042). Where something was verified
by observing the app's own behaviour rather than inferred, it says so.

Corrections welcome. Some of this is not documented anywhere else I could find.

---

## The station database (`.rsd`)

Plain text, **UTF-8**, **LF** line endings, tab-separated. One station per line,
**11 fields**:

```
Title  Description  Genre  Country  Language  Url1  Url2  Url3  Url4  Url5  Url6
```

- Unused URL slots contain a single `-`.
- The six URL slots are alternates for the same station. Merging duplicate
  listings into them is worthwhile: when one stream is dead the others remain.
- A BOM is optional. The stock 2013 database has one (two, actually); the
  radiosure.fr database has none. Both load correctly.

### Line 1 is a header and is discarded

**This is the important one.** RadioSure skips the first line of a `.rsd` and
reads stations from line 2 onward.

Verified directly: a file containing N station lines reports `Stations found: N-1`.
Prepending a timestamp line to the same file makes it report all N.

The consequence is that the official database RadioSure shipped with in 2013 put
a real station on line 1 (`Recorder-radio.com`) and had therefore been silently
dropping it for its entire life. The radiosure.fr database gets this right and
writes a `yyyy-MM-dd HH:mm:ss` timestamp there. Do the same.

### `stations.rsdx`

A one-line XML file in `Stations\` naming the `.rsd` to load:

```xml
<RadioSure> <Stations> <BaseFile><DownloadName></DownloadName><FileName>stations-2026-08-02.rsd</FileName></BaseFile> </Stations> </RadioSure>
```

### Codec support

RadioSure ships a 2013 build of BASS. It plays MP3, AAC, AAC+ and OGG. It cannot
play **HLS** streams or video containers (MP4, FLV, anything H.264). Those are
worth filtering out of a generated database — roughly 4,000 of Radio-Browser's
61,000 entries — because they fail silently rather than reporting an error.

---

## `RadioSure.xml` — handle carefully

Holds favourites, history and settings, as a **single line** of UTF-8 **without
a BOM**. Two ways to destroy it, both of which I managed:

1. **`[xml]::Save()` in PowerShell reformats the entire file** and turns empty
   elements such as `<Filter_5></Filter_5>` into ones containing whitespace.
2. **`Get-Content` reads it as the system code page**, because there is no BOM.
   Round-tripping through that mangles every accented station name — `RTÉ Gold`
   comes back as `RTÃ‰ Gold`, and then gets saved that way.

If you must edit it, read and write bytes as UTF-8 explicitly and do a targeted
string replace. Better: don't. Nothing about updating stations requires it.

### `LastStationsUpdateCheck`

This field gates the app's own updater. Per Philiweb (portablefreeware forum,
Sept 2022):

> If RS is registered then the next update will be "allowed" 24 hours after this
> LastStationsUpdateCheck, and otherwise one week later for the free version.

So paid copies check daily, free copies weekly. Note that a third-party updater
which writes this field can delay the app's own update check.

---

## Skins (`.rsn`)

A skin is a **folder** named `<SkinName>.rsn` inside `Skins\`, containing PNGs
and two XML files. The name RadioSure shows, and stores in `RadioSure.xml`, is
the folder name without the extension.

| File | Purpose |
|---|---|
| `skin.rsn` | Layout for the **expanded** window |
| `skin2.rsn` | Layout for the **collapsed** window |
| `SkinPreview.png` | Thumbnail for the skin picker |

**The window is not a fixed size.** The stock skin is 490×346 expanded and
490×100 collapsed, and it is easy to assume those numbers are the format. They
are not — `<width>` and `<height>` inside `<Window>` set whatever you like, and
every control is positioned in absolute pixels within it. Skins in this repo run
at 620×560 and 900×620. If you want a big cabinet, take one.

One authoring detail: the background PNG is a pixel larger than the declared
window in each direction (a 620×560 window ships a 621×561 background). Match
that and the edge lands cleanly.

`skin2.rsn` is the same document with a smaller height, buttons moved up, and
the list, filter and found-count set to `<visible>0</visible>`. A skin without it
will not collapse properly.

### Press F5 to reload

RadioSure re-reads the skin live when you press **F5**. Edit `skin.rsn`, press
F5, see the result. This makes skinning genuinely pleasant instead of a
restart-per-change slog.

### Colours

`A,R,G,B` — alpha first, 0–255 each. `-1` means "use the system default".

```xml
<BarColorTop>255,255,196,96</BarColorTop>
<BkColor>-1</BkColor>
```

### The window

```xml
<Window>
  <text>Radiation King</text>
  <Frame>1</Frame>
  <width>490</width>
  <height>346</height>
  <Background>Background.png</Background>
  <Rounded>0</Rounded>
</Window>
```

- **`<Background>` accepts a PNG filename**, not just a colour. This is how you
  get a full custom cabinet instead of a grey dialog. Verified by testing.
- `<Frame>0</Frame>` removes the Windows title bar for a borderless look.

Remember that child controls sit **on top** of the background: the list, the
spectrum and the buttons will cover most of a 490×346 canvas. Only the strips
around and between them actually show.

### Buttons

Each button takes three images, by convention `Name.png`, `Name-hot.png`,
`Name-pressed.png`:

```xml
<Play>
  <x>9</x> <y>303</y> <width>33</width> <height>34</height>
  <visible>1</visible>
  <Image>
    <Normal>Play.png</Normal>
    <Hot>Play-hot.png</Hot>
    <Pressed>Play-pressed.png</Pressed>
  </Image>
  <AltImage>
    <Normal>Play-2.png</Normal>
    ...
  </AltImage>
</Play>
```

`<AltImage>` is the toggled state — Play/Stop, Mute/Unmute, Record on/off,
Always-on-top on/off.

**Author button art at 256×256.** The stock skin does, and RadioSure scales it
down to the 33×34 the layout asks for. The oversized source keeps edges clean.
`Sources` is the odd one out at 1200×256.

### The controls a skin can position

`Exit` `Options` `Mute` `Favorites` `Rec` `Next` `Back` `Play` `Sources`
`FilterLabel` `Filter` `Minimize` `List` `FoundNumber` `Spectrum` `BufferInfo`
`BufferIndicator` `Status` `Volume` `RotatedInfo` `Expand` `SongTitle` `OnTop`

Useful specifics:

- `List` takes `TextColor`, `BkColor`, `HighLightColor`, `HighLightTextColor`
  and `Transparent`. Dark text on a warm cream background is far more readable
  at small sizes than the default, and suits a period look.
- `Spectrum` takes top/bottom bar colours, top/bottom background colours,
  `Bars`, `GlassLevel` (0–255) and `Frame`.
- `BufferIndicator` has **no colour options** — it is drawn by the system and
  will be green whatever your palette is. Plan around it or hide it.
- `RotatedInfo` is the scrolling station/track text, which suits being placed on
  a tuning-dial strip.

### Gotchas when generating skins from PowerShell

- `$home` is a **read-only automatic variable**; assigning to it aborts the
  script with a confusing error.
- A hashtable key shadows the property of the same name, so `$h.Count` returns
  the value of a key called `count` if one exists. Use `$h.PSBase.Count`.
- Keep generator scripts pure ASCII, or save them UTF-8 **with** BOM. Windows
  PowerShell reads BOM-less scripts as the system code page and mangles any
  non-ASCII string literals.

## The window is always a rectangle

A skin cannot be a shaped window. If you were hoping to cut a player out to the
silhouette of its artwork — a radio, a headstone, anything with a profile — it
is not available, and it is worth knowing before you draw for it.

- **Alpha in the background PNG is not honoured as window transparency.**
  Pixels at alpha 0 composite to **white**, not to the desktop. Tested by
  building a skin whose background was 16% fully transparent: the transparent
  region rendered as a solid white ground filling the window rectangle.
- **`<Rounded>` is a corner radius, not a mask.** It rounds the corners of the
  rectangle and nothing more. There is no path, region or mask field.
- **`<Transparent>` exists but belongs to `<List>`**, not to `<Window>` — it
  controls the station list's background, not the window shape.

The practical consequence: whatever sits around your artwork is part of the
skin and has to be *designed*, not wished away. Give it something deliberate —
a ground, a shadow, a surround that reads as intentional — because the rectangle
is going to be visible no matter what you put in the alpha channel.
