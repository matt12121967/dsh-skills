# install.ps1 - install this repo's skills into the DSH skills folder.
#
#   From a clone:   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   From anywhere:  powershell -ExecutionPolicy Bypass -Command "irm <raw-url>/install.ps1 | iex"
#
#   -List                 show available skills
#   -Only a,b             install only these
#   -Target <dir>         override destination
#   -Force                overwrite existing files

param(
    [string]$Repo,
    [string]$Branch = 'main',
    [string]$Target = $(if ($env:DSH_HOME) { Join-Path $env:DSH_HOME 'skills' } else { Join-Path $env:USERPROFILE '.dsh\skills' }),
    [string[]]$Only,
    [switch]$Force,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

# Filled in after the repo exists. Override with -Repo owner/name.
$DefaultRepo = '__OWNER__/dsh-skills'
if (-not $Repo) { $Repo = $DefaultRepo }

function Get-SkillsDir {
    $local = Join-Path $PSScriptRoot 'skills'
    if (Test-Path $local) { return $local }

    if ($Repo -like '__*') {
        throw "No local skills folder, and repo is not configured yet. Pass -Repo owner/name."
    }

    $stamp = [guid]::NewGuid().ToString('N')
    $zip = Join-Path $env:TEMP ("dsh-skills-$stamp.zip")
    $dst = Join-Path $env:TEMP ("dsh-skills-$stamp")
    $url = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"

    Write-Host "downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $dst -Force
    Remove-Item $zip -Force -ErrorAction SilentlyContinue

    $root = Get-ChildItem $dst -Directory | Select-Object -First 1
    return (Join-Path $root.FullName 'skills')
}

$src = Get-SkillsDir
$files = Get-ChildItem $src -Filter *.md | Sort-Object Name

if ($List) {
    Write-Host "available:"
    $files | ForEach-Object { Write-Host ("  " + [IO.Path]::GetFileNameWithoutExtension($_.Name)) }
    return
}

$dshHome = Split-Path $Target -Parent
if (-not (Test-Path $dshHome)) {
    Write-Host "WARN: $dshHome does not exist. Start the DSH client once for this user, then rerun." -ForegroundColor Yellow
}
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }

$wanted = @()
if ($Only) { $files = $files | Where-Object { $Only -contains [IO.Path]::GetFileNameWithoutExtension($_.Name) } }

foreach ($f in $files) {
    $dest = Join-Path $Target $f.Name
    if ((Test-Path $dest) -and (-not $Force)) {
        Write-Host ("SKIP (exists) " + $f.Name) -ForegroundColor DarkGray
    } else {
        Copy-Item $f.FullName $dest -Force
        Write-Host ("OK           " + $f.Name) -ForegroundColor Green
    }
    $wanted += $f.Name
}

Write-Host ""
Write-Host ("target: " + $Target)
Write-Host ("count:  " + $wanted.Count)
