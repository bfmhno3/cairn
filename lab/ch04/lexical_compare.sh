# shellcheck shell=bash
# Shows: inside [[ ]], > and < compare strings; (( )) compares numbers.
# BAD: > in [[ ]] is a string comparison.
# shellcheck disable=SC2071,SC2050
if [[ 22 > 4 ]]; then
  echo '[[ 22 > 4 ]]  true'
else
  echo '[[ 22 > 4 ]]  false (string order: "2" sorts before "4")'
fi
if ((22 > 4)); then
  echo '(( 22 > 4 ))  true'
else
  echo '(( 22 > 4 ))  false'
fi
if [[ 22 -gt 4 ]]; then
  echo '[[ 22 -gt 4 ]] true'
fi
