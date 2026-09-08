# Teleswitch Service — Troubleshooting & Configuration Reference

**Server:** cwpdmedcrbl02 | **Site:** CWC | **Date:** 07 September 2026

---

## 1. Summary

The Teleswitch (FreeSWITCH 1.10.12) service on cwpdmedcrbl02 failed to start due to multiple issues in the startup scripts. This document records the problems found, fixes applied, final script contents, and the startup chain for future reference.

---

## 2. Environment

| Item | Value |
|------|-------|
| Hostname | cwpdmedcrbl02 |
| OS | RHEL / CentOS (systemd-based) |
| Application | Teleswitch (FreeSWITCH 1.10.12-release 64bit) |
| Binary | `/data/sdpuser/development/teleswitch/usr/bin/teleswitch` |
| Config | `/data/sdpuser/development/teleswitch/etc/teleswitch/` |
| Logs | `/data/sdpuser/development/teleswitch/var/log` |
| Run-as User | sdpuser |
| Site Code | CWC |

---

## 3. Issues Identified & Fixes Applied

### 3.1 Relative Path in runTeleswitch.sh

**Problem:** Line 26 used a relative path to the binary:

```
data/sdpuser/development/teleswitch/usr/bin/teleswitch ...
```

The shell couldn't resolve it from any working directory other than `/`, producing "No such file or directory".

**Fix:** Changed to absolute path:

```
/data/sdpuser/development/teleswitch/usr/bin/teleswitch ...
```

### 3.2 Process Dying After `su -c` Exits

**Problem:** When started via `su - sdpuser -c '<command>'`, teleswitch self-daemonised (printed "Backgrounding."), but the parent `su` session ended immediately and the backgrounded child was killed by session cleanup.

**Fix (standalone start):** Wrapped with `nohup`:

```bash
su - sdpuser -c 'nohup /data/sdpuser/development/teleswitch/runTeleswitch.sh 1>/dev/null 2>&1 &'
```

### 3.3 File Ownership Mismatch

**Problem:** Ownership was changed to `teleswitch:root`, but the process runs as `sdpuser`, preventing log/db writes.

**Fix:**

```bash
chown -R sdpuser:sdpuser /data/sdpuser/development/teleswitch/
```

### 3.4 No Auto-Restart on Crash

**Problem:** If teleswitch was killed, nothing restarted it. The existing watchdog script (`startTeleswitch.sh`) was not being called.

**Fix:** Reconnected the startup chain — `startserver.sh` now calls `startTeleswitchint.sh`, which invokes the `Teleswitchservice` wrapper, which runs `startTeleswitch.sh` with its `while(true)` restart loop.

### 3.5 Foreground Mode for Watchdog Compatibility

**Problem:** Teleswitch self-backgrounds by default, causing `su` inside the watchdog loop to return immediately. The loop would think the process died and continuously respawn it.

**Fix:** Added `-nf` (no fork) flag so teleswitch stays in the foreground. The watchdog loop blocks on `su` until teleswitch actually exits, then restarts after a 5-second delay:

```bash
su - sdpuser -c '/data/sdpuser/development/teleswitch/usr/bin/teleswitch -nonat -nf -nc \
  -conf /data/sdpuser/development/teleswitch/etc/teleswitch/ \
  -log /data/sdpuser/development/teleswitch/var/log \
  -db /data/sdpuser/development/teleswitch/var/'
```

---

## 4. Startup Script Chain

```
startserver.sh
  └── startTeleswitchint.sh  (background)
        └── Teleswitchservice start  (background)
              └── startTeleswitch.sh
                    └── while(true) loop
                          ├── check / kill stale processes
                          ├── su - sdpuser -c 'teleswitch -nonat -nf -nc ...'
                          ├── (blocks until teleswitch exits)
                          ├── sleep 5
                          └── restart
```

---

## 5. Key File Locations

