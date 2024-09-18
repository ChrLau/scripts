#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :

# Bash strict mode
#  read: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Generic
VERSION="1.0"
#SOURCE="https://github.com/ChrLau/scripts/blob/master/check-isso-comments.sh"
# Values
TELEGRAM_CHAT_ID=""
TELEGRAM_BOT_TOKEN=""
ISSO_COMMENTS_DB=""
# Needed binaries
SQLITE3="$(command -v sqlite3)"
CURL="$(command -v curl)"
# Colored output
RED="\e[31m"
#GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Check that variables are defined
if [ -z "$TELEGRAM_CHAT_ID" ] || [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$ISSO_COMMENTS_DB" ]; then
  echo "${RED}This script requires the variables TELEGRAM_CHAT_ID, TELEGRAM_BOT_TOKEN and ISSO_COMMENTS_DB to be set. Define them at the top of this script.${ENDCOLOR}"
  exit 1;
fi

# Test if sqlite3 is present and executeable
if [ ! -x "${SQLITE3}" ]; then
  echo "${RED}This script requires sqlite3 to connect to the database. Exiting.${ENDCOLOR}"
  exit 2;
fi

# Test if ssh is present and executeable
if [ ! -x "${CURL}" ]; then
  echo "${RED}This script requires curl to send the message via Telegram API. Exiting.${ENDCOLOR}"
  exit 2;
fi

# Test if the Isso comments DB file is readable
if [ ! -r "${ISSO_COMMENTS_DB}" ]; then
  echo "${RED}The ISSO sqlite3 database ${ISSO_COMMENTS_DB} is not readable. Exiting.${ENDCOLOR}"
  exit 3;
fi

COMMENT_COUNT=$(echo "select count(*) from comments where mode == 2" | sqlite3 "${ISSO_COMMENTS_DB}")

TEMPLATE=$(cat <<TEMPLATE
<strong>ISSO Comment checker</strong>

<pre>${COMMENT_COUNT} comments need approval</pre>
TEMPLATE
)

if [ "${COMMENT_COUNT}" -gt 0 ]; then

  /usr/bin/curl --silent --output /dev/null \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${TEMPLATE}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

fi
