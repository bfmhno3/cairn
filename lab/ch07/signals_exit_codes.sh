# shellcheck shell=bash
# Shows: signal numbers with `kill -l`, and the shell convention that a
# process killed by signal n has exit status 128 + n: TERM (15) gives
# 143, KILL (9) gives 137, INT (2) gives 130.
echo '--- kill -l ---'
kill -l
echo '--- number <-> name ---'
echo "kill -l 15  -> $(kill -l 15)"
echo "kill -l 143 -> $(kill -l 143)  (a status above 128 is accepted)"
echo "kill -l INT -> $(kill -l INT)"

echo '--- exit status of a child killed by a signal ---'
for sig in TERM KILL INT HUP; do
  sleep 30 &
  pid=$!
  kill -s "${sig}" "${pid}"
  wait "${pid}"
  status=$?
  echo "kill -${sig}: status ${status} = 128 + $((status - 128))" \
    "($(kill -l "${status}"))"
done
