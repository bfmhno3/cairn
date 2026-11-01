# shellcheck shell=bash
# Shows: a named pipe (mkfifo) is a pipe with a name. Opening it blocks
# until both a reader and a writer are there; no data is stored on disk.
fifo="${LAB_TMP}/pipe"
mkfifo "${fifo}" || exit 1
echo "file type character: $(stat -c %F "${fifo}")"

echo '--- a writer in the background, a reader in the foreground ---'
{
  echo 'line one'
  echo 'line two'
} >"${fifo}" &
writer=$!
cat <"${fifo}"
wait "${writer}"
echo "writer status: $?"

echo '--- the open() of the writer blocks until a reader shows up ---'
echo late >"${fifo}" &
writer=$!
sleep 0.5
if kill -0 "${writer}" 2>/dev/null; then
  echo 'writer is still blocked after 0.5 s, nobody reads yet'
fi
cat <"${fifo}"
wait "${writer}"

echo '--- the fifo itself stays empty on disk ---'
echo "size: $(stat -c %s "${fifo}") bytes"

echo '--- a fifo between two commands, like a pipe with a name ---'
printf 'c\na\nb\n' >"${fifo}" &
sort <"${fifo}"
wait
rm -f "${fifo}"
