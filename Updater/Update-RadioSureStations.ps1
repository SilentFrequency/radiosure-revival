################################################################################
#  Update-RadioSureStations.ps1                                                #
#                                                                              #
#  Rebuilds RadioSure's station database (.rsd) from the free, community-run    #
#  Radio-Browser directory (https://www.radio-browser.info).                    #
#                                                                              #
#  RadioSure's own server died in March 2022, so its built-in updater is dead.  #
#  Run this whenever you want a fresh list. Close RadioSure first.              #
#                                                                              #
#  .rsd format (tab separated, one station per line, UTF-8, LF endings):        #
#     Title <tab> Description <tab> Genre <tab> Country <tab> Language          #
#           <tab> Url1 ... Url6            (unused URL slots are a "-")         #
################################################################################

[CmdletBinding()]
param(
    # Folder containing RadioSure.exe. Defaults to where this script lives.
    [string] $RadioSureDir = $PSScriptRoot,

    # Cap the number of stations (keeps the most popular). 0 = no limit.
    [int]    $MaxStations = 0,

    # Build the .rsd but do not touch the RadioSure install.
    [switch] $DryRun,

    # Keep the downloaded CSV for inspection.
    [switch] $KeepCsv,

    # Unattended mode for the scheduled task: no pauses, writes to a log file,
    # and quietly defers instead of failing when RadioSure is open or the
    # database is already fresh.
    [switch] $Scheduled,

    # In -Scheduled mode, skip the run if the database is newer than this.
    [int]    $MinIntervalDays = 6,

    # RadioSure.xml (favourites, history, settings) is copied here on every
    # successful run. Set to '' to turn the backup off.
    [string] $BackupDir = '',

    # How many dated RadioSure.xml snapshots to keep.
    [int]    $KeepBackups = 12
)

$ErrorActionPreference = 'Stop'

# Radio-Browser mirrors, tried in order. "all" is a round-robin DNS pool that
# always points at a live server; the named host is the fallback if the pool
# entry itself misbehaves. Do not hard-code a longer list - the project adds and
# retires servers, and as of this writing there is only one behind the pool.
$Mirrors = @(
    'https://all.api.radio-browser.info',
    'https://de1.api.radio-browser.info'
)
$UserAgent = 'RadioSureStationUpdater/1.0'

# The server rate-limits repeated bulk downloads with a 503, so back off and
# retry rather than failing the whole run.
$RetryWaits = @(15, 45, 90)

if (-not $RadioSureDir) { $RadioSureDir = (Get-Location).Path }
$LogPath = Join-Path $RadioSureDir 'update-log.txt'

# In scheduled mode nobody is watching the console, so everything also goes to
# a log file and the "press on, here is what happened" pauses are skipped.
function Write-Log ($msg) {
    if (-not $Scheduled) { return }
    try {
        $line = "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $msg
        Add-Content -Path $LogPath -Value $line -Encoding UTF8
    } catch { }
}
function Pause-IfInteractive ($seconds) {
    if (-not $Scheduled) { Start-Sleep -Seconds $seconds }
}

function Write-Step ($msg) { Write-Host "  $msg" -ForegroundColor Gray;   Write-Log $msg }
function Write-Good ($msg) { Write-Host "  $msg" -ForegroundColor Green;  Write-Log $msg }
function Write-Warn ($msg) { Write-Host "  $msg" -ForegroundColor Yellow; Write-Log "WARN: $msg" }
function Write-Bad  ($msg) { Write-Host "  $msg" -ForegroundColor Red;    Write-Log "FAIL: $msg" }

Write-Host ""
Write-Host " RadioSure station database updater " -BackgroundColor DarkBlue -ForegroundColor White
Write-Host ""

# --- Sanity checks ------------------------------------------------------------

$stationsDir = Join-Path $RadioSureDir 'Stations'

