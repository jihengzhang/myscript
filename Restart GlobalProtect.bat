@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Self-elevate to Administrator
>nul 2>&1 net session
if %errorlevel% neq 0 (
  echo Re-launching with Administrator privileges...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: Ensure the service exists
sc query "PanGPS" >nul 2>&1
if errorlevel 1 (
  echo Service 'PanGPS' not found. Is GlobalProtect installed?
  exit /b 1
)

:: Clear network cache and reset
echo Flushing DNS cache...
ipconfig /flushdns >nul

echo Resetting IP...
netsh int ip reset >nul

echo Resetting Winsock...
netsh winsock reset >nul

:: Stop if running
for /f "tokens=4" %%A in ('sc query "PanGPS" ^| find "STATE"') do set "STATE=%%A"
if /I "!STATE!"=="RUNNING" (
  echo Stopping PanGPS...
  sc stop "PanGPS" >nul
  call :wait_state "PanGPS" "STOPPED" 20 || (
    echo Timeout waiting for service to stop.
    exit /b 1
  )
)

:: Start and wait to RUNNING
echo Starting PanGPS...
sc start "PanGPS" >nul
call :wait_state "PanGPS" "RUNNING" 20 || (
  echo Failed to start or timeout waiting for RUNNING.
  exit /b 1
)

echo PanGPS restarted successfully.
exit /b 0

:wait_state
:: %1 service name, %2 target state (RUNNING/STOPPED), %3 timeout seconds
set "SRV=%~1"
set "TARGET=%~2"
set /a SECS=%~3
:wait_loop
sc query "%SRV%" | find /I "%TARGET%" >nul
if not errorlevel 1 exit /b 0
if %SECS% LEQ 0 exit /b 1
timeout /t 1 /nobreak >nul
set /a SECS-=1
goto :wait_loop