# shellcheck shell=bash
# Shows: indexed and associative arrays. Word counts with an associative
# array; its iteration order is unspecified, so the result goes through
# sort.
text='the cat saw the dog and the dog saw the cat'

declare -A count=()
read -r -a words <<<"${text}"
for word in "${words[@]}"; do
  count[${word}]=$((${count[${word}]:-0} + 1))
done

echo "words: ${#words[@]}, distinct: ${#count[@]}"
for word in "${!count[@]}"; do
  printf '%s %d\n' "${word}" "${count[${word}]}"
done | sort

echo '--- membership and removal'
[[ -v count[cat] ]] && echo 'cat is a key'
[[ -v count[bird] ]] || echo 'bird is not a key'
unset 'count[cat]'
echo "after unset: ${#count[@]} keys"

echo '--- indexed arrays'
list=(a b c d e)
echo "slice [*]:1:3 -> ${list[*]:1:3}"
echo "last element -> ${list[-1]}"
list[9]=z
echo "sparse: indices ${!list[*]}, count ${#list[@]}"
