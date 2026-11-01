# shellcheck shell=bash
# Exercise solution: the 5 most common file extensions in a snapshot,
# by count (ties by name). Files without an extension (.hidden, Makefile)
# are skipped. Exits 1 if the result is not the expected one.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
mkdir "${src}" || exit 1
for name in a.txt b.txt c.txt d.txt e.txt f.txt g.md h.md i.md j.md \
  k.sh l.sh m.sh n.c o.c p.py q.py r.log .hidden Makefile s.tar.gz; do
  echo x >"${src}/${name}"
done
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"
name="$(CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1

# 取文件名里最后一个点之后的部分; 以点开头的隐藏文件没有扩展名。
find "${repo}/snapshots/${name}" -type f -printf '%f\n' \
  | awk -F. 'NF > 1 && $1 != "" { print $NF }' \
  | LC_ALL=C sort \
  | uniq -c \
  | LC_ALL=C sort -k1,1nr -k2,2 \
  | head -n 5 >top.txt
cat top.txt
printf '%s\n' '      6 txt' '      4 md' '      3 sh' '      2 c' \
  '      2 py' >expected.txt
diff expected.txt top.txt || exit 1
