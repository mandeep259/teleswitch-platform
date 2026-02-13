#!/bin/bash
set -e

echo "=== Preparing RTPengine Configuration ==="

TEMPLATE="/etc/rtpengine/rtpengine.conf.template"
CONFIG="/etc/rtpengine/rtpengine.conf"

# Copy template to active config
cp "$TEMPLATE" "$CONFIG"

# Replace the variable
if [ -n "$EXTERNAL_SIP_IP" ]; then
    echo "Injecting External IP: $EXTERNAL_SIP_IP"
    sed -i "s/\$EXTERNAL_SIP_IP/$EXTERNAL_SIP_IP/g" "$CONFIG"
else
    echo "Using default 127.0.0.1"
    sed -i "s/\$EXTERNAL_SIP_IP/127.0.0.1/g" "$CONFIG"
fi

echo "=== Starting RTPengine ==="
exec rtpengine -f --config-file="$CONFIG"
