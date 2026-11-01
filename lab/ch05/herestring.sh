# shellcheck shell=bash
# Shows: here-strings (`<<<`) feed one string plus a newline to stdin,
# with no subshell, unlike `echo ... |`.
echo '--- read with <<< keeps the variables ---'
read -r first second rest <<<'alpha beta gamma delta'
echo "first=${first} second=${second} rest=${rest}"

echo '--- echo | read loses them (subshell) ---'
unset first
# BAD: read runs in a subshell, first is not set afterwards.
# shellcheck disable=SC2030
echo 'alpha beta' | read -r first _
# shellcheck disable=SC2031
echo "first after pipe: '${first:-}'"

echo '--- <<< adds a trailing newline ---'
wc -c <<<'abc'
printf 'abc' | wc -c

echo '--- grep a variable without echo ---'
text=$'apple\nbanana\ncherry'
grep -c an <<<"${text}"

echo '--- splitting on a custom IFS ---'
IFS=: read -r user _ uid _ <<<'root:x:0:0:root'
echo "user=${user} uid=${uid}"
