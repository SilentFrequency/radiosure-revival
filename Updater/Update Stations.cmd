@echo off
REM Double-click this to refresh RadioSure's station list from Radio-Browser.
REM Close RadioSure first. Takes about a minute.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-RadioSureStations.ps1"
