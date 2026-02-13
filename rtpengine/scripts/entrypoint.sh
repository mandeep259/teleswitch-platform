#!/bin/bash
set -e

echo "=== Preparing RTPengine Configuration ==="

# Replace the variable string $EXTERNAL_SIP_IP with the actual env value in the config file
# We use a temporary file to avoid stream issues
if [ -n "$EXTERNAL_SIP_IP" ]; then
    echo "Setting External IP to: $EXTERNAL_SIP_IP"
    sed -i "s/\$EXTERNAL_SIP_IP/$EXTERNAL_SIP_IP/g" /etc/rtpengine/rtpengine.conf
else
    echo "WARNING: EXTERNAL_SIP_IP not set, defaulting to 127.0.0.1"
    sed -i "s/\$EXTERNAL_SIP_IP/127.0.0.1/g" /etc/rtpengine/rtpengine.conf
fi

echo "=== Starting RTPengine ==="
# -f keeps it in the foreground so Docker can manage the process
exec rtpengine -f --config-file=/etc/rtpengine/rtpengine.conf
