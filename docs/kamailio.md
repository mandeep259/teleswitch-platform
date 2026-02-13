This is a great idea. Having a "post-mortem" and a configuration guide will save you hours of troubleshooting down the road. Here is the compiled documentation of our session.

---

# ## Deployment Reference: Teleswitch Platform on Docker

### ### 1. Executive Summary

The deployment involved a multi-container SIP stack (Kamailio, Teleswitch/FreeSWITCH, MariaDB, and Teleplivo). We successfully moved the environment from a "failed to start" state to a "healthy" state by resolving port conflicts, fixing healthcheck dependencies, and diagnosing SIP-layer communication gaps.

---

### ### 2. The Troubleshooting Journey (Where we got stuck)

| Obstacle | Symptom | Resolution |
| --- | --- | --- |
| **Port Conflict** | `Bind for 0.0.0.0:5060 failed: port is already allocated` | Separated Host ports. Kamailio kept **5060**, Teleswitch moved to **5070** on the host. Internal Docker ports remained **5060**. |
| **Missing Dependencies** | `nc: executable file not found` in healthcheck logs. | The AlmaLinux image lacked `netcat`. We switched the healthcheck to use the native `healthcheck.sh` script (using `fs_cli`). |
| **Dependency Failure** | `container teleswitch is unhealthy` | Increased `start_period` to 40s and updated the `test` command in `docker-compose.yml` to trigger the internal script. |
| **SIP Inactivity** | Kamailio Dispatcher showed `FLAGS: IP` (Inactive/Probing). | Discovered via `tcpdump` and `sofia status` that Teleswitch was only listening on **IPv6 (::1)** while Kamailio was sending on **IPv4**. |

---

### ### 3. Final Optimized Configuration Structure

#### #### A. `docker-compose.yml` (Key Sections)

```yaml
services:
  teleswitch:
    # ... image info ...
    ports:
      - "5070:5060/udp" # Host port 5070 to avoid conflict with Kamailio
      - "5070:5060/tcp"
    environment:
      - EXTERNAL_SIP_IP=0.0.0.0 # Force IPv4 binding
      - EXTERNAL_RTP_IP=0.0.0.0
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 40s

  kamailio:
    # ... image info ...
    ports:
      - "5060:5060/udp" # Public SIP entry point
      - "5060:5060/tcp"
    # Ensure the directory for the unix socket exists
    entrypoint: /bin/sh -c "mkdir -p /var/run/kamailio && chown kamailio:kamailio /var/run/kamailio && exec kamailio -DD -E -f /etc/kamailio/kamailio.cfg"

```

#### #### B. `kamailio.cfg` (Dispatcher Correction)

To ensure the "Ping" looks valid to the backend:

```kamailio
modparam("dispatcher", "ds_ping_from", "sip:kamailio@kamailio")

```

---

### ### 4. Useful Diagnostic Commands

Keep these handy for future monitoring:

* **Check Platform Health:**
`docker compose ps`
* **Check SIP Dispatcher Status:**
`docker exec kamailio kamcmd -s tcp:127.0.0.1:8000 dispatcher.list`
* **Verify Teleswitch SIP Listeners:**
`docker exec teleswitch fs_cli -x "sofia status"`
* **Live SIP Packet Capture:**
`docker exec kamailio tcpdump -ni any port 5060 -vv`
* **Inspect Healthcheck Logs:**
`docker inspect --format='{{json .State.Health}}' teleswitch`

---

### ### 5. Next Steps for Optimization

As we proceed, we should look into:

1. **SIP Profiles:** Modifying the `internal.xml` in Teleswitch to ensure it explicitly uses `$${local_ip_v4}` for both SIP and RTP.
2. **Persistence:** Ensuring the MariaDB data and Teleswitch recordings folders are correctly mounted to persistent volumes.

**Would you like me to help you draft the specific XML changes for the Teleswitch SIP profiles to lock them into IPv4?**
# This should now return your FreeSWITCH IP from the DB
docker exec -it kamailio kamcmd dispatcher.list

# This should show the status of the rtpengine connection
docker exec -it kamailio kamcmd rtpengine.show all
