# shellcheck shell=bash
# Shows: `set -x` with a custom PS4 and BASH_XTRACEFD. The trace goes to
# a file instead of stderr, each line starts with the script name, the
# line number and the function name, so the normal output stays clean.
trace="${LAB_TMP}/trace.log"
exec {trace_fd}>"${trace}"
export BASH_XTRACEFD="${trace_fd}"
# 单引号: PS4 在每次输出跟踪行时才展开, 不是赋值的时候。
PS4='+${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '

double() {
  local n="$1"
  echo $((n * 2))
}

set -x
total=0
for n in 1 2 3; do
  total=$((total + $(double "${n}")))
done
set +x

echo "total: ${total}"
echo '--- trace.log ---'
cat "${trace}"
