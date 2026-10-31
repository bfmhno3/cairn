# shellcheck shell=bash
# Shows: `local x="$(cmd)"` hides the exit status of cmd behind the
# status of `local` itself. Declare first, assign second (SC2155).
bad() {
  # BAD: the status of `false` is lost.
  # shellcheck disable=SC2155
  local x="$(false)"
  echo "bad:  status after local x=\"\$(false)\" is $?"
}

# shellcheck disable=SC2034 # x is only there to carry the status
good() {
  local x
  x="$(false)"
  echo "good: status after x=\"\$(false)\" is $?"
}

bad
good
