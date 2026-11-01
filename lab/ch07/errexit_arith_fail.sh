# shellcheck shell=bash
# Shows: `(( i++ ))` with i=0 evaluates to 0, and an arithmetic command
# whose value is 0 has exit status 1, so `set -e` stops the script right
# there. Use i=$((i + 1)) or (( ++i )) instead. Ends in _fail.sh: exit 1.
set -e
i=0
echo "i=${i}, before (( i++ ))"
((i++)) # BAD: post-increment yields the old value 0, status 1
echo "i=${i}, after (not printed)"
