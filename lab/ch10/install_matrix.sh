# shellcheck shell=bash
# Shows: install.sh run under five shells into five prefixes. A shell
# passes when install.sh exits 0 and the installed cairn prints its
# version. Exits 1 if any shell fails.
shells=(dash "${CAIRN_BUSYBOX} sh" yash mksh 'bash --posix')
failed=0
n=0
for sh_cmd in "${shells[@]}"; do
  n=$((n + 1))
  prefix="${LAB_TMP}/prefix${n}"
  label="${sh_cmd/#${CAIRN_BUSYBOX}/busybox}"
  # shellcheck disable=SC2086
  if ${sh_cmd} "${CAIRN_ROOT}/install.sh" --prefix "${prefix}" >/dev/null \
    && [[ "$("${prefix}/bin/cairn" --version)" == 'cairn 0.1.0' ]]; then
    echo "ok ${label}"
  else
    echo "FAIL ${label}"
    failed=1
  fi
done
exit "${failed}"
