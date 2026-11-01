# shellcheck shell=bash
# Exercise solution: run a command so that its stdout and stderr go to
# two separate files AND both still show on the terminal, using process
# substitution with tee.
tee_both() {
  local out="$1"
  local err="$2"
  shift 2
  "$@" > >(tee "${out}") 2> >(tee "${err}" >&2)
}

noisy() {
  echo 'a line on stdout'
  echo 'a line on stderr' >&2
}

tee_both "${LAB_TMP}/out.txt" "${LAB_TMP}/err.txt" noisy 2>"${LAB_TMP}/screen_err.txt"
# 等 tee 进程把数据写完。
sleep 0.3
echo '--- out.txt ---'
cat "${LAB_TMP}/out.txt"
echo '--- err.txt ---'
cat "${LAB_TMP}/err.txt"
echo '--- what the terminal got on stderr ---'
cat "${LAB_TMP}/screen_err.txt"