if (-not $DryRun) {
    if (-not (Test-Path (Join-Path $RadioSureDir 'RadioSure.exe'))) {
        Write-Bad "RadioSure.exe not found in: $RadioSureDir"
        Write-Bad "Put this script in the RadioSure folder, or pass -RadioSureDir."
        Pause-IfInteractive 20
        exit 1
    }

    # Already fresh? Nothing to do. This is what makes "retry later" safe: the
    # scheduled task can fire repeatedly through the day and only the first
    # successful run of the week does any work.
    if ($Scheduled -and (Test-Path $stationsDir)) {
        $current = Get-ChildItem -Path $stationsDir -Filter 'stations*.rsd' -File |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($current -and ((Get-Date) - $current.LastWriteTime).TotalDays -lt $MinIntervalDays) {
            $age = [math]::Round(((Get-Date) - $current.LastWriteTime).TotalDays, 1)
            Write-Log "Skipped: database is $age days old, minimum interval is $MinIntervalDays."
            exit 0
        }
    }

    if (Get-Process RadioSure -ErrorAction SilentlyContinue) {
        if ($Scheduled) {
            # Deferred, not failed. The task fires again in two hours; sooner or
            # later it will catch a moment when the player is closed.
            Write-Log "Deferred: RadioSure is running. Will try again on the next fire."
            exit 0
        }
        Write-Bad "RadioSure is running. Close it first, then re-run this script."
        Pause-IfInteractive 20
        exit 1
    }
}

if ($Scheduled) { Write-Log "--- Scheduled run starting ---" }

$workDir     = Join-Path $env:TEMP 'RadioSureUpdate'
if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir | Out-Null }
$csvPath = Join-Path $workDir 'radiobrowser.csv'

# --- Download -----------------------------------------------------------------

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$downloaded = $false
for ($round = 0; $round -le $RetryWaits.Count; $round++) {

    if ($round -gt 0) {
        $wait = $RetryWaits[$round - 1]
        Write-Warn "Waiting $wait seconds before retrying (the server throttles bulk downloads) ..."
        Start-Sleep -Seconds $wait
    }

    foreach ($mirror in $Mirrors) {
        $url = "$mirror/csv/stations/search?hidebroken=true&limit=200000"
        try {
            Write-Step "Downloading station list from $mirror ..."
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $csvPath -UserAgent $UserAgent -TimeoutSec 300
            $progressPreference = 'Continue'
            $downloaded = $true
            break
        } catch {
            Write-Warn "Mirror failed: $($_.Exception.Message)"
        }
    }

    if ($downloaded) { break }
}

if (-not $downloaded) {
    Write-Bad "Could not reach Radio-Browser after several attempts."
    Write-Bad "Your existing station list has been left untouched. Try again later."
    Pause-IfInteractive 20
    exit 1
}

$csvSizeMb = [math]::Round((Get-Item $csvPath).Length / 1MB, 1)
if ($csvSizeMb -lt 5) {
    Write-Bad "Downloaded file is only ${csvSizeMb}MB - that looks wrong. Aborting so your"
    Write-Bad "existing station list is left alone."
    Pause-IfInteractive 20
    exit 1
}
Write-Good "Downloaded ${csvSizeMb}MB."

# --- Parse and filter ---------------------------------------------------------

Write-Step "Parsing ..."
$rows = Import-Csv -Path $csvPath
Write-Good "$($rows.Count) stations in the directory."

# Strip characters that would corrupt a tab-separated file, and collapse runs of
# whitespace. Some station names in the directory genuinely contain tabs.
function Clean ([string] $s) {
    if ([string]::IsNullOrEmpty($s)) { return '' }
    $s = $s -replace '[\t\r\n]', ' '
    $s = $s -replace '\s+', ' '
    return $s.Trim()
}

$textInfo = (Get-Culture).TextInfo

# Title case a tag, without mangling decade names: plain ToTitleCase turns
# "80s" into "80S" and "60er" into "60Er", which looks wrong in the Genre column.
function TitleCase ([string] $s) {
    $t = $textInfo.ToTitleCase($s.ToLowerInvariant())
    return [regex]::Replace($t, '(?<=\d)[A-Z]', { param($m) $m.Value.ToLowerInvariant() })
}

