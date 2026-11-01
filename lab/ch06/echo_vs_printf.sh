# shellcheck shell=bash
# Shows: echo treats some arguments as options, printf does not.
# echo -n and echo -e, a variable that holds "-n", and printf reusing
# its format for extra arguments.
show() { od -An -c | sed 's/^ *//'; }

echo '--- echo -n: no trailing newline ---'
echo -n hi | show
echo hi | show

echo '--- echo -e: bash only decodes escapes when asked ---'
# BAD: the point of the lab is that echo does not decode \t here.
# shellcheck disable=SC2028
echo 'a\tb' | show
echo -e 'a\tb' | show

echo "--- x=-n; echo \"\${x}\": the data is taken for an option ---"
x=-n
echo "${x}" | show
printf '%s\n' "${x}" | show

echo '--- echo -- does not help in bash: it is printed ---'
echo -- hi | show

echo '--- the same lines with POSIX mode xpg_echo ---'
(
  shopt -s xpg_echo
  # BAD: same as above, xpg_echo makes echo decode \t by itself.
  # shellcheck disable=SC2028
  echo 'a\tb' | show
)

echo '--- printf reuses its format for extra arguments ---'
printf '%s\n' one two three
printf '%s=%s\n' a 1 b 2 c 3
printf '<%s>' x y z
printf '\n'

echo '--- printf with too few arguments: empty string and 0 ---'
# BAD: too few arguments on purpose.
# shellcheck disable=SC2183
printf '[%s] [%d]\n'

echo '--- printf %q quotes for reuse in the shell ---'
printf '%q\n' 'with space' "it's" $'tab\there'
