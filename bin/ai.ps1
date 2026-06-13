#!/usr/bin/env pwsh
# AI CLI Pult — PowerShell uchun wrapper.
# Git Bash'ni PATH'dan yoki odatiy o'rnatish joylaridan topadi.
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'ai-selector.sh'

$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
if (-not $bash) {
  foreach ($p in @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )) {
    if (Test-Path $p) { $bash = $p; break }
  }
}
if (-not $bash) {
  Write-Error "bash topilmadi. Git for Windows o'rnating: https://git-scm.com/download/win"
  exit 127
}

& $bash $script @args
exit $LASTEXITCODE
