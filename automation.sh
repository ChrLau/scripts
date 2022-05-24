#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
# Small script to automate custom shell command execution

VERSION="0.1"
SCRIPT=$(basename "$0")
SSH=$(which ssh)

# Test if ssh is present and executeable
if [ ! -x "$SSH" ]; then
  echo "This script requires ssh to connect to the servers. Exiting."
  exit 2;
fi

function HELP {
  echo "$SCRIPT $VERSION: Execute custom shell commands on lists of hosts"
  echo "Usage: $SCRIPT -l /path/to/host.list -c \"command\" [-u <user>] [-a] [-r]"
  echo ""
  echo "Parameters:"
  echo " -l   Path to the hostlist file, 1 host per line"
  echo " -c   The command to execute. Needs to be in double-quotes. Else getops interprets it as separate arguments"
  echo " -u   (Optional) The user used during SSH-Connection. (Default: \$USER)"
  echo " -a   (Optional) Abort when the ssh-command fails? Use YES or NO (Default: YES)"
  echo " -r   (Optional) When given command will be executed via 'sudo su -c'"
  echo ""
  echo "No arguments or -h will print this help."
  exit 0;
}

# Print help if no arguments are given
if [ "$#" -eq 0 ]; then
  HELP
fi

# Parse arguments
while getopts ":l:c:u:a:hr" OPTION; do
  case "$OPTION" in
    l)
      HOSTLIST="${OPTARG}"
      ;;
    c)
      COMMAND="${OPTARG}"
      ;;
    u)
      SSH_USER="${OPTARG}"
      ;;
    a)
      ABORT="${OPTARG}"
      ;;
    r)
      SUDO="YES"
      ;;
    h)
      HELP
      ;;
    *)
      HELP
      ;;
# Not needed as we use : as starting char in getopts string
#    :)
#      echo "Missing argument"
#      ;;
#    \?)
#      echo "Invalid option"
#      exit 1
#      ;;
  esac
done

# Give usage message and print help if both arguments are empty
if [ -z "$HOSTLIST" ] || [ -z "$COMMAND" ]; then
  echo "You need to specify -l and -c. Exiting."
  exit 1;
fi

# Check if username was provided, if not use $USER environment variable
if [ -z "$SSH_USER" ]; then
  SSH_USER="$USER"
fi

# Check for YES or NO
if [ -z "$ABORT" ]; then
  # If empty, set to YES (default)
  ABORT="YES"
# Check if it's not NO or YES - we want to ensure a definite decision here
elif [ "$ABORT" != "NO" ] && [ "$ABORT" != "YES" ]; then
  echo  "-a accepts either YES or NO (case-sensitive)"
  exit 1;
fi


# Check if hostlist is readable
if [ -r "$HOSTLIST" ]; then
  # Check that hostlist is not 0 bytes
  if [ -s "$HOSTLIST" ]; then

    for HOST in $(cat "$HOSTLIST"); do

      getent hosts "$HOST" &> /dev/null

      # getent returns exit code of 2 if a hostname isn't resolving
      if [ "$?" -ne 0 ]; then
        echo "Host: $HOST is not resolving. Typo? Aborting."
        exit 2
      fi

      echo "Connecting to $HOST ...";
      # Execute command via sudo or not?
      if [ "$SUDO" = "YES" ]; then
        ssh -n -o ConnectTimeout=10 "$SSH_USER"@"$HOST" "sudo su -c '$COMMAND'";
      else
        ssh -n -o ConnectTimeout=10 "$SSH_USER"@"$HOST" "$COMMAND";
      fi

      # Test if command was successful
      if [ "$?" -ne 0 ]; then
        echo -n "Command was NOT successful on $HOST"

        # Shall we proceed or not?
        if [ "$ABORT" = "YES" ]; then
          echo -n -e "... Aborting.\n"
          exit 1
        else
          echo -n -e "... Proceeding, as configured.\n"
        fi
      fi

    done

  else
    echo "Host \"$HOSTLIST\" is empty. Exiting."
    exit 1
  fi

else
  echo "Hostlist \"$HOSTLIST\" is not readable. Exiting."
  exit 1
fi
