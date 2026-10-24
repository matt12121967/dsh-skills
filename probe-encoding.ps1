# probe-encoding.ps1
# ASCII-only on purpose: it must run on a machine whose console encoding is broken.
# Reports the facts that decide every encoding choice on Windows.

$ErrorActionPreference = 'Continue'

function Show($name, $value) {
    '{0,-24} {1}' -f $name, $value
}

'=== encoding probe ==='
Show 'PSVersion' $PSVersionTable.PSVersion.ToString()
Show 'PSEdition' $(if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { 'Desktop' })
Show 'chcp' (((chcp) -join ' ') -replace '[^0-9]', '')
Show 'Console.OutputEncoding' ([Console]::OutputEncoding.WebName)
Show 'Console.InputEncoding' ([Console]::InputEncoding.WebName)
Show 'PYTHONIOENCODING' ([string]$env:PYTHONIOENCODING)

# Build the sample from code points so this file stays pure ASCII.
$cn = [string]::Concat([char]0x4E2D, [char]0x6587)
$tmp = Join-Path $env:TEMP ('encprobe_' + [guid]::NewGuid().ToString('N') + '.txt')

# 1) What does '>' actually write?  FF FE = UTF-16LE (PowerShell 5.1).
$cn > $tmp
$b = [IO.File]::ReadAllBytes($tmp)
$head = ($b[0..([Math]::Min(3, $b.Length - 1))] | ForEach-Object { $_.ToString('X2') }) -join ' '
Show 'redirect(>) bytes' $head

# 2) UTF-8 without BOM, read back both ways.
[IO.File]::WriteAllText($tmp, $cn, (New-Object System.Text.UTF8Encoding($false)))
$raw = [IO.File]::ReadAllBytes($tmp)
Show 'utf8-nobom bytes' (($raw[0..2] | ForEach-Object { $_.ToString('X2') }) -join ' ')

$def = Get-Content $tmp -Raw
Show 'Get-Content default' $(if ($def.Trim() -eq $cn) { 'OK' } else { 'MOJIBAKE' })

$u8 = Get-Content $tmp -Raw -Encoding utf8
Show 'Get-Content -Encoding utf8' $(if ($u8.Trim() -eq $cn) { 'OK' } else { 'MOJIBAKE' })

# 3) Python: find a real interpreter, never the Microsoft Store stub.
$pyExe = $null
$cmd = Get-Command python -ErrorAction SilentlyContinue
if ($cmd -and $cmd.Source -and ($cmd.Source -notlike '*\WindowsApps\*')) { $pyExe = $cmd.Source }
if (-not $pyExe -and $env:DSH_HOME) {
    $rt = Join-Path $env:DSH_HOME 'dsh-runtimes'
    if (Test-Path $rt) {
        $hit = Get-ChildItem $rt -Recurse -Filter python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { $pyExe = $hit.FullName }
    }
}

if ($pyExe) {
    $enc = (& $pyExe -c "import sys;print(sys.stdout.encoding)" 2>&1 | Out-String).Trim()
    Show 'python stdout' $enc
    $null = & $pyExe -c "print(chr(0x4E2D)+chr(0x6587))" 2>&1
    Show 'python print CN' $(if ($LASTEXITCODE -eq 0) { 'OK' } else { 'FAIL (UnicodeEncodeError)' })
} elseif ($cmd) {
    Show 'python' 'STORE-STUB (no real interpreter)'
} else {
    Show 'python' 'not on PATH'
}

Remove-Item $tmp -Force -ErrorAction SilentlyContinue
'=== done ==='
