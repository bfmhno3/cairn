# shellcheck shell=bash
# Shows: a pipeline is concurrent processes (each with its own PID);
# `yes | head -n 1` ends because yes dies of SIGPIPE (141); PIPESTATUS
# holds every stage's status; pipefail makes the pipeline's own status
# the last non-zero one.
echo '--- every stage is its own process ---'
# shellcheck disable=SC2216
sleep 1 | sleep 1 | sleep 1 &
# 三个 sleep 同时在跑, 它们的父进程都是本 shell。
sleep 0.2
pids="$(pgrep -P "$$" -x sleep | wc -l)"
echo "sleep processes started by this shell: ${pids}"
wait

echo '--- yes | head -n 1 ---'
yes | head -n 1
echo "PIPESTATUS: ${PIPESTATUS[*]}"
echo "128 + SIGPIPE($(kill -l PIPE)) = $((128 + $(kill -l PIPE)))"

echo '--- $? only sees the last stage ---'
yes | head -n 1 >/dev/null
echo "\$? = $?"

echo '--- pipefail off: false | true ---'
false | true
echo "\$? = $?, PIPESTATUS = ${PIPESTATUS[*]}"

echo '--- pipefail on ---'
set -o pipefail
false | true
echo "\$? = $?, PIPESTATUS = ${PIPESTATUS[*]}"
yes | head -n 1 >/dev/null
echo "yes | head: \$? = $?"
set +o pipefail

echo '--- save PIPESTATUS at once: the next command overwrites it ---'
false | true
echo "first: ${PIPESTATUS[*]}"
echo "second: ${PIPESTATUS[*]}"
