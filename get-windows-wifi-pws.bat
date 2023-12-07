REM Batch-Script to print all stored WLANs and their passwords
REM Useful if you don't remember the password but need to add another device

REM TODO: Don't list WLAN networks without a password (useful if you connected to many open hotspots)

REM Execute in cmd with admin rights
@echo off
setlocal enabledelayedexpansion

for /F "tokens=2 delims=:" %%a in ('netsh wlan show profile') do (
  set wifi_password=
  for /F "tokens=2 delims=: usebackq" %%F IN (`netsh wlan show profile %%a key^=clear ^|find "Key Content"`) do (
    set wifi_password=%%F
  )
  echo %%a : !wifi_password!
)
