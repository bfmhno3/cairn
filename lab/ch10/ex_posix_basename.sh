# shellcheck shell=bash
# Shows: exercise solution. basename(1) written with parameter expansion
# only, in POSIX sh (no local: the body is a subshell). The lab checks it
# against the real basename under bash and under dash and exits 1 on any
# difference.

#######################################
# POSIX sh replacement for basename.
# Arguments:
#   PATH, optional SUFFIX to strip.
# Outputs:
#   The last path component without trailing slashes and without SUFFIX.
#######################################
posix_basename() (
  p="$1"
  suffix="${2:-}"
  [ -n "${p}" ] || exit 0
  while [ "${p}" != "${p%/}" ]; do
    p="${p%/}"
  done
  if [ -z "${p}" ]; then
    printf '/\n'
    exit 0
  fi
  p="${p##*/}"
  if [ -n "${suffix}" ] && [ "${p}" != "${suffix}" ]; then
    p="${p%"${suffix}"}"
  fi
  printf '%s\n' "${p}"
)

fails=0
while IFS='|' read -r path suffix; do
  want="$(basename -- "${path}" ${suffix:+"${suffix}"})"
  got_bash="$(posix_basename "${path}" "${suffix}")"
  got_dash="$(dash -c "$(declare -f posix_basename)
posix_basename \"\$@\"" dash "${path}" "${suffix}")"
  if [[ "${got_bash}" == "${want}" && "${got_dash}" == "${want}" ]]; then
    printf 'ok   %-20q -> %s\n' "${path}" "${want}"
  else
    printf 'FAIL %-20q want %s, bash %s, dash %s\n' "${path}" "${want}" \
      "${got_bash}" "${got_dash}"
    fails=1
  fi
done <<'CASES'
/usr/bin/cairn|
cairn|
dir/file.txt|.txt
dir/file.txt|.sh
/a/b///|
/|
//|
.txt|.txt
a b/c d|
CASES
exit "${fails}"
