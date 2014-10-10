#!/bin/bash

# Use the correct SSH-User to connect to a system
# based on availbility of Port 80/tcp

user=$USER

arg=$1

if [ "$arg" == "" ]
then
  read -e -p "Host to connect to: " host
else
  host=${arg##*@}
  shift
fi

newhost=$(nc -w2 $host 80 2>/dev/null)
if [ -n "$newhost" ]
then
  host=$newhost
fi

if [ "${arg##*@}" != "${arg%%@*}" ]
then
  user=${arg%%@*}
else
  internal=$(nc -w2 $newhost 80 2>/dev/null)
  if [ -z "$internal" ]
  then
    user="root"
  fi
fi

echo >&2
echo -e "\033[1;32mConnecting to \033[1;31m$host\033[1;32m as user \033[1;31m$user\033[m" >&2
echo >&2

echo -en "\033]0;$host\007" >&2
/usr/bin/ssh -o PasswordAuthentication=no -o PreferredAuthentications=publickey -l $user $host $@
echo -en "\033]0;None\007" >&2
