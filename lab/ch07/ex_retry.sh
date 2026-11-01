# shellcheck shell=bash
# Exercise solution: `retry N cmd...` runs a command up to N times and
# sleeps between attempts, doubling the delay each time (100, 200, 400
# ... ms). Returns 0 on the first success, else the last status. The
# delays are printed, not measured.
retry() {
  local max="$1"
  shift
  local delay_ms=100
  local try=1
  local status secs
  while true; do
    "$@" && return 0
    status=$?
    if ((try >= max)); then
      echo "giving up after ${try} attempts (status ${status})" >&2
      return "${status}"
    fi
    printf -v secs '%d.%03d' "$((delay_ms / 1000))" "$((delay_ms % 1000))"
    echo "attempt ${try} failed (status ${status}); sleeping ${secs} s" >&2
    sleep "${secs}"
    delay_ms=$((delay_ms * 2))
    try=$((try + 1))
  done
}

# 前两次失败, 第三次成功。
flaky() {
  local n
  n="$(cat counter 2>/dev/null || echo 0)"
  n=$((n + 1))
  echo "${n}" >counter
  echo "flaky: call ${n}"
  ((n >= 3))
}

echo '--- succeeds on the third call ---'
retry 5 flaky
echo "retry status: $?"
echo '--- never succeeds: 4 attempts, last status is returned ---'
retry 4 bash -c 'exit 7'
echo "retry status: $?"
echo '--- first try works: no sleeping ---'
retry 3 true
echo "retry status: $?"
