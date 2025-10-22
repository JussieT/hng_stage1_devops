# 🚀 Automated Dockerized App Deployment Script

## Overview
This project contains a **production-grade Bash script (`deploy.sh`)** that automates the setup, deployment, and configuration of a Dockerized Node.js application on a remote Linux (EC2) server.  
It installs dependencies, builds and runs Docker containers, configures **NGINX as a reverse proxy**, validates deployment health, and provides robust logging and cleanup options.

---

## Features
- 🔧 Automatic installation of Docker, Docker Compose, and NGINX  
- 🐳 Builds and runs containers using `docker-compose.yml`  
- 🌐 Configures NGINX to forward HTTP (port 80) traffic to the app’s internal port (8080)  
- 📊 Logs all actions with timestamps  
- 🔁 Idempotent — can safely re-run without breaking existing setups  
- 🧹 Includes `--cleanup` flag to remove deployed resources

---

## Usage
```bash
# Make script executable
chmod +x deploy.sh

# Deploy the application
./deploy.sh

# (Optional) Remove containers, networks, and NGINX configs
./deploy.sh --cleanup