# Radio-Browser reports full ISO country names. "United Kingdom Of Great Britain
# And Northern Ireland" is useless in RadioSure's narrow Country column, and the
# names people actually type into the filter box are the short ones.
$CountryMap = @{
    'United States Of America'                          = 'USA'
    'United Kingdom Of Great Britain And Northern Ireland' = 'United Kingdom'
    'Russian Federation'                                = 'Russia'
    'Republic Of Korea'                                 = 'South Korea'
    'Democratic Peoples Republic Of Korea'              = 'North Korea'
    'Islamic Republic Of Iran'                          = 'Iran'
    'Bolivarian Republic Of Venezuela'                  = 'Venezuela'
    'Plurinational State Of Bolivia'                    = 'Bolivia'
    'United Republic Of Tanzania'                       = 'Tanzania'
    'Republic Of Moldova'                               = 'Moldova'
    'Republic Of North Macedonia'                       = 'North Macedonia'
    'Syrian Arab Republic'                              = 'Syria'
    'Lao Peoples Democratic Republic'                   = 'Laos'
    'Democratic Republic Of The Congo'                  = 'Congo (DR)'
    'Taiwan, Republic Of China'                         = 'Taiwan'
    'Viet Nam'                                          = 'Vietnam'
    'Czechia'                                           = 'Czech Republic'
    'Turkiye'                                           = 'Turkey'
    'Republic Of Serbia'                                = 'Serbia'
    'Brunei Darussalam'                                 = 'Brunei'
    'Cabo Verde'                                        = 'Cape Verde'
    'Myanmar'                                           = 'Myanmar (Burma)'
}

# RadioSure ships BASS 2013: no HLS, no video containers. Streams it cannot play
# are worse than absent - they just fail silently when clicked.
$unplayable = '(H\.264|FLV|MP4)'

Write-Step "Filtering out streams this build of RadioSure cannot play ..."
$playable = New-Object System.Collections.ArrayList
foreach ($r in $rows) {
    if ($r.lastcheckok -ne '1') { continue }
    if ($r.hls -eq '1')         { continue }
    if ($r.codec -match $unplayable) { continue }
    $u = $r.url_resolved
    if ([string]::IsNullOrWhiteSpace($u)) { $u = $r.url }
    if ([string]::IsNullOrWhiteSpace($u)) { continue }
    if (-not ($u -match '^https?://')) { continue }
    [void]$playable.Add($r)
}
Write-Good "$($playable.Count) playable streams."

# --- Merge duplicates ---------------------------------------------------------
# The same station is often listed several times with different stream URLs.
# The .rsd format has six URL slots per station precisely for this: RadioSure
# falls back to the next URL when one is dead. So group by name+country and
# fold the duplicates into alternates instead of throwing them away.

Write-Step "Merging duplicate listings into alternate stream slots ..."
$groups = @{}
foreach ($r in $playable) {
    $key = (Clean $r.name).ToLowerInvariant() + '|' + $r.countrycode
    if (-not $groups.ContainsKey($key)) {
        $groups[$key] = New-Object System.Collections.ArrayList
    }
    [void]$groups[$key].Add($r)
}
Write-Good "$($groups.PSBase.Count) distinct stations after merging."

# Tags are free text, so a station can be tagged both "disco" and
# "la guapachosa fm". Counting how often each tag is used across the whole
# directory lets the Genre column show the real genres first and push
# one-off vanity tags to the end.
Write-Step "Ranking tags by how widely they are used ..."
$tagFreq = @{}
foreach ($r in $playable) {
    if (-not $r.tags) { continue }
    foreach ($t in ($r.tags -split ',')) {
        $t = (Clean $t).ToLowerInvariant()
        if (-not $t) { continue }
        if ($tagFreq.ContainsKey($t)) { $tagFreq[$t]++ } else { $tagFreq[$t] = 1 }
    }
}
# PSBase, because a hashtable key shadows the property of the same name and
# some station out there is genuinely tagged "count".
Write-Good "$($tagFreq.PSBase.Count) distinct tags."

# --- Build the .rsd lines -----------------------------------------------------

Write-Step "Building station records ..."
$records = New-Object System.Collections.ArrayList

