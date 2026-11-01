# shellcheck shell=bash
# Shows: for-in, C-style for, while, until, break 2 and continue.
echo '--- for in ---'
for word in alpha 'two words' gamma; do
  echo "[${word}]"
done

echo '--- C-style for ---'
for ((i = 0; i < 3; i++)); do
  echo "i=${i}"
done

echo '--- while ---'
n=3
while ((n > 0)); do
  echo "n=${n}"
  n=$((n - 1))
done

echo '--- until ---'
n=0
until ((n >= 3)); do
  echo "n=${n}"
  ((n += 1))
done

echo '--- continue ---'
for ((i = 1; i <= 5; i++)); do
  if ((i % 2 == 0)); then
    continue
  fi
  echo "odd ${i}"
done

echo '--- break 2 ---'
for a in 1 2 3; do
  for b in 1 2 3; do
    if ((a * b == 4)); then
      echo "found a=${a} b=${b}, leaving both loops"
      break 2
    fi
    echo "a=${a} b=${b}"
  done
done
