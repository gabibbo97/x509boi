#!/usr/bin/env sh
# Import libraries
. ./lib.sh
# Fail on error
set -e
# Check openssl presence
check_executable 'openssl'
# Check env variables
if [ -z "$CA_SUBJECT" ]; then
  CA_SUBJECT='/CN=CA/'
fi
log_debug "Selecting $CA_SUBJECT as subject"
# Generate private key
PRIVATE_KEY_FILE='ca_private_key.pem' \
  PUBLIC_KEY_FILE='ca_public_key.pem' \
  sh genpkey.sh
# Generate self signed CA certificate
GENCOMMAND="openssl req"
GENCOMMAND="$GENCOMMAND -batch"
GENCOMMAND="$GENCOMMAND -new -x509"
GENCOMMAND="$GENCOMMAND -key ca_private_key.pem -keyform PEM"
GENCOMMAND="$GENCOMMAND -out ca.pem -outform PEM"
GENCOMMAND="$GENCOMMAND -subj '$CA_SUBJECT'"
GENCOMMAND="$GENCOMMAND -days 30000"
GENCOMMAND="$GENCOMMAND -SHA512"

GENCOMMAND="$GENCOMMAND -addext basicConstraints=CA:TRUE"
GENCOMMAND="$GENCOMMAND -addext subjectKeyIdentifier=hash"
GENCOMMAND="$GENCOMMAND -addext keyUsage=keyCertSign,cRLSign"

launch_command "$GENCOMMAND"
