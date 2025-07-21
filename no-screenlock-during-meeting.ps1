# Press the Scrolllock-Key every 280 seconds to prevent the automatic screen locking

# Check Powershell Executionpolicy
if ( $(Get-Executionpolicy) -eq "Unrestricted" ) {
  Write-Host "This script doesn't work with an ExecutionPolicy of Restricted. Aborting."
}

# If the computer isn't locked:
# Press the Scrolllock-Key every 280 seconds to prevent the automatic screen locking
$WShell = New-Object -Com "Wscript.shell"
while (1) {
  # Check if the logonui process is running - which is only the case when the Lockscreen is up
  if ( Get-Process logonui -ErrorAction SilentlyContinue ) {
    # Computer is locked, do nothing
  } else {
    # Computer is unlocked, press SCOLLLOCK key
    $WShell.SendKeys("{SCROLLLOCK}");
  }
  # Sleep for 280 seconds
  sleep 280;
}

