#!/bin/bash

# bgp-diff.sh
# This script executes an "vtysh -c 'show ip bgp summary'" and "vtysh -c 'show ip bgp neigh ip.ip.ip.ip advert'" on both nodes of a clustered loadbalancer-pair
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

# RegEx for catching only valid IPs:
#grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" 

# Still have to decide whats the best way..
# a) Do it directly via SSH
# b) Put the actual logic as some script on the LBs and just execute this script, then parse the output...
#diff -B -y --suppress-common-lines <(ssh $SSHUSER@${1}a vtysh -c 'show ip bgp summary') <(ssh $SSHUSER@${1}b ipvsadm -L -n --sort | cut -c 1-40)
