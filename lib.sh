#!/usr/bin/env sh
# Fail on error
set -e

# Log
log() {
  printf '{"LEVEL":"%s","MESSAGE":"%s"}\n' "$1" "$2"
}
log_debug() {
  if [ -n "$LOG_DEBUG" ]; then
    log "DEBUG" "$1"
  fi
}
log_info() {
  log "INFO" "$1"
}
log_warning() {
  log "WARNING" "$1"
}
err() {
  log "ERROR" "$1" >/dev/stderr
  exit 1
}

# Checks
check_executable() {
  if which "$1" >/dev/null 2>&1; then
    log_debug "Found executable '$1'"
  else
    err "Could not find executable '$1'"
  fi
}

# Command
launch_command() {
  STDOUT_FILE=$(mktemp)
  STDERR_FILE=$(mktemp)

  set +e
  eval "$1" >"$STDOUT_FILE" 2>"$STDERR_FILE"
  RC="$?"
  set -e

  printf '{"command":"%s",' "$1"

  FIRST_STDOUT_LINE=y
  printf '"stdout":['
  while read -r line; do
    if [ "$FIRST_STDOUT_LINE" = "y" ]; then
      FIRST_STDOUT_LINE=n
    else
      printf ','
    fi
    printf "\"%s\"" "$line"
  done <"$STDOUT_FILE"
  printf '],'
  unset FIRST_STDOUT_LINE

  FIRST_STDERR_LINE=y
  printf '"stderr":['
  while read -r line; do
    if [ "$FIRST_STDERR_LINE" = "y" ]; then
      FIRST_STDERR_LINE=n
    else
      printf ','
    fi
    printf "\"%s\"" "$line"
  done <"$STDERR_FILE"
  printf '],'
  unset FIRST_STDERR_LINE

  printf '"rc":"%d"' "$RC"

  printf '}\n'

  rm -f "$STDOUT_FILE"
  rm -f "$STDERR_FILE"

  unset STDOUT_FILE
  unset STDERR_FILE
}
