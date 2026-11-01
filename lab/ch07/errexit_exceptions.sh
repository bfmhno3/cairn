# shellcheck shell=bash
# Shows: six places where `set -e` does not stop the script. Every case
# runs in its own `bash` child, prints a marker for each line it reaches
# and the child's exit status. BashFAQ 105 lists these exceptions:
# https://mywiki.wooledge.org/BashFAQ/105
run_case() {
  echo "--- $1 ---"
  cat >case.sh
  bash case.sh
  echo "exit status: $?"
}

run_case '1. if condition: false is tested, not fatal' <<'CASE'
set -e
if false; then echo 'then branch'; else echo 'else branch reached'; fi
echo 'line after if reached'
CASE

run_case '2. non-final element of &&' <<'CASE'
set -e
false && echo 'never printed'
echo 'line after && reached'
CASE

run_case '3. negated pipeline with !' <<'CASE'
set -e
! true
echo 'line after ! true reached'
CASE

run_case '4. function called in a condition: set -e is off inside it' <<'CASE'
set -e
f() {
  false
  echo 'f went on after false'
}
if f; then echo 'f succeeded'; fi
echo 'line after if f reached'
CASE

run_case '5a. local x=<failing substitution>: local masks the status' <<'CASE'
set -e
g() {
  local x="$(false)"
  echo "g went on, status of local: $?"
}
g
echo 'line after g reached'
CASE

run_case '5b. declare first, assign later: the status counts' <<'CASE'
set -e
h() {
  local x
  x="$(false)"
  echo 'h went on (not printed)'
}
h
echo 'line after h reached (not printed)'
CASE

run_case '6a. command substitution, no inherit_errexit' <<'CASE'
set -e
out="$(false; echo 'inside $(...) went on')"
echo "${out}"
CASE

run_case '6b. the same with shopt -s inherit_errexit' <<'CASE'
set -e
shopt -s inherit_errexit
out="$(false; echo 'inside $(...) went on (not printed)')"
echo "${out}"
CASE
