# shellcheck shell=bash
# Shows: redirections are applied left to right. `>f 2>&1` sends both
# streams to f; `2>&1 >f` copies the OLD stdout (the terminal/pipe) to
# stderr first, so only stdout lands in f.
noisy() {
  echo 'to stdout'
  echo 'to stderr' >&2
}

echo '--- noisy >f 2>&1 ---'
noisy >"${LAB_TMP}/a.txt" 2>&1
echo "file a.txt:"
cat "${LAB_TMP}/a.txt"

echo '--- noisy 2>&1 >f (stderr goes where stdout used to go) ---'
# 外面再套一层 2>/dev/null 看不到 stderr, 所以用 { ...; } 2>&1 把
# 屏幕上的内容收集起来, 区分"文件里"和"屏幕上"。
screen="$({ noisy 2>&1 >"${LAB_TMP}/b.txt"; } 2>&1)"
echo "file b.txt:"
cat "${LAB_TMP}/b.txt"
echo "screen:"
echo "${screen}"

echo '--- &> and |& are shorthands ---'
noisy &>"${LAB_TMP}/c.txt"
echo "file c.txt:"
cat "${LAB_TMP}/c.txt"
echo "noisy |& wc -l: $(noisy |& wc -l)"

echo '--- >> appends, > truncates ---'
echo one >"${LAB_TMP}/d.txt"
echo two >>"${LAB_TMP}/d.txt"
echo "lines after > then >>: $(wc -l <"${LAB_TMP}/d.txt")"
echo three >"${LAB_TMP}/d.txt"
echo "lines after another >: $(wc -l <"${LAB_TMP}/d.txt")"

echo '--- the classic mistake: reading and truncating the same file ---'
printf 'a\nb\nc\n' >"${LAB_TMP}/e.txt"
# BAD: the shell truncates e.txt before sort even starts.
# shellcheck disable=SC2094
sort "${LAB_TMP}/e.txt" >"${LAB_TMP}/e.txt"
echo "bytes left in e.txt: $(wc -c <"${LAB_TMP}/e.txt")"
