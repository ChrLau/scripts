#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
# Bash script that checks if a TCP port on a host is reachable (open/closed)
# using bash's built-in /dev/tcp pseudo-device - no nc/nmap/telnet required.
#
# Usage:
#   check_port.sh <host> <port> [timeout_in_seconds]
#
# If no timeout is given, 0.5 seconds will be used.
#
# Exit codes:
#   0 = port is open
#   1 = port is closed (or not reachable within the timeout)
#   2 = wrong usage / invalid arguments / missing tool

# Bash strict mode
# read: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

VERSION="1.0"
SCRIPT="$(basename "$0")"

# Colored output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

check_port() {

  # Fewer than two or more than three arguments? Print help
  if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "$SCRIPT $VERSION: Check if a TCP port is open on a host"
    echo ""
    echo "Usage: $SCRIPT host port [timeout]"
    echo " If [timeout] is omitted, 0.5 seconds will be used."
    echo " Example:"
    echo " $SCRIPT example.com 443"
    echo " $SCRIPT 192.168.1.10 22 2"
    return 2
  fi

  host="$1"
  port="$2"
  wait_time="${3:-0.5}"

  # Check tooling
  for cmd in timeout bash; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo -e "${RED}Error: required tool is not installed: $cmd${ENDCOLOR}"
      return 2
    fi
  done

  # Validate port (numeric, 1-65535)
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo -e "${RED}Error: invalid port: $port (expected 1-65535).${ENDCOLOR}"
    return 2
  fi

  # Validate timeout (positive number, integer or decimal)
  if ! [[ "$wait_time" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo -e "${RED}Error: invalid timeout: $wait_time (expected a number in seconds).${ENDCOLOR}"
    return 2
  fi

  # The /dev/tcp redirect is opened by the shell itself. A plain
  #   "timeout 0.5 echo ... < /dev/tcp/..." would therefore NOT limit the
  #   connect(). Running it inside "bash -c" puts the connect under timeout.
  # Host and port are passed as positional parameters (no injection via quoting).
  # _ functions as placeholder, so $host stays at $1 and doesn't become $0 (you never stop learning).
  if timeout "$wait_time" bash -c 'echo -n 2>/dev/null < "/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo -e "${GREEN}open${ENDCOLOR}"
    return 0
  else
    echo -e "${YELLOW}closed${ENDCOLOR}"
    return 1
  fi
}

# If this script is executed directly (not sourced), call the
# function with the given arguments.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_port "$@"
fi
