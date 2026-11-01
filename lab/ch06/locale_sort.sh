# shellcheck shell=bash
# Shows: sort order depends on the locale. LC_ALL=C compares bytes;
# en_US.UTF-8 uses the language's collation rules. Then the cost: sort
# on 1,000,000 lines in both locales, median of 5 runs in ms.
printf '%s\n' banana Apple apple Banana cherry 中文 文本 _tmp 10 9 \
  >mixed.txt

echo '--- LC_ALL=C ---'
LC_ALL=C sort mixed.txt | paste -sd' '
echo '--- LC_ALL=en_US.UTF-8 ---'
LC_ALL=en_US.UTF-8 sort mixed.txt | paste -sd' '

echo '--- the same with sort -f and -n ---'
LC_ALL=C sort -f mixed.txt | paste -sd' '
LC_ALL=en_US.UTF-8 sort -n mixed.txt | paste -sd' '

echo '--- 1,000,000 lines of random words ---'
awk 'BEGIN {
  srand(1)
  for (i = 0; i < 1000000; i++) {
    printf "%c%c%c%c%c%d\n", 97 + int(rand() * 26) - 32 * (i % 3 == 0),
      97 + int(rand() * 26), 97 + int(rand() * 26),
      97 + int(rand() * 26), 97 + int(rand() * 26), int(rand() * 1000)
  }
}' >big.txt
wc -l <big.txt

median_ms() {
  local -a times=()
  local start
  for _ in 1 2 3 4 5; do
    start="${EPOCHREALTIME/./}"
    "$@" >/dev/null
    times+=($((${EPOCHREALTIME/./} - start)))
  done
  local mid
  mid="$(printf '%s\n' "${times[@]}" | sort -n | sed -n 3p)"
  echo "$((mid / 1000))"
}
sort_c() { LC_ALL=C sort big.txt; }
sort_utf8() { LC_ALL=en_US.UTF-8 sort big.txt; }
c="$(median_ms sort_c)"
u="$(median_ms sort_utf8)"
echo "LC_ALL=C:           ${c} ms"
echo "LC_ALL=en_US.UTF-8: ${u} ms"
printf 'ratio: %d.%dx\n' "$((u / c))" "$((u * 10 / c % 10))"
