@echo off
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "ProcmonConverter-Production-Ready-20251105-214531\Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1" -InputDirectory "ProcmonConverter-Production-Ready-20251105-214531\Data\SampleData" -OutputDirectory "ProcmonConverter-Production-Ready-20251105-214531\Ultimate-Analysis-Reports"
pause

