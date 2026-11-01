# shellcheck shell=bash
# Shows: `[ $x = y ]` breaks when x is empty; `[[ ]]` does not. Also
# pattern matching (unquoted RHS) vs literal comparison (quoted RHS).
x=''

echo "--- [ \$x = y ] with x empty ---"
# BAD: unquoted expansion vanishes, `[` sees only `= y ]`.
# shellcheck disable=SC2086
[ $x = y ]
echo "status $?"

echo "--- [[ \${x} == y ]] with x empty ---"
if [[ ${x} == y ]]; then
  echo 'equal'
else
  echo 'not equal, no error'
fi

echo '--- pattern vs quoted RHS ---'
file='report.txt'
if [[ "${file}" == *.txt ]]; then
  echo 'report.txt == *.txt   : true (pattern)'
fi
if [[ "${file}" == "*.txt" ]]; then
  echo 'quoted: true'
else
  echo 'report.txt == "*.txt" : false (literal asterisk)'
fi
star='*.txt'
# BAD: unquoted RHS is a pattern.
# shellcheck disable=SC2053
if [[ "${file}" == ${star} ]]; then
  echo "unquoted \${star}: true (pattern again)"
fi
