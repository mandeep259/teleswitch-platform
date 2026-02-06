# Teleswitch Platform

A high-performance VoIP switching platform powered by **Kamailio** and **FreeSWITCH**.

## Features
* **Kamailio SIP Proxy:** Core routing and load balancing.
* **Security:** Integrated CI/CD quality gates for configuration validation.
* **Dockerized:** Fully containerized setup for easy deployment.

## CI/CD Pipeline
This repository uses a **Pre-commit Quality Gate**. Every push to `main` is validated for:
* YAML/Shell script syntax.
* Secrets/Private key detection.
* Formatting (Trailing whitespace & End-of-file).

## Getting Started
1. Install pre-commit: `pip install pre-commit`
2. Initialize hooks: `pre-commit install`
3. Run locally: `docker-compose up -d`
