# shellcheck shell=bash
# Shows: an EXIT trap runs however the shell ends: at the end of the
# script, after `exit 3`, after a failing command under `set -e`, and
# when SIGINT kills it. Inside the trap `$?` is the status the shell is
# about to exit with, and the trap does not change it; after a fatal
# signal bash shows `$?` as 0 there, the 130 only reaches the parent.
run_case() {
  echo "--- $1 ---"
  cat >case.sh
  bash case.sh
  echo "exit status: $?"
}

run_case 'normal end' <<'CASE'
trap 'echo "EXIT trap ran, status $?"' EXIT
echo 'script body'
CASE

run_case 'exit 3' <<'CASE'
trap 'echo "EXIT trap ran, status $?"' EXIT
echo 'script body'
exit 3
CASE

run_case 'error under set -e' <<'CASE'
set -e
trap 'echo "EXIT trap ran, status $?"' EXIT
echo 'script body'
ls /nonexistent-cairn-path 2>/dev/null
echo 'not printed'
CASE

run_case 'SIGINT (kill -INT $$)' <<'CASE'
trap 'echo "EXIT trap ran, status $?"' EXIT
echo 'script body'
kill -INT $$
echo 'not printed'
CASE

run_case 'SIGINT caught by its own trap, then exit 130' <<'CASE'
trap 'echo "INT trap ran"; exit 130' INT
trap 'echo "EXIT trap ran, status $?"' EXIT
echo 'script body'
kill -INT $$
echo 'not printed'
CASE
