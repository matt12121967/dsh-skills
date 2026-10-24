# lessons.ps1 - portable lessons library maintenance. No python, ASCII-only source.
#
#   lessons.ps1 stats               summary: entries, due, overdue, evidence mix
#   lessons.ps1 due [-Date YYYY-MM-DD]
#   lessons.ps1 list                id + title
#   lessons.ps1 mark <ID> -Grade N  SM-2 review result (N = 0..5)
#   lessons.ps1 validate            ids unique, metadata present, dates valid
#   lessons.ps1 init                add missing metadata lines (idempotent)
#   lessons.ps1 new -Title "..."    append a five-part skeleton with metadata
#
# Library path: $env:DSH_HOME\lessons-learned.md, else %USERPROFILE%\.dsh\lessons-learned.md

param(
    [Parameter(Position = 0)]
    [ValidateSet('stats', 'due', 'list', 'mark', 'validate', 'init', 'new')]
    [string]$Command = 'stats',

    [Parameter(Position = 1)]
    [string]$Id,

    [ValidateRange(0, 5)]
    [int]$Grade = 3,

    [string]$Title,
    [string]$Date,
    [int]$FirstDueDays = 3,
    [string]$File
)

$ErrorActionPreference = 'Stop'
$Inv = [Globalization.CultureInfo]::InvariantCulture

# Chinese labels built from code points so this file stays pure ASCII.
function U([int[]]$cp) { return (-join ($cp | ForEach-Object { [char]$_ })) }
$L_SCENE   = (U 0x573A, 0x666F) + [char]0xFF1A   # chang jing
$L_LESSON  = (U 0x6559, 0x8BAD) + [char]0xFF1A   # jiao xun
$L_PREVENT = (U 0x9884, 0x9632) + [char]0xFF1A   # yu fang
$L_APPLY   = (U 0x9002, 0x7528) + [char]0xFF1A   # shi yong
$L_EXPIRE  = (U 0x5931, 0x6548, 0x6761, 0x4EF6) + [char]0xFF1A  # shi xiao tiao jian
$EV_NONE   = (U 0x672A, 0x6807, 0x6CE8)          # wei biao zhu
$EV_TESTED = (U 0x5B9E, 0x6D4B)                  # shi ce

if (-not $File) {
    $base = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
    $File = Join-Path $base 'lessons-learned.md'
}

function Get-Today {
    if ($Date) { return [datetime]::ParseExact($Date, 'yyyy-MM-dd', $null) }
    return (Get-Date).Date
}

function Read-Doc {
    if (-not (Test-Path $File)) {
        return [pscustomobject]@{ Exists = $false; Text = ''; Bom = $false }
    }
    $bytes = [IO.File]::ReadAllBytes($File)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ($bom) { $text = $text.TrimStart([char]0xFEFF) }
    return [pscustomobject]@{ Exists = $true; Text = $text; Bom = $bom }
}

function Save-Doc($text, $doc) {
    $enc = New-Object System.Text.UTF8Encoding($doc.Bom)
    [IO.File]::WriteAllText($File, $text, $enc)
}

function Get-Entries($text) {
    $lines = $text -split "`r?`n"
    $entries = New-Object System.Collections.ArrayList

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^###\s+(\d{4}-\d{2}-\d{2})\s+(.+)$') { continue }
        $e = [pscustomobject]@{
            Index = $i; Date = $matches[1]; Title = $matches[2].Trim(); MetaLine = -1
            Id = $null; Evidence = $null; Last = $null; Due = $null; Ease = 2.5; Reps = 0
        }
        $limit = [Math]::Min($i + 4, $lines.Count - 1)
        for ($j = $i + 1; $j -le $limit; $j++) {
            if ($lines[$j] -match '^<!--\s*lesson\s+(.+?)\s*-->') {
                $e.MetaLine = $j
                foreach ($pair in [regex]::Matches($matches[1], '([A-Za-z_]+)=(\S+)')) {
                    $k = $pair.Groups[1].Value
                    $v = $pair.Groups[2].Value
                    switch ($k) {
                        'id'       { $e.Id = $v }
                        'evidence' { $e.Evidence = $v }
                        'last'     { $e.Last = $v }
                        'due'      { $e.Due = $v }
                        'ease'     { $e.Ease = [double]::Parse($v, $Inv) }
                        'reps'     { $e.Reps = [int]$v }
                    }
                }
                break
            }
            if ($lines[$j].Trim().Length -gt 0) { break }
        }
        [void]$entries.Add($e)
    }
    return , $entries.ToArray()
}

