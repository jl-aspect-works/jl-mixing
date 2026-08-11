# Internal Windows launcher for the authoritative JL Mixing Python runtime.
# Public .cmd shims pass a Python module name followed by the original CLI args.
$ErrorActionPreference = 'Stop'

if ($args.Count -lt 1) {
    [Console]::Error.WriteLine('Error: internal JL Mixing launcher requires a Python module name.')
    exit 2
}

$module = [string]$args[0]
$commandArgs = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($env:JL_MIXING_HOME)) {
    $appRoot = [IO.Path]::GetFullPath((Join-Path $scriptDir '..\..'))
} else {
    $appRoot = [IO.Path]::GetFullPath($env:JL_MIXING_HOME)
}

$python = $env:JL_MIXING_PYTHON
if ([string]::IsNullOrWhiteSpace($python)) {
    $bundledPython = Join-Path $appRoot 'runtime\python.exe'
    if (Test-Path -LiteralPath $bundledPython -PathType Leaf) {
        $python = $bundledPython
    } else {
        $pythonCommand = Get-Command python.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $pythonCommand) {
            $pythonCommand = Get-Command python -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($null -ne $pythonCommand) {
            $python = $pythonCommand.Source
        }
    }
}

if ([string]::IsNullOrWhiteSpace($python) -or -not (Test-Path -LiteralPath $python -PathType Leaf)) {
    [Console]::Error.WriteLine('Error: JL Mixing Python runtime was not found.')
    exit 3
}

$sourceRoot = Join-Path $appRoot 'src'
$existingPythonPath = $env:PYTHONPATH
$hasSourceRoot = $false
if (-not [string]::IsNullOrEmpty($existingPythonPath)) {
    foreach ($entry in ($existingPythonPath -split ';')) {
        if ([string]::Equals($entry, $sourceRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $hasSourceRoot = $true
            break
        }
    }
}
if (-not $hasSourceRoot) {
    $env:PYTHONPATH = if ([string]::IsNullOrEmpty($existingPythonPath)) {
        $sourceRoot
    } else {
        "$sourceRoot;$existingPythonPath"
    }
}

& $python '-m' $module @commandArgs
exit $LASTEXITCODE