foreach ($entry in $groups.GetEnumerator()) {
    $dupes = $entry.Value

    # Most-voted listing supplies the display metadata and the primary stream.
    # Sorting is skipped for the common case of a station listed only once.
    if ($dupes.Count -eq 1) {
        $ranked = $dupes
    } else {
        $ranked = $dupes | Sort-Object { [int]$_.votes } -Descending
    }
    $best = $ranked[0]

    $title = Clean $best.name
    if (-not $title) { continue }

    # Collect unique stream URLs across the duplicates, best-voted first.
    $urls = New-Object System.Collections.ArrayList
    $seenUrls = @{}
    foreach ($d in $ranked) {
        foreach ($cand in @($d.url_resolved, $d.url)) {
            if ([string]::IsNullOrWhiteSpace($cand)) { continue }
            $c = Clean $cand
            if (-not ($c -match '^https?://')) { continue }
            $norm = $c.ToLowerInvariant().TrimEnd('/')
            if ($seenUrls.ContainsKey($norm)) { continue }
            $seenUrls[$norm] = $true
            [void]$urls.Add($c)
            if ($urls.Count -ge 6) { break }
        }
        if ($urls.Count -ge 6) { break }
    }
    if ($urls.Count -eq 0) { continue }

    # Tags -> Genre (top three) and the full tag list -> Description, both
    # ordered by how common the tag is so real genres lead.
    $rawTags = New-Object System.Collections.ArrayList
    $seenTags = @{}
    foreach ($d in $dupes) {
        foreach ($t in ($d.tags -split ',')) {
            $t = (Clean $t).ToLowerInvariant()
            if (-not $t) { continue }
            if ($seenTags.ContainsKey($t)) { continue }
            $seenTags[$t] = $true
            [void]$rawTags.Add($t)
        }
    }

    if ($rawTags.Count -gt 1) {
        $ordered = $rawTags | Sort-Object { -$tagFreq[$_] }
    } else {
        $ordered = $rawTags
    }

    $tagList = New-Object System.Collections.ArrayList
    foreach ($t in $ordered) { [void]$tagList.Add((TitleCase $t)) }

    if ($tagList.Count -gt 0) {
        $genre = ($tagList | Select-Object -First 3) -join '/'
    } else {
        $genre = ' '
    }

    # Description: what the station plays, then the stream quality, then its site.
    # RadioSure's filter box searches this, so more detail here means better search.
    $descParts = New-Object System.Collections.ArrayList
    if ($tagList.Count -gt 0) {
        [void]$descParts.Add((($tagList | Select-Object -First 8) -join ', '))
    }
    $quality = Clean $best.codec
    if ($quality -and $quality -ne 'UNKNOWN') {
        if ([int]$best.bitrate -gt 0) { $quality = "$quality $($best.bitrate)k" }
        [void]$descParts.Add("[$quality]")
    }
    # NB: not $home - that is a read-only PowerShell automatic variable.
    $homeUrl = Clean $best.homepage
    if ($homeUrl) { [void]$descParts.Add("($homeUrl)") }

    if ($descParts.Count -gt 0) { $desc = $descParts -join ' ' } else { $desc = '-' }
    if ($desc.Length -gt 250) { $desc = $desc.Substring(0, 250) }

    $country = Clean $best.country
    $country = $country -replace '^The\s+', ''
    if ($CountryMap.ContainsKey($country)) { $country = $CountryMap[$country] }
    # Matched by pattern rather than as a map key: this script is kept pure
    # ASCII so Windows PowerShell reads it correctly whatever the code page.
    if ($country -match '^T.rkiye$') { $country = 'Turkey' }
    if (-not $country) { $country = ' ' }

    $language = Clean (($best.language -split ',')[0])
    if ($language) { $language = TitleCase $language }
    else { $language = ' ' }

    # Pad the six URL slots with "-", exactly as the original 2013 database did.
    $slots = @('-', '-', '-', '-', '-', '-')
    for ($i = 0; $i -lt $urls.Count; $i++) { $slots[$i] = $urls[$i] }

    $popularity = [int]$best.votes + [int]$best.clickcount

    [void]$records.Add([PSCustomObject]@{
        Title      = $title
        Popularity = $popularity
        Line       = (@($title, $desc, $genre, $country, $language) + $slots) -join "`t"
    })
}

if ($MaxStations -gt 0 -and $records.Count -gt $MaxStations) {
    Write-Step "Trimming to the $MaxStations most popular stations ..."
    $records = $records | Sort-Object Popularity -Descending | Select-Object -First $MaxStations
}

$lines = $records | Sort-Object Title | Select-Object -ExpandProperty Line
Write-Good "$($lines.Count) station records built."

# --- Write the .rsd -----------------------------------------------------------

$stamp   = Get-Date -Format 'yyyy-MM-dd'
$rsdName = "stations-$stamp.rsd"

if ($DryRun) {
    $outDir = $workDir
} else {
    $outDir = $stationsDir
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
}
$rsdPath = Join-Path $outDir $rsdName

