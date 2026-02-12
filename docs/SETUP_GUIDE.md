This is a great idea. As a project grows, having a "Source of Truth" document prevents configuration drift and helps onboard new developers (or your future self) in minutes.

I have structured this as a **Master Setup Guide**. You can save this as `docs/SETUP_GUIDE.md` or append it to your `README.md`.

---

# 📖 Teleswitch Platform: Master Setup Guide

This document provides a step-by-step walkthrough of the platform setup, from folder structure to CI/CD integration.

---

## 📂 Phase 1: Folder Structure

A clean structure is vital for Docker volume mounting and CI scanning.

```text
teleswitch-platform/
├── .github/workflows/    # CI/CD Pipeline (GitHub Actions)
├── kamailio/             # Kamailio SIP Proxy
│   ├── kamailio.cfg      # SIP Routing Logic
│   ├── db_init/          # SQL scripts for MariaDB (Dispatcher, Alias, etc.)
│   └── Dockerfile        # Custom Kamailio image
├── teleswitch/           # FreeSWITCH Media Server
│   ├── config/           # XML configs (dialplan, directory)
│   └── Dockerfile
├── teleplivo/            # API Layer
│   └── Dockerfile
├── .pre-commit-config.yaml # Local code quality gate
├── docker-compose.yml    # Orchestration
└── .env                  # Environment variables (Global)

```

---

## 🛠 Phase 2: Configuration Step-by-Step

### Step 1: The Database Initialization (`kamailio/db_init/init.sql`)

This script runs **only the first time** the container starts. It sets up the Dispatcher table so Kamailio knows where the FreeSWITCH (Teleswitch) nodes are.

* **Key Logic**: Ensure the `destination` matches the service name in `docker-compose.yml`.

### Step 2: Orchestration (`docker-compose.yml`)

This file connects the dots.

* **Healthchecks**: We use `mysqladmin` for the DB and `fs_cli` for Teleswitch.
* **Dependencies**: `kamailio` must wait for `kamailio-db` to be healthy, or the SIP engine will crash on startup while trying to connect to MySQL.

### Step 3: Local Quality Control (`.pre-commit-config.yaml`)

Before code reaches GitHub, we catch errors locally.

* **Kamailio Check**: We pull a temporary Docker image to run `kamailio -c`. If you have a missing semicolon in your SIP config, the commit will fail.
* **YAML Check**: Prevents the "indentation" errors we fixed earlier.

---

## 🤖 Phase 3: The CI/CD Pipeline (`ci.yml`)

The pipeline follows a "Fail Fast" philosophy:

1. **Build Matrix**: We build `teleswitch`, `teleplivo`, and `kamailio` in parallel to save time.
2. **Tagging Strategy**:
* `sha-xxxx`: Used for internal integration testing.
* `latest`: Only applied when code is merged into `main`.


3. **Integration Health**: The runner starts the **entire stack** and checks health. If the Kamailio DB fails to initialize, the `integration-test` job turns RED.

---

## 📋 Phase 4: Maintenance Checklist

| Task | Command / File | Frequency |
| --- | --- | --- |
| **Add new FS Node** | Update `kamailio/db_init/init.sql` | When scaling |
| **Update SIP Logic** | `kamailio/kamailio.cfg` | As features change |
| **Update Hooks** | `pre-commit autoupdate` | Monthly |
| **Clean Database** | `docker volume rm kamailio_db_data` | For fresh dev setups |

---

## 🛡 Future Roadmap (To be added)

As the project grows, we will add:

* **TLS/WSS Setup**: Documentation for SSL certificates in Kamailio.
* **Monitoring**: Integration with Prometheus and Grafana for SIP statistics.
* **Failover**: Setting up a secondary Kamailio node for High Availability.

---

### How to use this moving forward:

I recommend creating a `docs/` folder in your repo:

1. `mkdir docs`
2. `touch docs/SETUP_GUIDE.md`
3. Paste the content above into that file.

**Would you like me to help you write the specific "How-To" section for adding a new FreeSWITCH node to the Kamailio Dispatcher list?**
