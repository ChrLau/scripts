# Press the Scrolllock-Key every 280 seconds to prevent the automatic screen locking
$WShell = New-Object -Com "Wscript.shell"
while (1) {$WShell.SendKeys("{SCROLLLOCK}"); sleep 280}
