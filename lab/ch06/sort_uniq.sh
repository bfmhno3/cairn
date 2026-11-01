# shellcheck shell=bash
# Shows: sort keys (-k2,2n), -t, stable -s, and uniq -c | sort -rn.
cat >sales.txt <<'EOF'
north 10 apple
south 9 pear
east 10 fig
west 100 apple
north 9 fig
south 10 apple
EOF

echo '--- plain sort: compares whole lines as text ---'
sort sales.txt
echo '--- sort -k2 : key runs from field 2 to the END of the line ---'
sort -k2 sales.txt
echo '--- sort -k2,2n : field 2 only, numeric ---'
sort -k2,2n sales.txt
echo '--- sort -k2,2n -k1,1r : ties broken by name, reversed ---'
sort -k2,2n -k1,1r sales.txt
echo '--- sort -s -k2,2n : stable, ties keep input order ---'
sort -s -k2,2n sales.txt

echo '--- -t: a field separator other than blanks ---'
cat >passwd.txt <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bob:x:1000:1000:Bob:/home/bob:/bin/bash
EOF
sort -t: -k3,3nr passwd.txt | cut -d: -f1,3

echo '--- uniq needs sorted input: only neighbours collapse ---'
printf 'a\nb\na\n' | uniq
printf 'a\nb\na\n' | sort | uniq
echo '--- sort | uniq -c | sort -rn : frequency table ---'
cut -d' ' -f3 sales.txt \
  | sort \
  | uniq -c \
  | sort -rn
echo '--- sort -u and uniq -d ---'
cut -d' ' -f3 sales.txt | sort -u
cut -d' ' -f3 sales.txt | sort | uniq -d
