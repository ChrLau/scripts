#!/bin/bash

# Checks if keepalived has the MASTER or BACKUP state
# Note: Script currently assumes that:
#  - There is only 1 virtual_ipaddress block in the whole keepalived config file
#  - The virtual_ipaddress block has only 1 IPv4 IP configured
#  - This configured IP is only present on a network interface if the node has the state MASTER
#    (Which is the normal behaviour anyway, but I've seen weird stuff..)

keepalivedps=$(pgrep -u root -f "/usr/sbin/keepalived" -c)
keepalivedconf="/etc/keepalived/keepalived.conf"
# Set checkifup to be NOT 0 or 1 so the if statement will fail if it's not set
checkifup=3
state=""

# Check for optional command line parameter
if [[ -n "$1" ]]; then

  # Enforce precise naming
  if [[ "$1" == "MASTER" ]] || [[ "$1" == "BACKUP" ]]; then
    state="$1"
  else
    echo "Valid parameters (case-sensitive) are: MASTER or BACKUP"
    echo "Note: If a parameter is given script will exit with 0 if given state matches keepaliveds running state."
    echo "      Otherwise it will exit with 1."
    echo "      If no parameter is given it will echo the state."
    exit 1
  fi

fi


if [[ "$keepalivedps" -gt 1 ]]; then

  if [[ -r $keepalivedconf ]]; then
    virtualip=$(grep 'virtual_ipaddress {' -A 10 $keepalivedconf | grep -B 500 -m1 "}" | grep -Eo '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' )
    virtualipnr=$(echo -n "$virtualip" | grep -c '^')
    
    if [[ "$virtualipnr" -eq 1 ]]; then
      checkifup=$(ip a |grep -cPo "$virtualip/")

      if [[ "$checkifup" -eq 1 ]]; then
        role=MASTER
      elif [[ "$checkifup" -eq 0 ]]; then
        role=BACKUP

        if [[ -n "$state" ]]; then

          if [[ "$state" == "$role" ]]; then
            echo "Given state matches running state"
            exit 0
          else
            echo "Given state does not match running state"
            exit 1
          fi

        else
          echo "Role: $role"
        fi

      else
        echo "Couldn't check if node is MASTER or BACKUP (checkifup is not 0 or 1). Aborting."
        exit 1
      fi

    elif [[ "$virtualipnr" -gt 1 ]]; then
      echo "More than 1 virtual_ipaddress found in $keepalivedconf. Script currently can't safely handle this. Aborting."
      exit 1
    else
      echo "virtual_ipaddress not found in /etc/keepalived/keepalived.conf. Aborting."
      exit 1
    fi

  else
    echo "$keepalivedconf not readable. Aborting."
    exit 1
  fi

else
  echo "keepalived not running."
  exit 1
fi
