# If the computer isn't locked:
# Press the Scrolllock-Key every 280 seconds to prevent the automatic screen locking
$WShell = New-Object -Com "Wscript.shell"
while (1) {
  # Check if the logonui process is running - which is only the case when the Lockscreen is up
  if ( Get-Process logonui -ErrorAction SilentlyContinue ) {
    # Computer is locked, do nothing and check again
    sleep 280;
  } else {
    # Computer is unlocked
    $WShell.SendKeys("{SCROLLLOCK}");
    sleep 280;
  }
}