function New-Id($entries, $day) {
    $prefix = 'L-' + $day + '-'
    $max = 0
    foreach ($e in $entries) {
        if ($e.Id -and $e.Id.StartsWith($prefix)) {
            $n = 0
            if ([int]::TryParse($e.Id.Substring($prefix.Length), [ref]$n)) { if ($n -gt $max) { $max = $n } }
        }
    }
    return $prefix + ('{0:D2}' -f ($max + 1))
}

function Format-Meta($e) {
    return '<!-- lesson id=' + $e.Id + ' evidence=' + $e.Evidence + ' last=' + $e.Last +
           ' due=' + $e.Due + ' ease=' + $e.Ease.ToString('0.00', $Inv) + ' reps=' + $e.Reps + ' -->'
}

$doc = Read-Doc
if (-not $doc.Exists -and $Command -ne 'new') {
    Write-Host "no lessons file at $File" -ForegroundColor Yellow
    exit 1
}
if (-not $doc.Exists -and $Command -eq 'new') {
    $doc = [pscustomobject]@{
        Exists = $true; Bom = $false
        Text = "# Lessons learned`r`n`r`n> Maintained by lessons-hub: append on task end, check due at session start.`r`n"
    }
}

$entries = Get-Entries $doc.Text
$today = Get-Today

