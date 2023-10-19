REM Batch-Script to print all stored WLANs and their passwords
REM Useful if you don't remember the password but need to add another device

REM Execute in cmd
@echo off
setlocal enabledelayedexpansion

for /F "tokens=2 delims=:" %%a in (`netsh wlan show profile`) do (
  set wifi_password=
  for /F "tokens=2 delims=: usebackq" %%F IN (`netsh wlan show profile %%a key^=clear ^|find "Key Content"`) do (
    set wifi_password=%%F
  )
  echo %%a : !wifi_password!
)
