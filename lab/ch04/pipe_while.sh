# shellcheck shell=bash
# Shows: a counter set inside `cmd | while` is lost (the loop runs in a
# subshell); it survives with < <(cmd), readarray and lastpipe.
echo '--- cmd | while ---'
count=0
# BAD: the loop body is a subshell, so count stays 0.
# shellcheck disable=SC2030
printf 'a\nb\nc\n' | while read -r _; do
  ((count += 1))
done
# shellcheck disable=SC2031
echo "count after pipe: ${count}"

echo '--- while ... done < <(cmd) ---'
count=0
while read -r _; do
  ((count += 1))
done < <(printf 'a\nb\nc\n')
echo "count: ${count}"

echo '--- readarray ---'
readarray -t lines < <(printf 'a\nb\nc\n')
echo "count: ${#lines[@]}"

echo '--- shopt -s lastpipe ---'
# lastpipe 只在作业控制关闭时生效 (脚本默认如此)。
shopt -s lastpipe
count=0
printf 'a\nb\nc\n' | while read -r _; do
  ((count += 1))
done
echo "count: ${count}"