| File | Path |
|------|------|
| Master startup | `/usr/local/scripts/startserver.sh` |
| Teleswitch init | `/usr/local/scripts/Freeswitchscripts/startTeleswitchint.sh` |
| Service wrapper | `/usr/local/scripts/Freeswitchscripts/Teleswitchservice` |
| Watchdog loop | `/usr/local/scripts/Freeswitchscripts/startTeleswitch.sh` |
| Run script | `/data/sdpuser/development/teleswitch/runTeleswitch.sh` |
| Binary | `/data/sdpuser/development/teleswitch/usr/bin/teleswitch` |
| Config dir | `/data/sdpuser/development/teleswitch/etc/teleswitch/` |
| Logs | `/data/sdpuser/development/teleswitch/var/log` |
| Service log | `/usr/local/scripts/log/servicelog` |
| Config backup | `/data/sdpuser/development/teleswitch/etc_bak07Sept2026.tgz` |

---

## 6. Final Script Contents

### 6.1 startserver.sh

```bash
#!/bin/sh
if test -z $LD_LIBRARY_PATH ; then
. /etc/profile
. /root/.bash_profile
fi
/usr/local/scripts/Freeswitchscripts/startTeleswitchint.sh 1>/dev/null 2>&1 &
sleep 2
/usr/local/scripts/TelePlivo/startTelePlivoint.sh 1>/dev/null 2>&1 &
sleep 2
su - sdpuser -c /data/sdpuser/apache-tomcat-8.5.66_XML/bin/startup.sh
sleep 2
su - sdpuser -c /data/sdpuser/apache-tomcat-8.5.66_IVR/bin/startup.sh
```

### 6.2 startTeleswitchint.sh

```bash
#!/bin/sh
cd /usr/local/scripts/Freeswitchscripts/
./Teleswitchservice start &
```

### 6.3 startTeleswitch.sh (watchdog — key section)

```bash
while (true)
do
  echo "starting telemune Freeswitch service at  $(date)"
  echo "starting telemune Freeswitch service at  $(date)" >> /usr/local/scripts/log/servicelog

  pgrep -f "/data/sdpuser/development/teleswitch/usr/bin/teleswitch" >/dev/null
  if [ $? -ne 0 ] ; then
    echo "Freeswitch service not running"
  else
    # ... stop stale process ...
  fi

  echo "starting the Freeswitch service"
  sleep 2

  su - sdpuser -c '/data/sdpuser/development/teleswitch/usr/bin/teleswitch \
    -nonat -nf -nc \
    -conf /data/sdpuser/development/teleswitch/etc/teleswitch/ \
    -log /data/sdpuser/development/teleswitch/var/log \
    -db /data/sdpuser/development/teleswitch/var/'

  echo "Freeswitch service stopped"
  sleep 5
  echo "automated restart in progress"
done
```

---

## 7. Verification

- Started teleswitch via the watchdog chain — process came up as `sdpuser` (confirmed via `ps -ef`)
- FreeSWITCH 1.10.12 logged successful startup: Max Sessions 1000, SQL Enabled
- Killed the teleswitch process — watchdog detected the exit and auto-restarted within ~10 seconds
- Checked `/usr/local/scripts/log/servicelog` for restart log entries

---

## 8. Useful Commands

```bash
# Check if teleswitch is running
ps -ef | grep teleswitch

# View teleswitch logs
tail -f /data/sdpuser/development/teleswitch/var/log/teleswitch.log

# View watchdog restart log
tail -f /usr/local/scripts/log/servicelog

# Manual start (as root)
/usr/local/scripts/Freeswitchscripts/startTeleswitchint.sh 1>/dev/null 2>&1 &

# Manual stop
kill $(pgrep -f "/data/sdpuser/development/teleswitch/usr/bin/teleswitch")
# Note: watchdog will restart it automatically — kill the watchdog loop first if you want it to stay down

# Stop watchdog + teleswitch
pkill -f startTeleswitch.sh
kill $(pgrep -f "/data/sdpuser/development/teleswitch/usr/bin/teleswitch")
```

---

## 9. Notes & Recommendations

- Consider creating a **systemd unit** (`teleswitch.service`) for cleaner lifecycle management, boot integration, and journald logging.
- The `ulimit -n 65536` in `runTeleswitch.sh` fails for non-root users unless `/etc/security/limits.conf` grants `sdpuser` the nofile limit — verify this is configured.
- The `etc_bak07Sept2026.tgz` backup was taken before changes — retain for rollback.
- Two stray zero-byte files exist in `Freeswitchscripts/` (`]` and `10.234.3.69`) — safe to remove.
