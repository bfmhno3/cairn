# shellcheck shell=bash
# Shows: a file without a shebang or exec bit still runs as `bash hello.sh`.
# The runner starts non-executable labs this way.
echo "hello from $0"
