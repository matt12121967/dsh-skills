param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path
)

# Static checks for PowerShell scripts before they are executed.
#   1. file must be pure ASCII (PS 5.1 would decode non-ASCII as ANSI -> mojibake)
#   2. file must parse without syntax errors
#   3. every "-f" format expression must have enough arguments for its placeholders
# Exit 0 = PASS, 1 = FAIL.
$ErrorActionPreference = 'Stop'
$full = (Resolve-Path -LiteralPath $Path).Path
$fail = $false

# ---------- 1. ASCII ----------
$bytes = [System.IO.File]::ReadAllBytes($full)
$nonAscii = 0
for ($i = 0; $i -lt $bytes.Length; $i++) { if ($bytes[$i] -gt 127) { $nonAscii++ } }
if ($nonAscii -gt 0) {
    Write-Output ("FAIL [ascii] {0} non-ASCII byte(s) in {1}" -f $nonAscii, $full)
    $fail = $true
} else {
    Write-Output 'OK   [ascii] pure ASCII'
}

# ---------- 2. parse ----------
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($full, [ref]$null, [ref]$parseErrors)
if ($parseErrors -and $parseErrors.Count -gt 0) {
    Write-Output ("FAIL [parse] {0} syntax error(s)" -f $parseErrors.Count)
    $parseErrors | Select-Object -First 5 | ForEach-Object {
        Write-Output ("       line {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message)
    }
    $fail = $true
    Write-Output 'RESULT: FAIL'
    exit 1
}
Write-Output 'OK   [parse] no syntax errors'

# ---------- 3. -f placeholder arity ----------
$formatOps = $ast.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.BinaryExpressionAst] -and
        $n.Operator -eq [System.Management.Automation.Language.TokenKind]::Format
    }, $true)

$checked = 0
foreach ($op in $formatOps) {
    $left = $op.Left
    if ($left -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) { continue }
    $maxIndex = -1
    foreach ($m in [regex]::Matches($left.Value, '\{(\d+)')) {
        $idx = [int]$m.Groups[1].Value
        if ($idx -gt $maxIndex) { $maxIndex = $idx }
    }
    if ($maxIndex -lt 0) { continue }

    $right = $op.Right
    $argCount = 1
    if ($right -is [System.Management.Automation.Language.ArrayLiteralAst]) {
        $argCount = $right.Elements.Count
    }
    $checked++
    if ($maxIndex -ge $argCount) {
        Write-Output ("FAIL [format] line {0}: needs {1} arg(s) for {{0}}..{{{2}}}, got {3}" -f `
                $op.Extent.StartLineNumber, ($maxIndex + 1), $maxIndex, $argCount)
        Write-Output ("       source: " + ($op.Extent.Text -replace '\s+', ' '))
        $fail = $true
    }
}
if (-not $fail -or $checked -gt 0) { Write-Output ("OK   [format] {0} format expression(s) checked" -f $checked) }

if ($fail) {
    Write-Output 'RESULT: FAIL'
    exit 1
}
Write-Output 'RESULT: PASS'
exit 0
