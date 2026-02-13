Here is the updated, comprehensive guide for your **RTPengine** setup. This version includes the **Template Logic** we implemented to ensure the setup is "rebuild-proof" and doesn't overwrite your host files with hardcoded data.

---

# 🛠️ RTPengine Configuration Guide: Docker Environment

This guide details how to handle **Dynamic Configuration Injection** for RTPengine using a template system. This prevents "Invalid Interface" errors caused by environment variables not being natively supported in `.conf` files.

---

## 1. Directory Structure

Ensure your project folder is organized as follows:

```text
rtpengine/
├── config/
│   └── rtpengine.conf.template  <-- Source of truth
├── scripts/
│   └── entrypoint.sh            <-- Startup logic
└── Dockerfile                   <-- Optimized build

```

---

## 2. Implementation Files

### A. The Template File (`rtpengine/config/rtpengine.conf.template`)

Use the `$EXTERNAL_SIP_IP` placeholder. This file remains untouched by the script.

```ini
[rtpengine]
interface = eth0!$EXTERNAL_SIP_IP
listen-ng = 0.0.0.0:22222
port-min = 30000
port-max = 40000
log-level = 5
log-stderr = true

```

### B. The Entrypoint Script (`rtpengine/scripts/entrypoint.sh`)

This script creates a fresh config from the template on every boot.

```bash
#!/bin/bash
set -e

echo "=== Preparing RTPengine Configuration ==="

TEMPLATE="/etc/rtpengine/rtpengine.conf.template"
CONFIG="/etc/rtpengine/rtpengine.conf"

# Copy template to active config location inside the container
cp "$TEMPLATE" "$CONFIG"

# Inject the environment variable into the active config
if [ -n "$EXTERNAL_SIP_IP" ]; then
    echo "Injecting External IP: $EXTERNAL_SIP_IP"
    sed -i "s/\$EXTERNAL_SIP_IP/$EXTERNAL_SIP_IP/g" "$CONFIG"
else
    echo "Using default 127.0.0.1"
    sed -i "s/\$EXTERNAL_SIP_IP/127.0.0.1/g" "$CONFIG"
fi

echo "=== Starting RTPengine ==="
exec rtpengine -f --config-file="$CONFIG"

```

> **Note:** Run `chmod +x rtpengine/scripts/entrypoint.sh` and `sed -i 's/\r$//' rtpengine/scripts/entrypoint.sh` to ensure Linux compatibility.

### C. The Dockerfile (`rtpengine/Dockerfile`)

Optimized for size using `debian-slim`.

```dockerfile
FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    rtpengine \
    iproute2 \
    iptables \
    net-tools \
    tcpdump \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

```

### D. Docker Compose Service (`docker-compose.yml`)

```yaml
  rtpengine:
    build: ./rtpengine
    container_name: rtpengine
    restart: unless-stopped
    privileged: true
    cap_add:
      - NET_ADMIN
    environment:
      - EXTERNAL_SIP_IP=${EXTERNAL_SIP_IP:-127.0.0.1}
    ports:
      - "22222:22222/udp"
      - "30000-30005:30000-30005/udp"
    volumes:
      - ./rtpengine/config/rtpengine.conf.template:/etc/rtpengine/rtpengine.conf.template
      - ./rtpengine/scripts:/usr/local/bin
    networks:
      - sip_network

```

---

## 3. Deployment & Verification

| Step | Command |
| --- | --- |
| **1. Build Image** | `docker compose build rtpengine` |
| **2. Start Service** | `docker compose up -d rtpengine` |
| **3. Check Logs** | `docker compose logs rtpengine` |
| **4. Verify IP Injection** | `docker exec rtpengine cat /etc/rtpengine/rtpengine.conf` |

---

## 4. Key Takeaways for Future Reference

* **Template vs Config:** Never mount the active `.conf` file directly if using `sed`. Use a `.template` file to keep the source clean.
* **Line Endings:** If you see `exec format error`, always run `sed -i 's/\r$//' script.sh` to fix Windows/DOS formatting.
* **Port Mapping:** The `ports:` range in `docker-compose.yml` must be opened to allow media flow. For production, expand `30000-30005` to a larger range (e.g., `30000-40000`).
* **Privileged Mode:** Required for RTPengine to manage network interfaces and iptables correctly.

---

**Now that this is documented, should we look into why Kamailio is still reporting as "unhealthy"?**
