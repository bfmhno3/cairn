# shellcheck shell=bash
# Shows: what /bin/sh is on this machine. On NixOS it is bash (so a script
# with #!/bin/sh quietly gets bash); on Debian and Ubuntu it is dash.
# The output depends on the host, the lab never fails.
echo '$ readlink -f /bin/sh'
readlink -f /bin/sh
echo '$ ls -l /bin/sh'
ls -l /bin/sh
