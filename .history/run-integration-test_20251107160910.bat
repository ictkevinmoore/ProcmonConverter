@echo off
cd /d "%~dp0\ProcmonConverter-Production-Ready-20251105-214531"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1" -InputDirectory "Data\SampleData" -OutputDirectory "Ultimate-Analysis-Reports"
pause

