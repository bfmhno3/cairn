# shellcheck shell=bash
# Shows: hashing 200 files of 1 MiB with `xargs -0 -P 1` versus
# `-P "$(nproc)"`. Median of 3 runs in ms, then the speedup. Timings are
# printed, never asserted.
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${LAB_TMP}/tree" --big 200 \
  || exit 1
cd "${LAB_TMP}/tree" || exit 1
jobs="$(nproc)"
echo "regular files: $(find . -type f -print0 | tr -cd '\0' | wc -c)," \
  "nproc: ${jobs}"

hash_all() {
  find . -type f -print0 \
    | xargs -0 -r -P "$1" -n 4 sha256sum >/dev/null
}

# 用 EPOCHREALTIME 做微秒差, 取 3 次的中位数 (毫秒)。
median_ms() {
  local -a times=()
  local start
  for _ in 1 2 3; do
    start="${EPOCHREALTIME/./}"
    hash_all "$1"
    times+=($(((${EPOCHREALTIME/./} - start) / 1000)))
  done
  printf '%s\n' "${times[@]}" | sort -n | sed -n 2p
}

hash_all 1 # 预热页缓存
serial="$(median_ms 1)"
parallel="$(median_ms "${jobs}")"
echo "-P 1:        ${serial} ms"
echo "-P ${jobs}:       ${parallel} ms"
printf 'speedup: %d.%dx\n' "$((serial / parallel))" \
  "$((serial * 10 / parallel % 10))"

echo '--- same hashes either way ---'
a="$(
  find . -type f -print0 \
    | xargs -0 -P 1 -n 4 sha256sum \
    | LC_ALL=C sort -k 2 \
    | sha256sum
)"
b="$(
  find . -type f -print0 \
    | xargs -0 -P "${jobs}" -n 4 sha256sum \
    | LC_ALL=C sort -k 2 \
    | sha256sum
)"
if [[ "${a}" == "${b}" ]]; then
  echo 'manifests are identical after sort -k 2'
else
  echo 'manifests differ'
  exit 1
fi
