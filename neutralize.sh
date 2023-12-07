#!/bin/bash

# neutralize.sh
# AUTHOR: Christian Lauf
# Source: https://github.com/ChrLau/scripts/blob/master/network.sh
# This script is useful is you want to "neutralize" some script. Ensuring that it can't be executed/changed.
# Warning: As this script modifies timestamps and filerights it shouldn't be used as a forensic tool.

VERSION="1.0"
SCRIPT="$(basename "0")"
CHMOD="$(which chmod)"
CHOWN="$(which chown)"
CHATTR="$(which chattr)"
LSATTR="$(which lsattr)"
STAT="$(which stat)"

if [ "$#" != "1" ]; then
        echo "Usage: $0 /path/to/file"
        exit 1
fi

if [ -f "$1" ]; then

  $CHOWN 0000 $1
  $CHOWN root:root $1

  echo -e "\e[0;32mMade file 0000, root:root and immutable bit set:\e[0m"
  $STAT $1
  $CHATTR +i $1

  echo -e "\e[0;32mSet immutable bit on file:\e[0m"
  $LSATTR $1

else

  echo -e "\e[0;31m $1 is not a regular file.\e[0m"
  exit 2

fi
