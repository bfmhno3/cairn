# shellcheck shell=bash
# Exercise solution: a prompt that shows how old the newest snapshot is.
# cairn_prompt REPO prints "[cairn 2h]" (s, m, h or d) or "[cairn -]" for
# a repository without snapshots. PS1 calls it through $(...), which bash
# runs again for every prompt; ${PS1@P} does the same expansion here.
# PROMPT_NOW (seconds since the epoch) replaces the clock so that the
# lab prints the same thing on every run.
source "${CAIRN_ROOT}/lib/cairn/repo.sh"
repo="${LAB_TMP}/repo"
cairn -q -c "${LAB_TMP}/cairn.conf" init "${repo}" || exit 1

#######################################
# Print the age of the newest snapshot of a repository.
# Globals:
#   PROMPT_NOW (optional), EPOCHSECONDS
# Arguments:
#   Repository directory.
# Outputs:
#   "[cairn <age>]" or "[cairn -]" on stdout.
#######################################
cairn_prompt() {
  local name
  if ! name="$(cairn::repo::latest "$1")"; then
    printf '[cairn -]'
    return 0
  fi
  # 20261031T090000Z -> 2026-10-31 09:00:00
  local stamp="${name:0:4}-${name:4:2}-${name:6:2}"
  stamp+=" ${name:9:2}:${name:11:2}:${name:13:2}"
  local born now age
  born="$(date -u -d "${stamp}" +%s)" || return 0
  now="${PROMPT_NOW:-${EPOCHSECONDS}}"
  age=$((now - born))
  if ((age < 60)); then
    printf '[cairn %ds]' "${age}"
  elif ((age < 3600)); then
    printf '[cairn %dm]' $((age / 60))
  elif ((age < 86400)); then
    printf '[cairn %dh]' $((age / 3600))
  else
    printf '[cairn %dd]' $((age / 86400))
  fi
}

# 单引号：$(...) 要在每次显示提示符时才运行。
PS1='$(cairn_prompt "${repo}") \$ '
echo "PS1 is: ${PS1}"
echo "empty repository:      ${PS1@P}"
printf 'source = %s\n' "${LAB_TMP}" >>"${LAB_TMP}/cairn.conf"
CAIRN_NOW=20261031T090000Z cairn -q -c "${LAB_TMP}/cairn.conf" snapshot \
  >/dev/null || exit 1
for offset in 30 2700 9900 266400; do
  PROMPT_NOW=$(($(date -u -d '2026-10-31 09:00:00' +%s) + offset))
  echo "snapshot is ${offset}s old: ${PS1@P}"
done
