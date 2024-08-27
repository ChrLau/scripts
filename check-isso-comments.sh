#!/bin/sh
#set -eu

# Generic
VERSION="1.0"
SCRIPT="$(basename "$0")"
SOURCE="https://github.com/ChrLau/scripts/check-isso-comments.sh"
# Values
TELEGRAM_CHAT_ID="243844689"
TELEGRAM_BOT_TOKEN="6430503469:AAFYETwfK3YEB2ZD0KVUjM47llv4dd-CImY"
ISSO_COMMENTS_DB="/opt/isso/db/comments.db"
# Needed binaries
SQLITE3="$(command -v sqlite3)"
CURL="$(command -v curl)"
# Colored output
RED="\e[31m"
#GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Test if sqlite3 is present and executeable
if [ ! -x "$SQLITE3" ]; then
  echo "${RED}This script requires sqlite3 to connect to the database. Exiting.${ENDCOLOR}"
  exit 2;
fi

# Test if ssh is present and executeable
if [ ! -x "$CURL" ]; then
  echo "${RED}This script requires curl to send the message via Telegram API. Exiting.${ENDCOLOR}"
  exit 2;
fi

if [ ! -r "$ISSO_COMMENTS_DN" ]; then
  echo "${RED}The ISSO sqlite3 database $ISSO_COMMENTS_DB is not readable. Exiting.${ENDCOLOR}"
  exit 3;
fi

HELP() {
  echo "$SCRIPT $VERSION: Query the Isso sqlite3 comments database for not-approved comments and notify via Telegram API"
  echo "  newest version be found here: $SOURCE"
  echo " -h will print this help."
  exit 0;
}

# Parse arguments
while getopts ":h" OPTION; do
  case "$OPTION" in
    h)
      HELP
      ;;
    *)
      HELP
      ;;
  esac
done

COMMENT_COUNT=$(echo "select count(*) from comments where mode == 2" | sqlite3 "$ISSO_COMMENTS_DB")

template=$(cat <<TEMPLATE
<strong>ISSO Comment checker</strong>

<pre>${COMMENT_COUNT} comments need approval</pre>
TEMPLATE
)

if [ "$COMMENT_COUNT" -gt 0 ]; then

/usr/bin/curl --silent --output /dev/null \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${template}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

fi

