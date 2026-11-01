# shellcheck shell=bash
# Shows: awk as a small language: pattern { action } rules, fields,
# -F, NR and NF, BEGIN and END, associative arrays, printf, -v.
cat >sales.txt <<'EOF'
north 10 apple
south 9 pear
east 10 fig
west 100 apple
north 9 fig
EOF

echo "--- fields: \$1 and \$3, whole line \$0 ---"
awk '{ print $3, $1 }' sales.txt
echo '--- NR and NF ---'
awk '{ print NR, NF, $NF }' sales.txt
echo '--- a pattern selects lines; no action means print ---'
awk '$2 > 9' sales.txt
awk '/apple/ { print $1 }' sales.txt
awk 'NR == 2, NR == 3' sales.txt
echo '--- -F: another field separator ---'
echo 'root:x:0:0:root:/root:/bin/bash' | awk -F: '{ print $1, $NF }'
echo 'a,b;c' | awk -F'[,;]' '{ print $2, $3 }'
echo '--- BEGIN and END: sum and average ---'
awk 'BEGIN { print "start" }
  { sum += $2 }
  END { print "sum", sum, "avg", sum / NR }' sales.txt
echo '--- associative array: total per fruit ---'
awk '{ total[$3] += $2 } END { for (k in total) print k, total[k] }' \
  sales.txt | sort
echo '--- printf: formatted columns ---'
awk '{ printf "%-6s|%5d|%s\n", $1, $2, $3 }' sales.txt
echo '--- -v: pass a shell value into awk (not by splicing it in) ---'
min=10
awk -v min="${min}" '$2 >= min { print $1, $2 }' sales.txt
echo '--- assignments are numbers or strings by use ---'
awk 'BEGIN { x = "10"; y = 9; print (x > y), ("10" > "9") }'
echo "--- modify a field: \$0 is rebuilt with OFS ---"
awk 'BEGIN { OFS = "," } { $1 = toupper($1); print }' sales.txt
echo '--- uninitialised variables are 0 or "" ---'
awk 'BEGIN { print n + 1, "[" s "]" }'
