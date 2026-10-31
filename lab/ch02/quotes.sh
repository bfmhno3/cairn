# shellcheck shell=bash
# Shows: single quotes, double quotes, $'...', backslash and nested
# "$(...)" quoting.
args="${CAIRN_ROOT}/lab/ch02/args.sh"
name='world'

echo "--- single quotes: nothing is special"
bash "${args}" 'hello $name \n $(date)'
echo '--- double quotes: $, ` and \ still work'
bash "${args}" "hello ${name} $((1 + 1))"
echo '--- $'"'"'...'"'"': ANSI-C escapes'
bash "${args}" $'tab\there' $'two\nlines'
echo '--- backslash outside quotes'
bash "${args}" a\ b \$name
echo '--- backslash inside double quotes'
bash "${args}" "a\"b" "c\\d" "e\nf"
echo '--- a single quote inside single quotes'
bash "${args}" 'it'\''s'
echo "--- \"\$(...)\" nests: inner quotes are independent"
bash "${args}" "$(printf '%s' "a  b")"
bash "${args}" "outer $(printf '<%s>' "in ner") end"
echo "--- unquoted \$(...) splits"
# shellcheck disable=SC2046 # BAD: deliberate
bash "${args}" $(printf '%s' "a  b")
