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

