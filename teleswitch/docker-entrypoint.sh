#!/bin/bash
set -e

echo "=== Starting Teleswitch (FreeSWITCH core) ==="
echo "TELE_HOME=/home/teleswitch/teleswitch"

exec /home/teleswitch/teleswitch/usr/bin/freeswitch \
  -nf \
  -conf /home/teleswitch/teleswitch/etc/teleswitch \
  -log /home/teleswitch/teleswitch/var/log/teleswitch \
  -db /var/lib/freeswitch/db

