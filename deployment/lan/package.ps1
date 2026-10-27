param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repoRoot 'dist' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
$name = "agentero-lan-relay-windows-$arch"
$stage = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
$bundle = Join-Path $stage $name
$oldMixEnv = $env:MIX_ENV
Push-Location $repoRoot
try {
    $env:MIX_ENV = 'prod'
    & mix release --overwrite
    if ($LASTEXITCODE -ne 0) { throw 'mix release failed' }
    New-Item -ItemType Directory -Force -Path (Join-Path $bundle 'deployment\lan'), $OutputDirectory | Out-Null
    Copy-Item -Recurse -Path '_build\prod\rel\paseo_relay' -Destination (Join-Path $bundle 'release')
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $bundle 'release\releases\COOKIE')
    Copy-Item 'LICENSE' $bundle
    Copy-Item 'deployment\lan\run.cmd', 'deployment\lan\README.md' (Join-Path $bundle 'deployment\lan')
    @'
@echo off
setlocal
set "PASEO_RELAY_RELEASE_ROOT=%~dp0release"
call "%~dp0deployment\lan\run.cmd"
exit /b %errorlevel%
'@ | Set-Content -Encoding ascii -Path (Join-Path $bundle 'start.cmd')
    $archive = Join-Path $OutputDirectory "$name.zip"
    Compress-Archive -Path $bundle -DestinationPath $archive -Force
    Write-Output $archive
} finally {
    Pop-Location
    $env:MIX_ENV = $oldMixEnv
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}
