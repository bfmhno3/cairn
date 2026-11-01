# shellcheck shell=bash
# Shows: a sha256sum line for "with space.txt". awk's $2 stops at the
# first blank, so the path is cut. sha256sum's layout is fixed: 64 hex
# digits, two blanks, then the path; substr by position keeps it whole.
printf 'space\n' >'with space.txt'
printf 'plain\n' >plain.txt
sha256sum plain.txt 'with space.txt' >sums.txt
cat sums.txt

echo "--- \$2: right for plain.txt, wrong for 'with space.txt' ---"
awk '{ print "[" $2 "]" }' sums.txt
echo "--- \$0 with the 64 + 2 characters cut off by position ---"
awk '{ print "[" substr($0, 67) "]" }' sums.txt
echo '--- the hash by position ---'
awk '{ print substr($0, 1, 64) }' sums.txt
echo '--- the same with field splitting on two blanks only ---'
awk -F'  ' '{ print "[" $2 "]" }' sums.txt

echo '--- a path with a newline: sha256sum escapes it and starts with \ ---'
printf 'x\n' >$'new\nline.txt'
sha256sum $'new\nline.txt' | cut -c1-1,66-
sha256sum $'new\nline.txt' \
  | awk '{ skip = (substr($0, 1, 1) == "\\")
    print "[" substr($0, 67 + skip) "]" }'
