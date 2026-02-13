#!/bin/bash
set -e

echo "=== Starting RTPengine ==="
echo "Config: /etc/rtpengine/rtpengine.conf"

exec rtpengine -f --config-file=/etc/rtpengine/rtpengine.conf
