# shellcheck shell=bash
# Shows: what the prompt variables expand to. `${PS1@P}` runs the prompt
# expansion on a script's variable, so it can be inspected without a
# terminal. Then an interactive bash fed from a here-string prints PS1,
# PS0 and PROMPT_COMMAND at the places where a terminal would show them,
# and PS4 prefixes the lines of `set -x`.
# User and host name are replaced by USER and HOST in the output.
home="${LAB_TMP}/home"
mkdir -p "${home}/src" || exit 1
export HOME="${home}"
cd "${home}/src" || exit 1

#######################################
# Print a prompt-expanded string with the user and host name masked.
# Arguments:
#   Expanded text.
#######################################
mask() {
  local text="$1"
  text="${text//"$(id -un)@${HOSTNAME%%.*}"/USER@HOST}"
  printf '%s\n' "${text}"
}

echo "--- PS1 and \${PS1@P} ---"
PS1='\u@\h:\w\$ '
echo "PS1 is: ${PS1}"
mask "${PS1@P}"
PS1='\w \$ '
echo "PS1 is: ${PS1}"
echo "${PS1@P}"
PS1='jobs=\j \$ '
echo "PS1 is: ${PS1}"
echo "${PS1@P}"

echo '--- PS0, PS1 and PROMPT_COMMAND in an interactive bash ---'
# 提示符写在 stderr, 所以合并两个输出; 去掉没有终端时的作业控制警告。
{
  cat <<'COMMANDS'
PS1='ps1> '
PS0='[ps0] '
PROMPT_COMMAND='echo "[prompt_command]"'
echo first
echo second
COMMANDS
} | bash --norc -i 2>&1 | grep -v -e '^bash: cannot set terminal' \
  -e '^bash: no job control'
echo

echo '--- PS4 with set -x ---'
PS4='+ line ${LINENO}: ' bash -x -c 'a=1
b=$((a + 1))
echo "b is ${b}"' 2>&1
printf '%s\n' 'f() { echo in f; }' 'f' >trace_me.sh
PS4='+${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
  bash -x trace_me.sh 2>&1
