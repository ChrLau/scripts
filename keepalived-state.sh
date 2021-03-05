#!/bin/bash

# Checks if keepalived has the MASTER or BACKUP state
# Note: Currently assumes there is only 1 virtual_ipaddress block in the whole config with only 1 IPv4 IP

keepalivedps=$(pgrep -u root -f "/usr/sbin/keepalived" -c)
keepalivedconf="/etc/keepalived/keepalived.conf"
# Set checkifup to be NOT 0 or 1 so the if statement will fail if it's not set
checkifup=3

if [[ "$keepalivedps" -gt 1 ]]; then

  if [[ -r $keepalivedconf ]]; then
    virtualip=$(grep 'virtual_ipaddress {' -A 10 $keepalivedconf | grep -B 500 -m1 "}" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

    if [[ "$virtualip" -eq 1 ]]; then
      checkifup=$(ip a |grep -cPo "$virtualip/")

      if [[ "$checkifup" -eq 1 ]]; then
        role=MASTER
        echo "Role: $role"
      elif [[ "$checkifup" -eq 0 ]]; then
        role=BACKUP
        echo "Role: $role"
      else
        echo "Couldn't check if node is MASTER or BACKUP (checkifup is not 0 or 1). Aborting."
        exit 1
      fi

    elif [[ "$virtualip" -gt 1 ]]; then
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
