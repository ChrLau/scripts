#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :
#
#
ICINGA2_API_USER=""
ICINGA2_API_PASSWORD=""
ICINGA2_API_HOST=ip.ip.ip.ip
ICINGA2_API_PORT=

SCRIPT="$(basename "$0")"
JSON_PP="$(which json_pp)"
CURL="$(which curl)"

# Test if curl is present and executeable
if [ ! -x "$CURL" ]; then
  echo "This script requires curl for sending HTTP(S)-Requests to the API"
  exit 3;
fi

# Test if json_pp is present and executeable
if [ ! -x "$JSON_PP" ]; then
  echo "This script requires json_pp (pretty-print JSON) to display the retrieved results in a nice JSON-formatted syntax."
  exit 4;
fi

function HELP {
  echo "$SCRIPT: Query the Icinga2-API for latest check results"
  echo "Usage: $SCRIPT FQDN Servicename"
  echo ""
  echo "Both FQDN & Servicename can specified as RegEx."
  echo "Provide only FQDN to list all Services of this host."
}

# For later version where it's possible to specify what results to retrieve from the API
ONLY_ERRORS="&& !match(\"0\",service.state)"
HOSTFILTER="\"filter\": \"match(\"'$HOST'\",host.name)"
SERVICEFILTER="\"filter\": \"regex(pattern, service.name)\", \"filter_vars\": { \"pattern\": \"'$SERVICENAME'\" }"

# Print help if no arguments are given
if [ "$#" -eq 0 ]; then

  HELP

elif [ "$#" -eq 1 ]; then

  HOST="$1"
  results=$($CURL -s -u $ICINGA2_API_USER:$ICINGA2_API_PASSWORD -H 'Accept: application/json' -H 'X-HTTP-Method-Override: GET' -X POST -k "https://$ICINGA2_API_HOST:$ICINGA2_API_PORT/v1/objects/services/" -d '{"filter": "match(\"'"$HOST"'\",host.name)", "attrs": ["__name", "state", "action_url", "last_check_result"] }')
  # Get services based on service name
  #results=$($CURL -s -u $ICINGA2_API_USER:$ICINGA2_API_PASSWORD -H 'Accept: application/json' -H 'X-HTTP-Method-Override: GET' -X POST -k "https://$ICINGA2_API_HOST:$ICINGA2_API_PORT/v1/objects/services/" -d '{"filter": "match(\"'"$HOST"'\",service.name)", "attrs": ["__name", "state", "action_url", "last_check_result"] }')

  echo "$results" | "$JSON_PP"

elif [ "$#" -eq "2" ]; then

  HOST="$1"
  SERVICENAME="$2"
  results=$($CURL -s -u $ICINGA2_API_USER:$ICINGA2_API_PASSWORD -H 'Accept: application/json' -H 'X-HTTP-Method-Override: GET' -X POST -k "https://$ICINGA2_API_HOST:$ICINGA2_API_PORT/v1/objects/services/" -d '{ "filter": "regex(\"'"$HOST"'\",host.name) && regex(\"'"$SERVICENAME"'\",service.name)", "attrs": ["__name", "state", "action_url", "last_check_result"] }')

  echo "$results" | "$JSON_PP"

fi
