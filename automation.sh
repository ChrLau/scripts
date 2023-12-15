#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
# Small script to automate custom shell command execution
# Current version can be found here:
# https://github.com/ChrLau/scripts/blob/master/automation.sh

VERSION="1.3"
SCRIPT=$(basename "$0")
SSH=$(command -v ssh)
# Colored output
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Test if ssh is present and executeable
if [ ! -x "$SSH" ]; then
  echo "This script requires ssh to connect to the servers. Exiting."
  exit 2;
fi

function HELP {
  echo "$SCRIPT $VERSION: Execute custom shell commands on lists of hosts"
  echo "Usage: $SCRIPT -l /path/to/host.list -c \"command\" [-u <user>] [-a] [-r] [-s \"options\"]"
  echo ""
  echo "Parameters:"
  echo " -l   Path to the hostlist file, 1 host per line"
  echo " -c   The command to execute. Needs to be in double-quotes. Else getops interprets it as separate arguments."
  echo " -u   (Optional) The user used during SSH-Connection. (Default: \$USER)"
  echo " -a   (Optional) Abort run when the execution fails on a host? Use YES or NO (Default: YES)"
  echo " -r   (Optional) When given command will be executed via 'sudo su -c'"
  echo " -s   (Optional) Any SSH parameters you want to specify. Needs to be in double-quotes. (Default: empty)"
  echo "                 Example: -s \"-i /home/user/.ssh/id_user\""
  echo ""
  echo "No arguments or -h will print this help."
  exit 0;
}

# Print help if no arguments are given
if [ "$#" -eq 0 ]; then
  HELP
fi

# Parse arguments
while getopts ":l:c:u:a:hrs:" OPTION; do
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
    s)
      SSH_PARAMS="${OPTARG}"
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
      # shellcheck disable=SC2181
      if [ "$?" -ne 0 ]; then
        echo -e "${RED}Host: $HOST is not resolving. Typo? Aborting.${ENDCOLOR}"
        exit 2
      fi

      echo -e "${GREEN}Connecting to $HOST ...${ENDCOLOR}";
      # Execute command via sudo or not?
      if [ "$SUDO" = "YES" ]; then
        ssh -n -o ConnectTimeout=10 "${SSH_PARAMS}" "$SSH_USER"@"$HOST" "sudo su -c '${COMMAND}'";
      else
        ssh -n -o ConnectTimeout=10 "${SSH_PARAMS}" "$SSH_USER"@"$HOST" "${COMMAND}";
      fi

      # Test if command was successful
      # shellcheck disable=SC2181
      if [ "$?" -ne 0 ]; then
        echo -n -e "${RED}Command was NOT successful on $HOST... ${ENDCOLOR}"

        # Shall we proceed or not?
        if [ "$ABORT" = "YES" ]; then
          echo -n -e "${RED}Aborting.${ENDCOLOR}\n"
          exit 1
        else
          echo -n -e "${GREEN}Proceeding, as configured.${ENDCOLOR}\n"
        fi
      fi

    done

  else
    echo -e "${RED}Hostlist \"$HOSTLIST\" is empty. Exiting.${ENDCOLOR}"
    exit 1
  fi

else
  echo -e "${RED}Hostlist \"$HOSTLIST\" is not readable. Exiting.${ENDCOLOR}"
  exit 1
fi
