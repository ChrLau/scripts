#!/bin/bash

# keepalie-diff.sh
# This script executes a "ipvsadm -L -n --sort | cut -c 1-40" and both nodes of a clustered loadbalancer-pair
# Printing out the differences
# Useful for first troubleshooting or when doing config rollouts

HOST=$1

# No arguments? Print help
if [ "$#" -eq  "0" ]; then
  echo -e "Usage: $0 hostname [user]\nExample: $0 ipkeepalive05 (for diffing ipkeepalive05a and ipkeepalive05b)\nUsername is optional." 
  exit 1
# 2nd arugment is not zero chars long? Use that as username
elif [ -n "$2" ]; then
  # If a username is provided as 2nd argument, we use that one
  SSHUSER=$2
else
  # Default is the executing user
  SSHUSER=$USER
fi


echo -e "Diffing: $HOST\n"

diff -B -y --suppress-common-lines <(ssh "$SSHUSER@${HOST}a" ipvsadm -L -n --sort | cut -c 1-40) <(ssh "$SSHUSER@${HOST}b" ipvsadm -L -n --sort | cut -c 1-40)
