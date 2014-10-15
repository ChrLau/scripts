#!/bin/bash

# keepalie-diff.sh
# This script executes a "ipvsadm -L -n --sort | cut -c 1-40" and both nodes of a clustered loadbalancer-pair
# Printing out the differences
# Useful for first troubleshooting or when doing config rollouts

HOST=$1

if [ -n "$2" ]; then
  # If a username is provided as 2nd argument, we use that one
  SSHUSER=$2
else
  # Default is executing user
  SSHUSER=$USER
fi



if [ "$#" != "1" ]; then
  echo -e "Usage: $0 hostname [user]\nExample: $0 ipkeepalive05 (for diffing ipkeepalive05a and ipkeepalive05b)\nUsername is optional." 
  exit 1
fi

echo -e "Diffing: $1\n"

diff -B -y --suppress-common-lines <(ssh "$SSHUSER@${HOST}a" ipvsadm -L -n --sort | cut -c 1-40) <(ssh "$SSHUSER@${HOST}b" ipvsadm -L -n --sort | cut -c 1-40)
