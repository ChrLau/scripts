#!/bin/bash

# Recent version can be found here: https://github.com/ChrLau/scripts/blob/master/ca/hostcert.sh
# Based on this: https://wejn.org/2023/09/running-ones-own-root-certificate-authority-in-2023/

# shellcheck disable=SC2034

# Read the CA password, used by `sign.sh` later
CAPASS=$(cat ca.pass)

export CAPASS

if [ -f "$1.cnf" ]; then
        echo "Host: $1 already exists."
        exit 1
fi

if [ -z "$1" ]; then
        echo "Error: No hostname given. Please ensure the common name (CN) is given as first argument."
	echo "List additional DNS, IPv4 or IPv6 Altnames after the first argument, separated by spaces"
        exit 1
fi

umask 066

# Generate the certificate's password, and dump it.
PASS=$(xkcdpass -n 64)
export PASS

if [ -z "$PASS" ]; then
        echo "Error: password empty; no xkcdpass?"
        exit 1
fi

echo "$PASS" > "$1.pass"

# If first argument includes dots use that FQDN as CN for the cert
#  else add the domain
if echo "$1" | grep -F -q "."; then
	CN="$1"
else
	CN="$1.lan"
fi

# Check if Altname is an IPv4 or IPv6 (yeah.. very basic check..)
#  so we can set the proper x509v3 extension
for ALTNAME in $*; do
  if [[ $ALTNAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || $ALTNAME =~ \.*:\.* ]]; then
    IP_ALTNAMES+=("$ALTNAME")
  else
    DNS_ALTNAMES+=("$ALTNAME")
  fi
done

echo "CN: $CN"
echo "DNS ANs: ${DNS_ALTNAMES[@]}"
echo "IP ANs: ${IP_ALTNAMES[@]}"
echo "Enter to confirm."
# shellcheck disable=SC2162,SC2034
read A

# Generate the RSA key, unlock it into the "unsecure" file
openssl genrsa -aes256 -passout env:PASS  -out "$1.key" "${SSL_KEY_SIZE-4096}"
openssl rsa -in "$1.key" -passin env:PASS -out "$1.unsecure.key"

# Construct the CSR data
cat > "$1.cnf" <<EOF
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no

[ v3_req ]
# We are NOT a CA, this is for server auth, and these are the altnames
basicConstraints = critical,CA:FALSE
# We are, however, a certificate for server authentication (important!)
extendedKeyUsage=serverAuth
subjectAltName = @alt_names

[alt_names]
EOF

N=1
I=1
for DNSAN in ${DNS_ALTNAMES[@]}; do
        echo "DNS.$N = $DNSAN" >> "$1.cnf"
        N=$((N + 1))
done

for IPAN in ${IP_ALTNAMES[@]}; do
	echo "IP.$I = $IPAN" >> "$1.cnf"
	I=$((I + 1))
done
cat >> "$1.cnf" <<EOF

[ req_distinguished_name ]
C = DE
L = Karlsruhe
O = LAN CA host cert
CN = $CN
EOF

# Create the CSR
openssl req -new -key "$1.key" -sha512 -passin env:PASS -config "$1.cnf" \
        -out "$1.csr"

# Sign the CSR by the CA, resulting in `$1.crt`; needs env;CAPASS
./sign.sh "$1.csr"

# Optional: put both cert and key into a single `$1.pem` file
#ruby -pe 'next unless /BEGIN/../END/' "$1.crt" "$1.unsecure.key" > "$1.pem"

