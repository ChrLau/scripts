#!/bin/bash

# Create pkcs12 file from our PEM and Keyfile
#
# Current version can be found here:
# https://github.com/ChrLau/scripts/ca/blob/master/mk_pkcs12.sh

# shellcheck disable=SC2181
VERSION="1.0"
SCRIPT=$(basename "$0")
OPENSSL="$(command -v openssl)"

PRIVATE_KEY="$1"
PUBLIC_CERT="$2"
PKCS12_FILE="$3"

# Test if openssl is present and executeable
if [ ! -x "$OPENSSL" ]; then
  echo "This script requires openssl to convert the cert and key to pkcs12. Exiting."
  exit 2;
fi

function HELP {
  echo "$SCRIPT $VERSION: Converts PEM cert and key to PKCS12"
  echo "Usage: $SCRIPT PRIVATE.key PUBLIC.cert FILE.p12"
  echo ""
  echo "1st parameter: Path to the private Key file"
  echo "2nd parameter: Path to public cert (PEM)"
  echo "3rd parameter: Where to write the resulting pkcs12 cert"
  echo ""
  echo "$SCRIPT will ask for a passphrase of a PKCS12 file."
  exit 0
}

ssl_verify_cert() { openssl x509 -in "$PUBLIC_CERT" -text; }
ssl_verify_key() { openssl rsa -in "$PRIVATE_KEY" -check -noout; }
ssl_verify_cert2key() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: ssl_verify_cert2key certificate privatekey";
  else
    diff  <("$OPENSSL" x509 -in "$2" -pubkey -noout) <("$OPENSSL" rsa -in "$1" -pubout 2>/dev/null);
    if [ "$?" -eq 0 ];then
      echo "Certificate and PrivateKey match";
    else
      echo "Certificate and PivateKey DON'T match";
      exit 2
    fi
  fi;
}

# Print help if no arguments are given
if [ "$#" -ne 3 ]; then
  HELP
fi

# Test that PRIVATE_KEY and PUBLIC_CERT are readable
if [ ! -r "$PRIVATE_KEY" ]; then
  echo "$PUBLIC_CERT is not readable. Exiting."
  exit 1
fi

if [ ! -r "$PUBLIC_CERT" ]; then
  echo "$PUBLIC_CERT is not readable. Exiting."
  exit 1
fi

ssl_verify_cert2key "$PRIVATE_KEY" "$PUBLIC_CERT"

$OPENSSL pkcs12 -export -inkey "$PRIVATE_KEY" -in "$PUBLIC_CERT" -out "$PKCS12_FILE"

if [ "$?" -eq 0 ]; then
  echo "$PKCS12_FILE - Created successfully."
else
  echo "Error Creating $PKCS12_FILE. Please check."
fi

