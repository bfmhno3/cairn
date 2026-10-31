# shellcheck shell=bash disable=SC2030,SC2031
# Shows: declare attributes turn a plain string variable into something
# with behavior: integer, readonly, array, map, case folding, nameref,
# export. `declare -p` prints the real definition.
where_stripped() {
  [[ "$1" =~ line\ [0-9]+:\ (.*) ]] && echo "${BASH_REMATCH[1]}" || echo "$1"
}

echo '--- -i integer: assignments are arithmetic'
declare -i n=2+3
echo "n=${n}"
n+=1
echo "n+=1 gives ${n}"
n=abc
echo "n=abc gives ${n}"
declare -p n

echo '--- -r readonly: a second assignment fails (run in a subshell)'
declare -r pi=3
msg="$(
  (
    pi=4
    echo 'not reached: the subshell aborts on the assignment'
  ) 2>&1
)"
where_stripped "${msg}"
echo "pi is still ${pi}"
declare -p pi

echo '--- -a indexed array'
declare -a fruits=(apple 'sour cherry' fig)
fruits+=(plum)
echo "count=${#fruits[@]} second='${fruits[1]}'"
declare -p fruits

echo '--- -A associative array'
declare -A color=([apple]=red [fig]=purple)
color[plum]=blue
keys="$(printf '%s\n' "${!color[@]}" | sort | tr '\n' ' ')"
echo "plum is ${color[plum]}, keys: ${keys}"

echo '--- -l / -u change the case on assignment'
declare -l lower=MiXeD
declare -u upper=MiXeD
echo "lower=${lower} upper=${upper}"

echo '--- -n nameref: another name for a variable'
target=original
declare -n alias_name=target
alias_name=changed_via_alias
echo "target=${target}"
declare -p alias_name

echo '--- -x export'
declare -x LAB_EXPORTED=yes
bash -c 'echo "child sees LAB_EXPORTED=${LAB_EXPORTED-<unset>}"'
declare -p LAB_EXPORTED
