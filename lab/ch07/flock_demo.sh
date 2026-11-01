# shellcheck shell=bash
# Shows: flock(1) locks an open file description. Two descriptors opened
# separately on one file conflict, even inside one process. The lock ends
# when the last descriptor that refers to it is closed, and a child that
# inherited the descriptor keeps the lock alive.
exec {fd1}>lockfile
exec {fd2}>lockfile

flock -n "${fd1}"
echo "first  flock -n: status $? (got the lock)"
flock -n "${fd2}"
echo "second flock -n: status $? (busy)"

echo '--- close the holder: the lock is free ---'
exec {fd1}>&-
flock -n "${fd2}"
echo "second flock -n: status $? (got the lock)"
flock -u "${fd2}"

echo '--- a child inherits the descriptor and keeps the lock ---'
exec {fd1}>lockfile
flock -n "${fd1}"
sleep 30 &
child=$!
exec {fd1}>&-
echo 'parent closed its descriptor, but the background sleep still has it'
flock -n "${fd2}"
echo "flock -n while the child lives: status $? (busy)"
kill "${child}"
wait "${child}"
flock -n "${fd2}"
echo "flock -n after the child died:  status $? (got the lock)"

echo '--- the command form: flock -n FILE COMMAND ---'
exec {fd1}>lockfile
flock -n "${fd1}"
flock -n lockfile true
echo "flock -n lockfile true while locked: status $?"
