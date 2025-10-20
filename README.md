# Gisia Docker Setup

This repository contains Docker configuration for running Gisia

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Extract Configuration Files

Build and run the init container to extract configuration files:

```bash
docker build -t gisia-init:latest -f Dockerfile.init .
mkdir gisia
cd gisia
docker run --rm -v ./:/output gisia-init:latest
```

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp output/.env.example output/.env
```

Edit `output/.env` with your settings:
```bash
GISIA_HOST="your.domain.com"
GISIA_PORT="8080"
DATABASE_PASSWORD="your-secure-password"
```


### 3. Start Services

```bash
docker compose up -d
```

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

Please refer to the `NOTICE` and `.licenses` folders for detailed information on third-party licenses.

### ⚠️ Third-Party References Disclaimer

You may notice references to **"GitLab"** in server responses, logs, or internal messages.
These come from reused **GitLab components (MIT-licensed)** or code segments.

**Gisia is not affiliated with, endorsed by, or associated with GitLab Inc.**
All trademarks and brand names belong to their respective owners.

