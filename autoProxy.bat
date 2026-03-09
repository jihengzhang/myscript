@echo off
REM Smart Proxy Configuration - Auto detect, clear, or status
REM Usage:
REM   autoProxy.bat         - Show current proxy status only
REM   autoProxy.bat auto    - Auto detect and configure
REM   autoProxy.bat clear   - Force clear proxy (direct connection)
REM   autoProxy.bat status  - Show current proxy status only

if /i "%1"=="clear" (
    PowerShell -ExecutionPolicy Bypass -File "%~dp0autoProxy.ps1" -Clear
) else if /i "%1"=="status" (
    PowerShell -ExecutionPolicy Bypass -File "%~dp0autoProxy.ps1" -Status
) else if /i "%1"=="auto" (
    PowerShell -ExecutionPolicy Bypass -File "%~dp0autoProxy.ps1" -Auto
) else (
    PowerShell -ExecutionPolicy Bypass -File "%~dp0autoProxy.ps1" -Status
)
pause
