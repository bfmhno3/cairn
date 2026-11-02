# shellcheck shell=bash
# Shows: the value of $- and of `shopt -q login_shell` for the ways of
# starting bash. The letters: h hashall, B braceexpand, H histexpand,
# m monitor (job control), i interactive, c command from -c, s from stdin,
# e errexit, u nounset. Interactive runs use --norc, so no rc file can
# change the picture; their prompt warnings go to /dev/null. setsid(1)
# removes the controlling terminal, so the output is the same whether or
# not the lab is started from a terminal (without it, `bash -i` would
# try to take over the terminal, and `m` would appear in `$-`).
home="${LAB_TMP}/home"
mkdir "${home}" || exit 1
# 探针要在子 shell 里才展开，所以用单引号。
# shellcheck disable=SC2016
probe='printf "%-10s login=%s\n" "$-" \
  "$(shopt -q login_shell && echo yes || echo no)"'
printf '%s\n' "${probe}" >"${LAB_TMP}/probe.sh"

#######################################
# Run bash with the given arguments in the fake HOME, stdin empty.
# Arguments:
#   Label, then the bash arguments.
#######################################
show() {
  local label="$1"
  shift
  printf '%-36s ' "${label}"
  env -u BASH_ENV HOME="${home}" setsid --wait bash "$@" 2>/dev/null \
    </dev/null
}

show 'bash -c PROBE' -c "${probe}"
show 'bash -l -c PROBE' --noprofile -l -c "${probe}"
show 'bash -i -c PROBE' --norc -i -c "${probe}"
show 'bash -e -u -c PROBE' -e -u -c "${probe}"
show 'bash probe.sh' "${LAB_TMP}/probe.sh"
printf '%-36s ' 'bash -s < probe.sh'
env HOME="${home}" bash -s <"${LAB_TMP}/probe.sh"
printf '%-36s ' 'bash -i < probe.sh'
env HOME="${home}" setsid --wait bash --norc -i <"${LAB_TMP}/probe.sh" \
  2>/dev/null

echo '--- the usual test: is this shell interactive? ---'
for flags in '-c' '-i -c'; do
  # shellcheck disable=SC2086
  env HOME="${home}" setsid --wait bash --norc ${flags} \
    'if [[ $- == *i* ]]; then echo interactive; else echo not interactive; fi' \
    2>/dev/null </dev/null | sed "s/^/bash ${flags}: /"
done
