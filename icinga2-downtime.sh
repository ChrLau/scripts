#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
# set a downtime for the specified host and its services
# default duration: 60 minutes (unless second parameter is given)
#
# Source can be found here:
# https://github.com/ChrLau/scripts/blob/master/icinga2-downtime.sh

if [ -z "$1" ]
then
  echo "Usage: $0 <target_fqdn> [<duration in minutes> [<comment>]]"
  exit 1
else
  TARGET="$1"
fi

if [ -z "$2" ]
then
  DURATION=60
else
  DURATION="$2"
fi

if [ -z "$3" ]
then
  COMMENT="Downtime via script"
else
  COMMENT="$3"
fi

# Icinga details (host should probably be a HA name/IP)
ICINGA_HOST=''
ICINGA_USER=''
ICINGA_PASS=''

DOWNTIME_START=$(date +%s)
DOWNTIME_END=$(date +%s -d +"${DURATION}"minutes)

API_RESPONSE=$(curl -k -s \
        -u "$ICINGA_USER":"$ICINGA_PASS" \
        -H 'Accept: application/json' \
        -X POST "https://$ICINGA_HOST:5665/v1/actions/schedule-downtime?host=${TARGET}&type=Service&filter=host.name==%22${TARGET}%22" \
    -d "{ \"start_time\": \"${DOWNTIME_START}\", \"end_time\": \"${DOWNTIME_END}\", \"duration\": ${DURATION}, \"author\": \"mon_ah\", \"comment\": \"${COMMENT}\" }" )

if [[ "$API_RESPONSE" =~ .*error.* ]]
then
  echo "API returned error: $API_RESPONSE"
  exit 1
else
  echo "API completed successfully:"
  echo "$API_RESPONSE"
fi

exit 0
