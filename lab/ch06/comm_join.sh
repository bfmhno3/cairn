# shellcheck shell=bash
# Shows: comm and join, both need input sorted in the same order; this
# is what cairn diff does with manifests, done by hand.
printf '%s\n' a.txt b.txt c.txt d.txt >old.list
printf '%s\n' b.txt c.txt e.txt >new.list

echo '--- comm: three columns (only old, only new, both) ---'
comm old.list new.list
echo '--- comm -23: only in old (deleted) ---'
comm -23 old.list new.list
echo '--- comm -13: only in new (added) ---'
comm -13 old.list new.list
echo '--- comm -12: in both ---'
comm -12 old.list new.list

echo '--- comm on unsorted input: --check-order makes it an error ---'
printf '%s\n' b a \
  | comm --check-order - old.list 2>&1 >/dev/null \
  | sed 's/^comm: //'

echo '--- join: match lines of two files on a key field ---'
cat >size.txt <<'EOF'
a.txt 10
b.txt 20
c.txt 30
EOF
cat >owner.txt <<'EOF'
a.txt alice
c.txt carol
d.txt dave
EOF
join size.txt owner.txt
echo '--- join -a1: keep unmatched lines of the first file ---'
join -a1 size.txt owner.txt
echo '--- join -v2: only the unmatched lines of the second ---'
join -v2 size.txt owner.txt
echo '--- join -t, -1 2 -2 1: other separator and key columns ---'
printf '%s\n' 'x,a.txt' 'y,c.txt' >map.csv
join -t, -1 2 -2 1 <(sort -t, -k2,2 map.csv) <(printf '%s\n' \
  'a.txt,one' 'c.txt,three')