switch ($Command) {

    'list' {
        foreach ($e in $entries) {
            $id = if ($e.Id) { $e.Id } else { '(no id)' }
            Write-Host ("{0,-18} {1}  {2}" -f $id, $e.Date, $e.Title)
        }
        Write-Host ("entries: " + $entries.Count)
    }

    'due' {
        $rows = @()
        foreach ($e in $entries) {
            if (-not $e.Due) { continue }
            $d = [datetime]::ParseExact($e.Due, 'yyyy-MM-dd', $null)
            if ($d -le $today) {
                $rows += [pscustomobject]@{
                    Id = $e.Id; Due = $e.Due; Overdue = [int]($today - $d).TotalDays; Title = $e.Title
                }
            }
        }
        if ($rows.Count -eq 0) { Write-Host 'nothing due'; break }
        $rows | Sort-Object Due | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
        Write-Host ("due: " + $rows.Count)
    }

    'stats' {
        $withMeta = @($entries | Where-Object { $_.MetaLine -ge 0 }).Count
        $overdue = 0
        $dueToday = 0
        foreach ($e in $entries) {
            if (-not $e.Due) { continue }
            $d = [datetime]::ParseExact($e.Due, 'yyyy-MM-dd', $null)
            if ($d -lt $today) { $overdue++ } elseif ($d -eq $today) { $dueToday++ }
        }
        $ev = $entries | Group-Object Evidence | ForEach-Object { "$($_.Name)=$($_.Count)" }
        Write-Host ("file:      " + $File)
        Write-Host ("entries:   " + $entries.Count)
        Write-Host ("with meta: " + $withMeta)
        Write-Host ("due today: " + $dueToday)
        Write-Host ("overdue:   " + $overdue)
        Write-Host ("evidence:  " + ($ev -join ', '))
    }

    'validate' {
        $errors = New-Object System.Collections.ArrayList
        $seen = @{}
        foreach ($e in $entries) {
            if ($e.MetaLine -lt 0) { [void]$errors.Add("$($e.Date) '$($e.Title)' : missing metadata"); continue }
            if (-not $e.Id) { [void]$errors.Add("$($e.Date) '$($e.Title)' : missing id") }
            elseif ($seen.ContainsKey($e.Id)) { [void]$errors.Add("duplicate id $($e.Id)") }
            else { $seen[$e.Id] = $true }
            foreach ($d in @($e.Last, $e.Due)) {
                if ($d) {
                    try { [void][datetime]::ParseExact($d, 'yyyy-MM-dd', $null) }
                    catch { [void]$errors.Add("$($e.Id) : bad date '$d'") }
                }
            }
        }
        if ($errors.Count -eq 0) { Write-Host ("validate: ok, " + $entries.Count + " entries") -ForegroundColor Green; exit 0 }
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        Write-Host ("validate: " + $errors.Count + " error(s)") -ForegroundColor Red
        exit 1
    }

    'init' {
        if (-not $doc.Exists) {
            $doc = [pscustomobject]@{ Exists = $true; Text = "# Lessons learned`r`n`r`n> Maintained by lessons-hub.`r`n"; Bom = $false }
            $entries = Get-Entries $doc.Text
        }
        $lines = New-Object System.Collections.ArrayList
        $doc.Text -split "`r?`n" | ForEach-Object { [void]$lines.Add($_) }

        $todo = @($entries | Where-Object { $_.MetaLine -lt 0 } | Sort-Object Index -Descending)
        $added = 0
        foreach ($e in $todo) {
            $day = $e.Date
            $e.Id = New-Id (Get-Entries (($lines -join "`n"))) $day
            $e.Evidence = $EV_NONE
            $e.Last = $day
            $e.Due = [datetime]::ParseExact($day, 'yyyy-MM-dd', $null).AddDays($FirstDueDays).ToString('yyyy-MM-dd')
            $e.Ease = 2.5
            $e.Reps = 0
            $meta = Format-Meta $e
            $insertAt = $e.Index + 1
            $lines.Insert($insertAt, $meta)
            if ($insertAt + 1 -ge $lines.Count -or $lines[$insertAt + 1].Trim().Length -gt 0) { $lines.Insert($insertAt + 1, '') }
            $added++
        }
        if ($added -eq 0) { Write-Host 'init: nothing to add'; break }
        Save-Doc ($lines -join "`r`n") $doc
        Write-Host ("init: added metadata to $added entr(ies)")
    }

    'mark' {
        if (-not $Id) { Write-Host 'mark needs an id' -ForegroundColor Red; exit 1 }
        $e = $entries | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
        if (-not $e) { Write-Host "id not found: $Id" -ForegroundColor Red; exit 1 }

        $oldInterval = 1
        if ($e.Last -and $e.Due) {
            try {
                $oldInterval = [int]([datetime]::ParseExact($e.Due, 'yyyy-MM-dd', $null) -
                                     [datetime]::ParseExact($e.Last, 'yyyy-MM-dd', $null)).TotalDays
            } catch { $oldInterval = 1 }
        }
        if ($oldInterval -lt 1) { $oldInterval = 1 }

        if ($Grade -lt 3) {
            $reps = 0; $interval = 1
        } else {
            $reps = $e.Reps + 1
            if ($reps -eq 1) { $interval = 1 }
            elseif ($reps -eq 2) { $interval = 6 }
            else { $interval = [int][math]::Round($oldInterval * $e.Ease) }
            $e.Ease = $e.Ease + (0.1 - (5 - $Grade) * (0.08 + (5 - $Grade) * 0.02))
            if ($e.Ease -lt 1.3) { $e.Ease = 1.3 }
        }
        $e.Reps = $reps
        $e.Last = $today.ToString('yyyy-MM-dd')
        $e.Due = $today.AddDays($interval).ToString('yyyy-MM-dd')
        if (-not $e.Evidence) { $e.Evidence = $EV_TESTED }

        $lines = New-Object System.Collections.ArrayList
        $doc.Text -split "`r?`n" | ForEach-Object { [void]$lines.Add($_) }
        $lines[$e.MetaLine] = Format-Meta $e
        Save-Doc ($lines -join "`r`n") $doc
        Write-Host ("mark: " + $e.Id + " grade=" + $Grade + " reps=" + $e.Reps + " ease=" + $e.Ease.ToString('0.00', $Inv) + " due=" + $e.Due)
    }

    'new' {
        if (-not $Title) { Write-Host 'new needs -Title' -ForegroundColor Red; exit 1 }
        $day = $today.ToString('yyyy-MM-dd')
        $entries = Get-Entries $doc.Text
        $e = [pscustomobject]@{
            Id = New-Id $entries $day; Evidence = $EV_NONE; Last = $day
            Due = $today.AddDays($FirstDueDays).ToString('yyyy-MM-dd'); Ease = 2.5; Reps = 0
            Date = $day; Title = $Title
        }
        $block = @()
        $block += ''
        $block += '### ' + $day + ' ' + $Title
        $block += (Format-Meta $e)
        $block += ''
        $block += '- ' + $L_SCENE
        $block += '- ' + $L_LESSON
        $block += '- ' + $L_PREVENT
        $block += '- ' + $L_APPLY
        $block += '- ' + $L_EXPIRE
        $text = $doc.Text
        if ($text -and -not $text.EndsWith("`n")) { $text += "`r`n" }
        $text += ($block -join "`r`n") + "`r`n"
        if (-not $doc.Exists) { $doc = [pscustomobject]@{ Exists = $true; Bom = $false } }
        Save-Doc $text $doc
        Write-Host ("new: " + $e.Id + " due=" + $e.Due)
    }
}
