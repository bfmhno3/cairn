# shellcheck shell=bash
# Shows: integer arithmetic in Bash and its limits.
echo "\$((3 + 4 * 2))       = $((3 + 4 * 2))"
echo "\$((16#ff))          = $((16#ff))"
echo "\$((2#1010))         = $((2#1010))"
echo "\$((7 / 2))          = $((7 / 2))  (integer division, no floats)"
echo "\$((-7 / 2))         = $((-7 / 2))  (truncates toward zero)"
echo "\$((-7 % 3))         = $((-7 % 3))"
echo "\$((2 ** 62))        = $((2 ** 62))"
echo "\$((2 ** 63))        = $((2 ** 63))  (wraps to the minimum)"
echo "\$((2 ** 63 - 1))    = $((2 ** 63 - 1))  (maximum)"
echo "\$((2 ** 64))        = $((2 ** 64))  (wraps to 0)"

# 10 进制陷阱: 前导 0 表示八进制。
echo "\$((010))            = $((010))  (octal)"
echo "\$((10#08))          = $((10#08))  (forced decimal)"

i=0
# BAD: ((i++)) is 0 when i is 0, so its status is 1 (fatal under set -e).
((i++))
echo "((i++)) with i=0 returned status $? (the value 0 is 'false')"
echo "i is now ${i}"
