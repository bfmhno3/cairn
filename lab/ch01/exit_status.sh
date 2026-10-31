# shellcheck shell=bash
# Shows: how exit statuses flow through $?, &&, ||, ! and exit.
true
echo "after true:  $?"
false
echo "after false: $?"
true && echo "&& ran after success"
false || echo "|| ran after failure"
false && echo "never printed"
echo "status of a skipped &&: $?"
! true
echo "! true gives: $?"
! false
echo "! false gives: $?"
bash -c 'exit 256'
echo "exit 256 gives: $?"
bash -c 'exit -1'
echo "exit -1 gives:  $?"
bash -c 'exit 300'
echo "exit 300 gives: $?"