Write-Step "Writing $rsdName ..."
# UTF-8 without a BOM, LF line endings.
#
# The first line of a .rsd is a HEADER that RadioSure discards - it reads
# stations from line 2 onward. Verified directly: a file of N station lines
# reports N-1 stations found, and the same file with a timestamp prepended
# reports all N. The database RadioSure shipped with in 2013 had a station on
# line 1 and had therefore been quietly dropping it ever since. Write the
# timestamp, exactly as the radiosure.fr community database does.
$encoding = New-Object System.Text.UTF8Encoding($false)
$writer = New-Object System.IO.StreamWriter($rsdPath, $false, $encoding)
$writer.NewLine = "`n"
try {
    $writer.WriteLine((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    foreach ($line in $lines) { $writer.WriteLine($line) }
} finally {
    $writer.Close()
}

$rsdMb = [math]::Round((Get-Item $rsdPath).Length / 1MB, 1)
Write-Good "Wrote ${rsdMb}MB to $rsdPath"

if ($DryRun) {
    Write-Host ""
    Write-Warn "Dry run: your RadioSure install was not touched."
    Write-Host ""
    exit 0
}

# --- Install ------------------------------------------------------------------

# Keep the outgoing database rather than deleting it, so a bad update is one
# file copy away from being undone.
$previousDir = Join-Path $stationsDir '_previous'
$old = Get-ChildItem -Path $stationsDir -Filter 'stations*.rsd' -File |
       Where-Object { $_.Name -ne $rsdName }
if ($old) {
    if (-not (Test-Path $previousDir)) { New-Item -ItemType Directory -Path $previousDir | Out-Null }
    foreach ($f in $old) {
        Move-Item -Path $f.FullName -Destination (Join-Path $previousDir $f.Name) -Force
        Write-Step "Previous database moved to _previous\$($f.Name)"
    }
}

# The .rsdx tells RadioSure which .rsd to load.
$rsdxPath = Join-Path $stationsDir 'stations.rsdx'
$rsdx = "<RadioSure> <Stations> <BaseFile><DownloadName></DownloadName><FileName>$rsdName</FileName></BaseFile> </Stations> </RadioSure>"
[System.IO.File]::WriteAllText($rsdxPath, $rsdx, (New-Object System.Text.UTF8Encoding($false)))
Write-Good "Pointed stations.rsdx at $rsdName"

# RadioSure.xml is deliberately left alone. It holds your favourites, history
# and settings, and rewriting it here cost more than it was worth:
#   * [xml]::Save() reformats the whole file and turns empty elements such as
#     <Filter_5></Filter_5> into ones containing whitespace,
#   * Get-Content on Windows PowerShell reads the BOM-less UTF-8 file as the
#     system code page, so accented station names ("RTE Gold") come back
#     double-encoded and get written that way,
#   * the only field worth writing is LastStationsUpdateCheck, which matters
#     solely to an update server that has been offline since 2022.
# Nothing about this script's job requires touching it.

if (-not $KeepCsv) { Remove-Item $csvPath -ErrorAction SilentlyContinue }

# --- Back up the favourites ---------------------------------------------------
# The station database rebuilds itself in two minutes; RadioSure.xml holds the
# favourites, history and settings, and is the only irreplaceable file here.
# Copied, never modified - see the note above about why this script does not
# write to it.

if ($BackupDir) {
    try {
        $xmlPath = Join-Path $RadioSureDir 'RadioSure.xml'
        if (Test-Path $xmlPath) {
            if (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            }
            $stampName = "RadioSure_{0:yyyy-MM-dd_HHmm}.xml" -f (Get-Date)
            Copy-Item $xmlPath (Join-Path $BackupDir $stampName) -Force
            Copy-Item $xmlPath (Join-Path $BackupDir 'RadioSure_latest.xml') -Force

            # Keep the most recent N dated snapshots, drop the rest.
            $old = Get-ChildItem -Path $BackupDir -Filter 'RadioSure_2*.xml' -File |
                   Sort-Object LastWriteTime -Descending | Select-Object -Skip $KeepBackups
            foreach ($f in $old) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue }

            Write-Good "Favourites backed up to $BackupDir"
        }
    } catch {
        # A backup failing must never take the update down with it.
        Write-Warn "Could not back up RadioSure.xml ($($_.Exception.Message))."
    }
}

Write-Host ""
Write-Good "Done. $($lines.Count) stations installed. Start RadioSure."
Write-Host ""
if ($Scheduled) { Write-Log "--- Scheduled run finished OK ---" }
Pause-IfInteractive 5
