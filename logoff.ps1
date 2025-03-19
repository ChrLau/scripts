# Logging out properly is surprisingly click intensive in Windows Server..
# Read: https://learn.microsoft.com/en-us/windows-server/remote/multipoint-services/log-off-or-disconnect-user-sessions
# And a disconnect or just closing the Window leaves the session lingering around, taking up RDP-Licenses
# Which will grant you a telephone call from other people if they need to login
# Additionally most often the logout option is hidden in some companies!?
# Hence we put this on the Desktop and be done with all that
logoff
