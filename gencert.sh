#!/usr/bin/env sh
# Import libraries
. ./lib.sh
# Fail on error
set -e
# Check openssl presence
check_executable 'openssl'
# Check env variables
if [ -z "$CA_CERTIFICATE" ]; then
  CA_CERTIFICATE='ca.pem'
fi
log_debug "Selecting $CA_CERTIFICATE as root ca certificate"
if [ -z "$CA_KEY" ]; then
  CA_KEY='ca_private_key.pem'
fi
log_debug "Selecting $CA_KEY as root ca key"
if [ -z "$CERT_FILENAME" ]; then
  CERT_FILENAME='cert'
fi
log_debug "Selecting $CERT_FILENAME as cert filename prefix"
if [ -z "$CERT_SUBJECT" ]; then
  CERT_SUBJECT='/CN=Cert/'
fi
log_debug "Selecting $CERT_SUBJECT as subject"
# Generate private key
PRIVATE_KEY_FILE="${CERT_FILENAME}_private_key.pem"
PUBLIC_KEY_FILE="${CERT_FILENAME}_public_key.pem"
. ./genpkey.sh
# Generate CSR
GENCOMMAND="openssl req"
GENCOMMAND="$GENCOMMAND -batch"
GENCOMMAND="$GENCOMMAND -new"
GENCOMMAND="$GENCOMMAND -key $PRIVATE_KEY_FILE -keyform PEM"
GENCOMMAND="$GENCOMMAND -out ${CERT_FILENAME}.csr -outform PEM"
GENCOMMAND="$GENCOMMAND -subj '$CERT_SUBJECT'"

launch_command "$GENCOMMAND"
# Sign CSR
GENCOMMAND="openssl x509"
GENCOMMAND="$GENCOMMAND -req -in ${CERT_FILENAME}.csr -inform PEM"
GENCOMMAND="$GENCOMMAND -out ${CERT_FILENAME}.pem -outform PEM"

GENCOMMAND="$GENCOMMAND -CA $CA_CERTIFICATE -CAkey $CA_KEY"

SERIAL="0x$(tr -dc a-fA-F0-9 </dev/urandom | tr '[:lower:]' '[:upper:]' | head -c 8)"
GENCOMMAND="$GENCOMMAND -set_serial $SERIAL"

GENCOMMAND="$GENCOMMAND -SHA512"
GENCOMMAND="$GENCOMMAND -days 3650"

EXTFILE=$(mktemp)
GENCOMMAND="$GENCOMMAND -extfile $EXTFILE -extensions custom"
cat >>"$EXTFILE" <<EOF
[custom]
subjectKeyIdentifier = hash
EOF

if [ "$CERT_IS_CA" = "y" ]; then
  printf 'basicConstraints = CA:TRUE\n' >>"$EXTFILE"
else
  printf 'basicConstraints = CA:FALSE\n' >>"$EXTFILE"
fi

if [ -z "$CERT_KEY_USAGE" ]; then
  CERT_KEY_USAGE="digitalSignature nonRepudiation"
fi
printf 'keyUsage = ' >>"$EXTFILE"
FIRST=y
for key_usage in $CERT_KEY_USAGE; do
  if [ "$FIRST" = "y" ]; then FIRST=n; else printf ', ' >>"$EXTFILE"; fi
  printf '%s' "$key_usage" >>"$EXTFILE"
done
printf '\n' >>"$EXTFILE"

if [ -n "$CERT_EXT_KEY_USAGE" ]; then
  printf 'extendedKeyUsage = ' >>"$EXTFILE"
  FIRST=y
  for key_usage in $CERT_EXT_KEY_USAGE; do
    if [ "$FIRST" = "y" ]; then FIRST=n; else printf ', ' >>"$EXTFILE"; fi
    printf '%s' "$key_usage" >>"$EXTFILE"
  done
  printf '\n' >>"$EXTFILE"
fi

if [ -n "$CERT_SANS" ]; then
  printf 'subjectAltName = @custom_sans\n' >>"$EXTFILE"

  printf '\n[custom_sans]\n' >>"$EXTFILE"
  EMAIL_COUNT=0
  URI_COUNT=0
  DNS_COUNT=0
  RID_COUNT=0
  IP_COUNT=0
  DIRNAME_COUNT=0
  OTHERNAME_COUNT=0
  for san in $CERT_SANS; do
    san_category=$(echo "$san" | cut -d ':' -f 1)
    san_address=$(echo "$san" | cut -d ':' -f 2-)

    case $san_category in
    email)
      printf '%s.%d = %s\n' "$san_category" "$EMAIL_COUNT" "$san_address" >>"$EXTFILE"
      EMAIL_COUNT=$((EMAIL_COUNT + 1))
      ;;
    URI)
      printf '%s.%d = %s\n' "$san_category" "$URI_COUNT" "$san_address" >>"$EXTFILE"
      URI_COUNT=$((URI_COUNT + 1))
      ;;
    DNS)
      printf '%s.%d = %s\n' "$san_category" "$DNS_COUNT" "$san_address" >>"$EXTFILE"
      DNS_COUNT=$((DNS_COUNT + 1))
      ;;
    RID)
      printf '%s.%d = %s\n' "$san_category" "$RID_COUNT" "$san_address" >>"$EXTFILE"
      RID_COUNT=$((RID_COUNT + 1))
      ;;
    IP)
      printf '%s.%d = %s\n' "$san_category" "$IP_COUNT" "$san_address" >>"$EXTFILE"
      IP_COUNT=$((IP_COUNT + 1))
      ;;
    dirName)
      printf '%s.%d = %s\n' "$san_category" "$DIRNAME_COUNT" "$san_address" >>"$EXTFILE"
      DIRNAME_COUNT=$((DIRNAME_COUNT + 1))
      ;;
    otherName)
      printf '%s.%d = %s\n' "$san_category" "$OTHERNAME_COUNT" "$san_address" >>"$EXTFILE"
      OTHERNAME_COUNT=$((OTHERNAME_COUNT + 1))
      ;;
    esac
  done
  printf '\n' >>"$EXTFILE"
fi

launch_command "$GENCOMMAND"
rm -f "$EXTFILE"
rm -f "${CERT_FILENAME}.csr"
