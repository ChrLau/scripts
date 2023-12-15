#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :

# Description:
# Check Plugin for Icinga to monitor a local HTML logfile.
# As sometimes orders contain an old element name and processing this order fails.
# This plugin saves us the trouble to check the logfile manually on a daily base.

# Location:
# The current version of this script can be found here:
# https://github.com/ChrLau/scripts/check_html_logfile.sh

# shellcheck disable=SC2034
VERSION="1.2"
STATUS_LOGFILE="/path/to/log/file.html"
# For Testing:
#STATUS_LOGFILE="/home/$USER/index.html"

# Not really needed, due to how the order logfile works
#  as we WANT to be notified for ANY sum of failed orders
#WARN_THRESHOLD="$1"
#CRIT_THRESHOLD="$2"

# Icinga Plugin API documentation:
# https://icinga.com/docs/icinga-2/latest/doc/05-service-monitoring/#service-monitoring-plugin-api
# https://icinga.com/docs/icinga-2/latest/doc/05-service-monitoring/#performance-data-metrics

# Performance data metrics must be appended to the plugin output with a preceding | character. The schema is as follows:
#<output> | 'label'=value[UOM];[warn];[crit];[min];[max]
#The label should be encapsulated with single quotes. Avoid spaces or special characters such as % in there, this could lead to problems with metric receivers such as Graphite.
#Labels must not include ' and = characters. Keep the label length as short and unique as possible.
#Example:
#'load1'=4.7

# Plugin Exit codes for Icinga:
OK=0
# shellcheck disable=SC2034
WARN=1
CRIT=2
# shellcheck disable=SC2034
UNKOWN=3

# Check if logfile is readable
if [ ! -r "$STATUS_LOGFILE" ]; then

    # Check if the mountpoint is present (as the logfile is on a remote mounted filesystem)
    if ! findmnt --target /path/to/log > /dev/null 2>&1 ; then

        # Check for the line in /etc/fstab - As this seems to go missing regularly (yai for buggy CI/CD.. NOT)
        if ! grep -q "host.domain.tld:/log /path/to/log nfs defaults,noatime 0 0" /etc/fstab ; then

          echo "CRITICAL: Line for that mount is missing in /etc/fstab"
          # Add to /etc/fstab: host.domain.tld:/log /path/to/log nfs defaults,noatime 0 0
          exit $CRIT

        fi

      echo "CRITICAL: /path/to/log not mounted. This is needed to access the logfile."
      exit $CRIT

    fi

  echo "CRITICAL: Logfile $STATUS_LOGFILE is not readable. Exiting."
  exit $CRIT

fi

# Now that we have checked that the logfile is present and readable.. ;-)
# Store the Order-ID from all failed orders listed on the status page (contains 1 month, so also old non-relevant/fixed errors)
# We get the previous 4 lines also, so we can actually grep for the searchorderid
# paste -s puts into a line without newlines and separates the values by a comma. So we can easily transform it into an array
#
# Disable SC1001 (info) as we DO want to look for a literal =
# shellcheck disable=SC1001
ERROR_ID="$(grep -B4 Misserfolg "$STATUS_LOGFILE"  | grep \&searchorderid\= | sed 's#.*searchorderid\=##' | sed 's#\&level\=.*##' |paste -s -d ',')"

# Check if the length of the variable-content is zero
# If yes, we haven't found any errors. Yai!
if [ -z "$ERROR_ID" ]; then

  echo "OK: No failed orders found. | 'FailedOrders'=0"
  exit $OK

# Errors found? Proceed.
else

  # Array which stores all unsuccessful searchorderids
  declare -a ERROR_ID_ARRAY=()

  # Array which stores all successful searchorderids
  declare -a SOLVED_ERRORS_ARRAY=()

  # Set field separator to comma
  IFS=',' read -r -a ERROR_ID_ARRAY <<< "$ERROR_ID"

  # Debug: Print whole array
  #declare -p ERROR_ID_ARRAY

  # For each ERROR_ID in the array, check if there is a corresponding success entry with a success notice
  # As the logfile shows ALL jobs from the current day to 1 month back this includes also jobs which were already corrected
  for ID in "${ERROR_ID_ARRAY[@]}"; do

    # grep for searchorderids with errors, who also have a success entry
    grep -A4 "$ID" "$STATUS_LOGFILE" | grep -q "<td style=\"color: green\;\">Erfolg</td>";

    # If exit code of grep is 0, an entry was found, add this searchorderid to the array
    if [ "$?" -eq 0 ]; then

      SOLVED_ERRORS_ARRAY+=("$ID")

    fi

    # Debug: Print array during generation
    #declare -p SOLVED_ERRORS_ARRAY

  done


  # Make ERROR_ID_ARRAY and SOLVED_ERRORS_ARRAY only contain unique elements
  # As we want only the sum of failed jobs, not the sum of each attempt

  # Debug
  # echo "Makeing Arrays unique"
  #declare -p ERROR_ID_ARRAY
  #declare -p SOLVED_ERRORS_ARRAY

  # Print the whole array, concert to newline, run sort -u and concert newlines back to spaces
  ERROR_ID_ARRAY=("$(echo "${ERROR_ID_ARRAY[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')")
  SOLVED_ERRORS_ARRAY=("$(echo "${SOLVED_ERRORS_ARRAY[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')")

  # Debug
  #echo "Arrays are unique"
  #declare -p ERROR_ID_ARRAY
  #declare -p SOLVED_ERRORS_ARRAY

  # Check if we have any fixed searchorderids at all
  if [ "${#SOLVED_ERRORS_ARRAY[@]}" -ne 0 ]; then

    # Now we remove the searchorderids which were successful from the ERROR_ID_ARRAY
    for SUCCESS in "${SOLVED_ERRORS_ARRAY[@]}"; do

      for ERROR in "${!ERROR_ID_ARRAY[@]}"; do

        # If the value of an entry in the ERROR_ID_ARRAY matches the one of an entry in the SOLVED_ERRORS_ARRAY
        #  remove the order id from the ERROR_ID_ARRAY as it is already solved
        #
        # NOTE: This will only remove the element from the array, but it WON'T renumber the elements
        #  Means: If element 2 out of 3 is deleted, you will end up it elements at array position 0 and 2
        #  To fix this (just in case) we re-order the array later
        if [[ "${ERROR_ID_ARRAY[$ERROR]}" = "$SUCCESS" ]]; then

          unset "ERROR_ID_ARRAY[$ERROR]"

        fi

      done

    done

    # Debug: Before array re-ordering
    #declare -p ERROR_ID_ARRAY

    # Here we re-order the array to have consectuive element numbers
    ERROR_ID_ARRAY=("${ERROR_ID_ARRAY[@]}")

    # Debug: After array re-ordering
    #declare -p ERROR_ID_ARRAY

    # Now we have to check if there are unsolved errors remaining
    if [ "${#ERROR_ID_ARRAY[@]}" -ne 0 ]; then

      # Critical
      echo "CRITICAL: We have ${#ERROR_ID_ARRAY[@]} failed orders | 'FailedOrders'=${#ERROR_ID_ARRAY[@]}"
      exit $CRIT

    # No errors
    else

      echo "OK: No failed orders found. | 'FailedOrders'=0"
      exit $OK

    fi

  else

    echo "CRITICAL: We have ${#ERROR_ID_ARRAY[@]} failed orders | 'FailedOrders'=${#ERROR_ID_ARRAY[@]}"
    exit $CRIT

  fi

fi
