# shellcheck shell=bash
# Shows: cut, tr, paste, wc, head and tail on a small CSV-like table.
cat >table.txt <<'EOF'
alice,30,berlin
bob,25,paris
carol,41,rome
dave,25,oslo
EOF

echo '--- cut -d, -f1,3: fields ---'
cut -d, -f1,3 table.txt
echo '--- cut -d, -f2- : from field 2 to the end ---'
cut -d, -f2- table.txt
echo '--- cut -c1-3: characters 1 to 3 ---'
cut -c1-3 table.txt
echo '--- cut --complement -d, -f2 ---'
cut --complement -d, -f2 table.txt

echo '--- tr: translate, delete, squeeze ---'
echo 'Hello World' | tr '[:lower:]' '[:upper:]'
echo 'Hello World' | tr -d 'lo'
echo 'a   b    c' | tr -s ' '
echo 'a:b:c' | tr ':' '\n'
echo '--- tr -c: complement of the set (keep only digits) ---'
echo 'tel: 030-1234' | tr -cd '0-9\n'

echo '--- paste: columns side by side, or one line ---'
cut -d, -f1 table.txt >names.txt
cut -d, -f2 table.txt >ages.txt
paste names.txt ages.txt
paste -d: names.txt ages.txt
paste -sd, names.txt

echo '--- wc: lines, words, bytes ---'
wc -l <table.txt
wc -w <table.txt
wc -c <table.txt
echo '--- wc -m vs wc -c on a Chinese line (UTF-8 locale) ---'
printf '中文\n' | LC_ALL=en_US.UTF-8 wc -m
printf '中文\n' | wc -c

echo '--- head and tail ---'
head -n 2 table.txt
tail -n 2 table.txt
echo '--- tail -n +3: from line 3 on; head -n -1: all but the last ---'
tail -n +3 table.txt
head -n -1 table.txt
