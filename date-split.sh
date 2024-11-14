user@host:~$ cat date-split.sh
#!/bin/bash
# vim: set tabstop=2 smarttab shiftwidth=2 softtabstop=2 expandtab foldmethod=syntax :

# Split a logfile based on timestamps but using the actual line-numbers of last/first occurence
#  Useful if not every logline is prefix with a timestamp

# Source: https://github.com/ChrLau/scripts/blob/master/date-split.sh

LOGFILE="/var/log/unbound/unbound.log"
GZIP="$(command -v gzip)"

for YEAR in {2023..2024}; do
  for MONTH in {1..12}; do

    # Logfile starts November 2023 and ends November 2024 - don't grep for values before/after that time window
    if  [[ "$YEAR" -eq 2023 && "$MONTH" -gt 10 ]] ||  [[ "$YEAR" -eq 2024 && "$MONTH" -lt 12 ]]; then

      # Debug
      echo "$YEAR/$MONTH"

      # Calculate first and last second of each month
      FIRST_SECOND="$(date -d "$(date +"$YEAR"/"$MONTH"/01)" "+%s")"
      LAST_SECOND="$(date -d "$(date +"$YEAR"/"$MONTH"/01) + 1 month - 1 second" "+%s")"

      # Export variables so the grep in the sub-shells have this value
      export FIRST_SECOND
      export LAST_SECOND

      # Split logfiles solely based on timestamps
      #awk -F'[\\[\\]]' -v MIN=${FIRST_SECOND} -v MAX=${LAST_SECOND} '{if($2 >= MIN && $2 <= MAX) print}' unbound.log >> "unbound-$YEAR-$MONTH.log"

      # Using grep, head and tail to get the first and last line from the timeframe
      FIRST_LINE="$(grep -n "$FIRST_SECOND" "$LOGFILE" | head -n 1 | awk -F':' '{print $1}')"
      LAST_LINE="$(grep -n "$LAST_SECOND" "$LOGFILE" | tail -n 1 | awk -F':' '{print $1}')"

      # Store matching lines into separate logfile
      sed -n -e "$FIRST_LINE,$LAST_LINE p" -e "$LAST_LINE q" "$LOGILFE" >> "unbound-$YEAR-$MONTH.log"

      # Creating all those separate logfiles will probably fill up our diskspace
      #  therefore we gzip them immediately afterwards
      "$GZIP" "/var/log/unbound/unbound-$YEAR-$MONTH.log"

    fi

  done;
done
