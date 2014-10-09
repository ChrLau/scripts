#!/bin/bash

# keepalie-diff.sh
# This script executes a "ipvsadm -L -n --sort | cut -c 1-40" and both nodes of a clustered loadbalancer-pair
# Printing out the differences
# Useful for first troubleshooting or when doing config rollouts

# Set this to the username you wish to use:
# Default is executing user
SSHUSER=$USER

if [ "$#" != "1" ]; then
  echo -e "Usage: $0 hostname (without node-identifier)\nExample: $0 ipkeepalive05 (for diffing ipkeepalive05a and ipkeepalive05b)" 
  exit 1
fi

echo -e "Diffing: $1\n"

diff -B -y --suppress-common-lines <(ssh $SSHUSER@${1}a ipvsadm -L -n --sort | cut -c 1-40) <(ssh $SSHUSER@${1}b ipvsadm -L -n --sort | cut -c 1-40)
