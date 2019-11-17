#!/usr/bin/env sh
# Import libraries
. ./lib.sh
# Fail on error
set -e
# Check openssl presence
check_executable 'openssl'
# Check env variables
case $PRIVATE_KEY_ALGORITHM in
ec | EC | rsa | RSA)
  PRIVATE_KEY_ALGORITHM=$(echo "$PRIVATE_KEY_ALGORITHM" | tr '[:lower:]' '[:upper:]')
  log_info "Selecting $PRIVATE_KEY_ALGORITHM as private key algorithm"
  ;;
*)
  if [ -z "$PRIVATE_KEY_ALGORITHM" ]; then
    log_info "Selecting RSA as private key algorithm"
    PRIVATE_KEY_ALGORITHM='RSA'
  else
    err "Unknown PRIVATE_KEY_ALGORITHM ( $PRIVATE_KEY_ALGORITHM )"
  fi
  ;;
esac
if [ -z "$PRIVATE_KEY_FILE" ]; then
  PRIVATE_KEY_FILE="private_key.pem"
fi
log_debug "Selecting private key file '$PRIVATE_KEY_FILE'"
if [ -z "$PUBLIC_KEY_FILE" ]; then
  PUBLIC_KEY_FILE="public_key.pem"
fi
log_debug "Selecting public key file '$PUBLIC_KEY_FILE'"
# Generate private key
if ! [ -f "$PRIVATE_KEY_FILE" ]; then
  log_info "Starting generation of private key"

  GENCOMMAND="openssl genpkey"
  GENCOMMAND="$GENCOMMAND -out $PRIVATE_KEY_FILE -outform PEM"

  if [ "$PRIVATE_KEY_ALGORITHM" = "EC" ]; then
    GENCOMMAND="$GENCOMMAND -algorithm ED25519"
  fi

  if [ "$PRIVATE_KEY_ALGORITHM" = "RSA" ]; then
    GENCOMMAND="$GENCOMMAND -algorithm RSA -pkeyopt rsa_keygen_bits:4096"
  fi

  launch_command "$GENCOMMAND"

  unset GENCOMMAND

else
  log_info "Not generating private key: already exists"
fi
# Generate public key
if ! [ -f "$PUBLIC_KEY_FILE" ]; then
  log_info "Starting generation of public key"

  GENCOMMAND="openssl pkey"
  GENCOMMAND="$GENCOMMAND -in $PRIVATE_KEY_FILE -inform PEM"
  GENCOMMAND="$GENCOMMAND -out $PUBLIC_KEY_FILE -outform PEM -pubout"

  launch_command "$GENCOMMAND"

  unset GENCOMMAND

else
  log_info "Not generating public key: already exists"
fi
