#!/usr/bin/env bash
# =============================================================
# deploy.sh (EC2 self-run version)
# Automates setup, deployment, and configuration
# of a Dockerized application *on the same EC2 instance*.
# =============================================================
set -euo pipefail

# --- Logging ---
LOGFILE="deploy_$(date +%Y%m%d_%H%M%S).log"
exec 3>&1
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE" >&3; }

trap 'log "❌ Error on line $LINENO. Exiting."; exit 1' ERR
trap 'log "🔚 Script finished at $(date)";' EXIT

# --- Inputs ---
read -p "Enter Git repository URL (https): " REPO_URL
read -s -p "Enter GitHub Personal Access Token (PAT) (press Enter if repo is public): " PAT
echo
read -p "Enter branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}
read -p "Enter internal app port (container port, default 8080): " APP_PORT
APP_PORT=${APP_PORT:-8080}

REPO_NAME=$(basename -s .git "$REPO_URL")
APP_DIR="$HOME/$REPO_NAME"

log "🔰 Starting deployment of $REPO_NAME"
log "Repo: $REPO_URL"
log "Branch: $BRANCH"
log "App port: $APP_PORT"
log "Install log: $LOGFILE"

# --- Update system and install dependencies ---
log "⚙️ Installing Docker, Compose, and Nginx if missing..."
sudo apt-get update -y
sudo apt-get install -y curl git docker.io nginx

# Ensure docker is running
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER" || true

# Install docker-compose plugin if missing
if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get install -y docker-compose-plugin
fi

# --- Clone or update repo ---
if [[ -d "$APP_DIR" ]]; then
  log "🔄 Repo exists. Pulling latest changes."
  cd "$APP_DIR"
  git fetch --all
  git checkout "$BRANCH" || git checkout -b "$BRANCH" origin/"$BRANCH" || true
  git pull origin "$BRANCH" || true
else
  log "📥 Cloning repo..."
  if [[ -n "$PAT" ]]; then
    CLONE_URL=$(echo "$REPO_URL" | sed -E "s#https://##")
    git clone -b "$BRANCH" "https://${PAT}@${CLONE_URL}" "$APP_DIR"
  else
    git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
  fi
fi

cd "$APP_DIR"
log "✅ Repository ready at $APP_DIR"

# --- Build and deploy docker containers ---
if [[ -f docker-compose.yml ]]; then
  log "🐳 Using docker-compose to deploy..."
  sudo docker compose down --remove-orphans || true
  sudo docker compose build --no-cache
  sudo docker compose up -d
elif [[ -f Dockerfile ]]; then
  log "🐳 No docker-compose.yml found. Building from Dockerfile..."
  sudo docker build -t "$REPO_NAME" .
  sudo docker run -d -p 80:"$APP_PORT" "$REPO_NAME"
else
  log "❌ No Dockerfile or docker-compose.yml found. Aborting."
  exit 1
fi

# --- Configure Nginx reverse proxy ---
log "🔧 Configuring Nginx..."
NGINX_CONF="/etc/nginx/sites-available/$REPO_NAME.conf"
sudo tee "$NGINX_CONF" >/dev/null <<EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
log "✅ Nginx configured and reloaded."

# --- Validate deployment ---
log "🔎 Validating service..."
sleep 5
if curl -sf http://127.0.0.1 >/dev/null 2>&1; then
  log "✅ Application reachable locally."
else
  log "⚠️ Local validation failed. Check container logs."
fi

log "🎉 Deployment complete! Visit: http://$(curl -s ifconfig.me)"
