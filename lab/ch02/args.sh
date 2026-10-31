# shellcheck shell=bash
# Helper, not a lesson: prints argc=N, then every argument as <arg>.
# Other labs call it as: bash "${CAIRN_ROOT}/lab/ch02/args.sh" ARG...
# Run alone by the chapter runner it prints argc=0.
printf 'argc=%d\n' "$#"
for arg in "$@"; do
  printf '<%s>\n' "${arg}"
done
