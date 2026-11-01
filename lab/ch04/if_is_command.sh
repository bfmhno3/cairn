# shellcheck shell=bash
# Shows: `if` runs a command and branches on its exit status; `[` is a
# command too (a builtin, with a twin in /usr/bin or similar).
printf 'alpha\nbeta\n' >"${LAB_TMP}/words.txt"

if grep -q beta "${LAB_TMP}/words.txt"; then
  echo 'grep -q beta: status 0, then-branch'
fi
if ! grep -q gamma "${LAB_TMP}/words.txt"; then
  echo 'grep -q gamma: status 1, ! turns it into success'
fi

# if 测试的是整个命令列表的最后一条命令。
if
  echo 'side effect'
  false
then
  echo 'not reached'
else
  echo 'the list ends with false, so else runs'
fi

echo '--- type -a [ ---'
type -a [ | awk '!seen[$0]++' | head -n 2
