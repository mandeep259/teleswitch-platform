#!/bin/bash

echo "=== Starting Teleswitch (FreeSWITCH core) ==="
echo "TELE_HOME=/home/teleswitch/teleswitch"

# We do not use 'set -e' here so that if the 'nice' level
# fails (common in CI/locked-down environments), the container doesn't crash.
# FreeSWITCH will still attempt to run with standard priority.

exec /home/teleswitch/teleswitch/usr/bin/freeswitch \
  -nf \
  -conf /home/teleswitch/teleswitch/etc/teleswitch \
  -log /home/teleswitch/teleswitch/var/log/teleswitch \
  -db /var/lib/freeswitch/db
