# shellcheck shell=bash
# Shows: `cmd &` starts a background job and sets $!; `wait` blocks
# until the jobs finish. Three `sleep 1 &` take about 1 s, not 3 s.
# `wait -n` returns when the first job ends.
now_ms() {
  local t="${EPOCHREALTIME/./}"
  printf '%s\n' "$((t / 1000))"
}

echo '--- sequential: three sleeps ---'
start="$(now_ms)"
sleep 1
sleep 1
sleep 1
echo "wall: $(($(now_ms) - start)) ms (expect about 3000)"

echo '--- parallel: three sleeps with & and wait ---'
start="$(now_ms)"
sleep 1 &
echo "first pid: $!"
sleep 1 &
sleep 1 &
wait
echo "wall: $(($(now_ms) - start)) ms (expect about 1000)"

echo '--- $! is the last background job ---'
sleep 0.3 &
pid=$!
wait "${pid}"
echo "waited for ${pid}, status $?"

echo '--- wait returns the status of the job ---'
(exit 5) &
wait $!
echo "status: $?"

echo '--- wait -n: first to finish ---'
sleep 0.6 &
slow=$!
sleep 0.1 &
fast=$!
wait -n -p done_pid
if [[ "${done_pid}" == "${fast}" ]]; then
  echo 'wait -n returned the short job first'
fi
wait "${slow}"
echo "slow job finished too: $?"
