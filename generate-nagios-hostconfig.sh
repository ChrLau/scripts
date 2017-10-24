#!/bin/bash
# Small script to generate Nagios Host-definitions
# Non-resolving FQDN/Hostnames will produce empty host definitions

# No arguments? Print help.
if [ "$#" -eq "0" ]; then
  echo -e "Usage: $0 Inputfile Outputfile Templatename\\nExample: $0 prod-hosts.list prod-hosts.cfg prod-host\\nInputfile: 1 host per line (works best if FQDNs are given)\\nOutputfile: Name of generated Host-Definitions file\\n"
  exit 1
fi

INPUTFILE=$1

# 2nd arugment is zero chars long? Abort
if [ -z "$2" ]; then
  echo "Please provide outputfile-name."
  exit 1
else
  OUTPUTFILE=$2
fi

while read -r line;
do
        RESOLVEDDNS=$(getent hosts "$line");
        HOSTIP=$(awk '{print $1}' <<< "$RESOLVEDDNS");
        FQDN=$(awk '{print $2}' <<< "$RESOLVEDDNS");

        # $HOSTENV determines if the host is prod or non-prod
        # And sets the host-template accordingly
        if echo "$RESOLVEDDNS" | grep -q -e "qa" -e "qs" -e "test" -e "dev"; then
                TEMPLATENAME="non-prod-host"
        else
                TEMPLATENAME="prod-host"
        fi


        printf "define host {\\n\
\\thost_name\\t%s\\n\
\\taddress\\t\\t%s\\n\
\\talias\\t\\t%s\\n\
\\tuse\\t\\t%s\\n\
}\\n\\n" "$FQDN" "$HOSTIP" "$FQDN" "$TEMPLATENAME" >> "$OUTPUTFILE"

done < "$INPUTFILE"
