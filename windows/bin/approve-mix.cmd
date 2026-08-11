@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0jl-mixing-python-command.ps1" "jl_mixing.approve_mix_cli" %*
exit /b %ERRORLEVEL%
