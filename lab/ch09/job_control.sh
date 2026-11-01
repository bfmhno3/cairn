# shellcheck shell=bash
# Shows: job control in a script. `set -m` gives every background job its
# own process group (pgid = pid of the job), `jobs -l` and `kill %1` use
# the job table, `disown` removes a job from it. Without -m the job stays
# in the shell's group. PIDs are replaced by names so the output is the
# same on every run: SHELL is this script's bash, JOB the background
# sleep, GROUP the process group the script runs in (when the lab runs
# under scripts/chapter.sh, that is the group of timeout(1)).
shell_pid=$$
group="$(ps -o pgid= -p "${shell_pid}")"
group="${group// /}"

#######################################
# Replace PIDs in the text on stdin by their names; in ps rows keep only
# the first letter of the state (S, not Ss or S+, which depend on the
# terminal).
# Arguments:
#   The job's pid.
#######################################
mask_pids() {
  local job="$1"
  local line pid pgid state rest
  while IFS= read -r line; do
    read -r pid pgid state rest <<<"${line}"
    if [[ "${pid}" =~ ^[0-9]+$ && "${pgid}" =~ ^[0-9]+$ ]]; then
      line="${pid} ${pgid} ${state:0:1} ${rest}"
    fi
    line="${line//"${job}"/JOB}"
    line="${line//"${group}"/GROUP}"
    line="${line//"${shell_pid}"/SHELL}"
    line="${line//"${BASH_SOURCE[0]}"/job_control.sh}"
    printf '%s\n' "${line}"
  done
}

#######################################
# Wait until the background job is a sleeping sleep process: right after
# the fork it is still a copy of bash, and ps would show that.
# Arguments:
#   The job's pid.
#######################################
wait_until_asleep() {
  until [[ "$(ps -o comm=,stat= -p "$1")" == sleep\ *S* ]]; do
    :
  done
}

#######################################
# Print the pid/pgid table of the shell and the job, masked.
# Arguments:
#   The job's pid.
#######################################
show_ps() {
  ps -o pid,pgid,stat,cmd -p "${shell_pid},$1" | mask_pids "$1"
}

echo '--- set -m: the job gets its own process group ---'
set -m
sleep 30 &
job=$!
wait_until_asleep "${job}"
echo 'jobs -l:'
jobs -l | mask_pids "${job}"
echo 'ps -o pid,pgid,stat,cmd:'
show_ps "${job}"
kill %1
wait "${job}"
echo "kill %1, then wait: status $?"
echo "jobs after that: $(jobs | wc -l) line(s)"

echo "--- set +m: the job stays in the shell's group ---"
set +m
sleep 30 &
job=$!
wait_until_asleep "${job}"
show_ps "${job}"
kill "${job}"
wait "${job}"

echo '--- disown: still running, no longer in the job table ---'
set -m
sleep 30 &
job=$!
disown
echo "jobs: $(jobs | wc -l) line(s)"
if kill -0 "${job}" 2>/dev/null; then
  echo 'the process is still alive'
fi
kill "${job}"
wait "${job}"
echo 'killed with kill PID'
