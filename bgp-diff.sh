#!/bin/bash

# bgp-diff.sh
# This script executes an "vtysh -c 'show ip bgp summary'" on both nodes of a clustered loadbalancer-pair
# Printing out the differences
# Useful for first troubleshooting or when doing config rollouts

# TODO:
# - Add functionality for checking advertised-routes to neighbors
#   Like: "vtysh -c 'show ip bgp neigh ip.ip.ip.ip advert'"

# Set this to the username you wish to use:
# Default is executing user
SSHUSER="$USER"

if [ "$#" != "1" ]; then
  echo -e "Usage: $0 hostname (without node-identifier)\nExample: $0 ipkeepalive05 (for diffing ipkeepalive05a and ipkeepalive05b)" 
  exit 1
fi

# RegEx for catching only valid IPs:
#grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" 

getent hosts "${1}a" "${1}b" &> /dev/null

# getent returns exit code of 2 if a hostname isn't resolving
if [ $? -ne 0 ]; then
  echo "One of the provided hostnames is not resolving, please check."
  exit 2
fi

ssh -q "$SSHUSER@${1}a" exit
if [ $? -ne 0 ]; then
  echo "You don't have rights to log on as $SSHUSER via SSH on ${1}a, please check."
  exit 3
fi

ssh -q "$SSHUSER@${1}b" exit
if [ $? -ne 0 ]; then
  echo "You don't have rights to log on as $SSHUSER via SSH on ${1}b, please check."
  exit 3
fi

echo -e "Diffing: $1\n"

diff -B -y --suppress-common-lines <(ssh "$SSHUSER@${1}a" vtysh -c 'show ip bgp summary' | cut -c 1-90) <(ssh "$SSHUSER@${1}b" vtysh -c 'show ip bgp summary' | cut -c 1-90)

