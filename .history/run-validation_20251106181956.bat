@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Test-ExecutiveSummaryValidation.ps1"
pause

