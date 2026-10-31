#!/usr/bin/env bash
# Shows: what an executable script sees about itself. The kernel read the
# shebang, started env, which found bash on PATH.
echo "\$0           = $0"
echo "\$BASH        = ${BASH}"
echo "\$BASH_VERSION = ${BASH_VERSION}"
echo "\$\$           = $$"
echo "\$PPID        = ${PPID}"
