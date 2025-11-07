@echo off
cd /d "%~dp0"
pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command ".\Test-PathFix.ps1"
pause

