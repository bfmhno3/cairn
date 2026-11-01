# shellcheck shell=bash
# Exercise solution: countdown N prints N down to 1, then "liftoff".
# Rejects anything that is not a positive integer, or has a leading
# zero (08 would be read as octal), with status 2.
countdown() {
  if [[ ! "$1" =~ ^[1-9][0-9]*$ ]]; then
    echo "countdown: not a positive integer: $1" >&2
    return 2
  fi
  local n
  for ((n = $1; n >= 1; n--)); do
    echo "${n}"
  done
  echo 'liftoff'
}

countdown 3
countdown abc
echo "status for abc: $?"
countdown 0
echo "status for 0: $?"
