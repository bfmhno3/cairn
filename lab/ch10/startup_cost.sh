# shellcheck shell=bash
# Shows: how long each shell takes to start and exit (`-c :`), measured with
# hyperfine without an intermediate shell (-N), 200 runs after 20 warm-up
# runs. Prints the median in ms and the ratio to dash. Timings differ from
# run to run; no threshold is asserted.
json="${LAB_TMP}/hyperfine.json"
names=(dash bash 'busybox sh' mksh yash)
cmds=(
  'dash -c :'
  'bash -c :'
  "${CAIRN_BUSYBOX} sh -c :"
  'mksh -c :'
  'yash -c :'
)
hyperfine -N --warmup 20 --runs 200 --export-json "${json}" \
  "${cmds[@]}" >/dev/null || exit 1
printf '%-12s %10s %8s\n' shell 'median ms' 'vs dash'
jq -r --argjson n "$(printf '%s\n' "${names[@]}" | jq -R . | jq -s .)" \
  '(.results[0].median * 1000) as $base
   | .results | to_entries[]
   | [$n[.key], (.value.median * 1000), (.value.median * 1000 / $base)]
   | @tsv' "${json}" \
  | awk -F '\t' '{ printf "%-12s %10.2f %7.1fx\n", $1, $2, $3 }'
