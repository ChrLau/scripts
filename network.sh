#!/bin/bash

# This scripts determines the first IP which doesn't reply to ICMP-Pings and has an associated DNS-Record
# This is used to generated the static network config /etc/network/interfaces
VERSION="1.0"
SCRIPT="$(basename "$0")"
NMAP="$(which nmap)"

# Test if ssh is present and executeable
if [ ! -x "$NMAP" ]; then
  echo "This script requires nmap. Exiting."
  exit 2;
fi

FIRST_DOWN_HOST=$(nmap -v -sn -R 192.168.178.21-49 -oG - | grep -m1 -oP "^Host:[[:space:]]192\.168\.178\.[0-9]{2}[[:space:]]\([a-zA-Z0-9\-]+\.lan\)[[:space:]]Status: Down")
#echo "FIRST_DOWN_HOST: $FIRST_DOWN_HOST"

IP=$(awk '{print $2}' <<<$FIRST_DOWN_HOST)
#echo "IP: $IP"

FQDN=$(awk -F'[()]' '{print $2}' <<<$FIRST_DOWN_HOST)
#echo "FQDN: $FQDN"

GATEWAY=$(ip -o -4 route show to default | awk '{print $3}')
#echo "GATEWAY: $GATEWAY"

INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
#echo "INTERFACE: $INTERFACE"

# Save old network config
if [ -f /etc/network/interfaces ]; then
  cp /etc/network/interfaces /etc/network/interfaces.scriptcopy
fi

# Write new config
cat <<NETWORKEOF > /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug $INTERFACE
iface $INTERFACE inet static
  address $IP
  netmask 255.255.255.0
  gateway $GATEWAY
  dns-nameservers 192.168.178.9

#iface $INTERFACE inet6 static
#  address fd00::b4fd:51ff:fe7b:XXXX
#  netmask 64
#  gateway fe80::1
NETWORKEOF

# Set /etc/hosts
# Only add if not already present
grep -q "$IP[[:blank:]]$FQDN[[:blank:]]$HOST" /etc/hosts

if [ "$?" -ne 0 ]; then
  echo "$IP\t$FQDN\t$HOST" >> /etc/hosts
else
  echo "/etc/hosts entry already present"
fi

# Set Hostname - only if variable is not empty
if [ ! -z $FQDN ]; then
  echo "$FQDN" > /etc/hostname
else
  echo "FQDN is empty"
fi
