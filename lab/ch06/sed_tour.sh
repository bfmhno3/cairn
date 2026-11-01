# shellcheck shell=bash
# Shows: sed substitution, -n with /re/p, address ranges, -E groups,
# and why sed -i is dangerous for a hard-linked snapshot: it writes a
# new file and renames it over the old one, so the inode changes and
# the link to the other name is silently cut.
cat >poem.txt <<'EOF'
alpha one
beta two
gamma three
delta four
epsilon five
EOF

echo '--- s///: first match per line, then g for every match ---'
echo 'a-b-c-d' | sed 's/-/+/'
echo 'a-b-c-d' | sed 's/-/+/g'
echo 'a-b-c-d' | sed 's/-/+/2'
echo '--- another delimiter, and & for the whole match ---'
echo '/usr/local/bin' | sed 's|/usr/local|/opt|'
echo 'cat' | sed 's/.*/[&]/'

echo '--- -n and p: print only matching lines ---'
sed -n '/ta/p' poem.txt
echo '--- a line number, last line, and a range ---'
sed -n '2p' poem.txt
sed -n '$p' poem.txt
sed -n '2,4p' poem.txt
echo '--- range between two patterns, and d to delete ---'
sed -n '/beta/,/delta/p' poem.txt
sed '2,4d' poem.txt
echo '--- first,~step and 0~2 (GNU): every second line ---'
sed -n '0~2p' poem.txt

echo '--- -E and groups: swap the two words ---'
sed -E 's/^([a-z]+) ([a-z]+)$/\2 \1/' poem.txt
echo '--- -E with alternation and a counted repeat ---'
echo 'ab123 cd4567' | sed -E 's/[0-9]{3,}/<&>/g'
echo 'foo bar' | sed -E 's/(foo|bar)/X/g'

echo '--- sed -i: the inode changes ---'
echo data >orig
ln orig linked
printf 'before: orig inode %s, linked inode %s, links %s\n' \
  "$(stat -c %i orig)" "$(stat -c %i linked)" "$(stat -c %h orig)"
sed -i 's/data/changed/' orig
printf 'after:  orig inode %s, linked inode %s, links %s\n' \
  "$(stat -c %i orig)" "$(stat -c %i linked)" "$(stat -c %h orig)"
echo "orig:   $(cat orig)"
echo "linked: $(cat linked)"
echo '--- a redirect keeps the inode: both names see the change ---'
echo data >orig2
ln orig2 linked2
before="$(stat -c %i orig2)"
sed 's/data/changed/' orig2 >orig2.new
cat orig2.new >orig2
after="$(stat -c %i orig2)"
echo "inode before ${before}, after ${after}, linked2: $(cat linked2)"
