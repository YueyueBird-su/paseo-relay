@echo off
setlocal EnableExtensions
if not defined PASEO_RELAY_RELEASE_ROOT set "PASEO_RELAY_RELEASE_ROOT=%~dp0..\..\_build\prod\rel\paseo_relay"
if not defined PASEO_RELAY_HOST set "PASEO_RELAY_HOST=10.112.112.91"
if not defined PASEO_RELAY_PORT set "PASEO_RELAY_PORT=4000"
if not defined PASEO_RELAY_ALLOW_LEGACY_BASE64URL set "PASEO_RELAY_ALLOW_LEGACY_BASE64URL=true"
if not defined PASEO_RELAY_MIN_CLUSTER_SIZE set "PASEO_RELAY_MIN_CLUSTER_SIZE=1"
if not defined RELEASE_DISTRIBUTION set "RELEASE_DISTRIBUTION=none"
if not defined RELEASE_COOKIE (
  for /f "delims=" %%C in ('powershell.exe -NoProfile -Command "$b = New-Object byte[] 32; $r = [Security.Cryptography.RandomNumberGenerator]::Create(); $r.GetBytes($b); $r.Dispose(); [BitConverter]::ToString($b).Replace('-', '').ToLowerInvariant()"') do set "RELEASE_COOKIE=%%C"
)
if not defined RELEASE_COOKIE exit /b 1
call "%PASEO_RELAY_RELEASE_ROOT%\bin\paseo_relay.bat" start
exit /b %errorlevel%
