param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Script,
    [string[]]$ScriptArgs = @(),
    [switch]$Wait,
    [switch]$SkipCheck,
    [switch]$CheckOnly,
    [switch]$Visible
)

# Elevated runner for scripts (see skill script-safety-gate).
#   - uses PowerShell 7 (pwsh.exe) only, never powershell.exe 5.1
#   - hidden console by default: QuickEdit text selection would freeze the process
#   - runs check-script.ps1 first and REFUSES on failure unless -SkipCheck
#   - -CheckOnly performs the static check only (no UAC prompt)

$ErrorActionPreference = 'Stop'

$pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
if (-not $pwsh) {
    $candidate = Join-Path $PSHOME 'pwsh.exe'
    if (Test-Path $candidate) { $pwsh = $candidate }
}
if (-not $pwsh) {
    throw 'pwsh.exe (PowerShell 7) not found. Install PowerShell 7, or run the script elevated by hand.'
}

$target = (Resolve-Path -LiteralPath $Script).Path

if (-not $SkipCheck) {
    $checker = Join-Path $PSScriptRoot 'check-script.ps1'
    if (-not (Test-Path $checker)) { throw "static checker missing: $checker" }
    $out = & $pwsh -NoProfile -File $checker $target 2>&1
    $code = $LASTEXITCODE
    $out | ForEach-Object { Write-Output $_ }
    if ($code -ne 0) {
        Write-Output 'REFUSED: static check failed. Fix the script, or pass -SkipCheck to override.'
        exit 1
    }
    if ($CheckOnly) {
        Write-Output 'CHECK-ONLY: passed, not elevating.'
        exit 0
    }
}

$argList = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $target) + $ScriptArgs
$params = @{
    FilePath     = $pwsh
    Verb         = 'RunAs'
    ArgumentList = $argList
}
if (-not $Visible) { $params['WindowStyle'] = 'Hidden' }
if ($Wait) { $params['Wait'] = $true }

Write-Output "elevating: $target"
Write-Output ("argv: " + ($argList -join ' '))
Start-Process @params
Write-Output 'UAC prompt issued.'
