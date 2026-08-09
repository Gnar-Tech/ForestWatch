#!/usr/bin/env bash
set -euo pipefail

# ForestWatch Backend Deploy Script
# Run as root on the VPS after vps-setup.sh
# Usage: bash vps-deploy.sh

APP_DIR="/opt/forestwatch"
REPO_URL="https://github.com/Gnar-Tech/ForestWatch.git"

echo "=== ForestWatch Backend Deploy ==="

# 1. Clone or pull the repo
echo "[1/6] Fetching latest code..."
if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR"
  git pull
else
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

# 2. Start PostgreSQL with Docker
echo "[2/6] Starting PostgreSQL/PostGIS via Docker..."
cd "$APP_DIR/backend"
if command -v docker &>/dev/null; then
  docker compose up -d
  echo "Waiting for PostgreSQL to be ready..."
  sleep 10
else
  echo "ERROR: Docker not found. Install Docker first."
  exit 1
fi

# 3. Install dependencies and build
echo "[3/6] Installing dependencies and building..."
npm install
npm run build

# 4. Create .env if it doesn't exist
echo "[4/6] Checking .env..."
if [ ! -f "$APP_DIR/backend/.env" ]; then
  # Get the Docker container's IP for the DB connection
  DB_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} forestwatch-db 2>/dev/null || echo "localhost")
  
  # Generate a random JWT secret
  JWT_SECRET=$(openssl rand -hex 32)
  
  # Get server public IP
  PUBLIC_IP=$(curl -s ifconfig.me || echo "localhost")
  
  cat > "$APP_DIR/backend/.env" << EOF
PORT=4000
DATABASE_URL=postgres://forestwatch:forestwatch@${DB_HOST}:5432/forestwatch
JWT_SECRET=${JWT_SECRET}
PUBLIC_URL=http://${PUBLIC_IP}
CORS_ORIGINS=*
EOF
  echo "Created .env with DB_HOST=$DB_HOST, PUBLIC_URL=http://$PUBLIC_IP"
else
  echo ".env already exists, keeping current config."
fi

# 5. Run migrations
echo "[5/6] Running database migrations..."
npm run migrate

# 6. Restart PM2 process
echo "[6/6] Restarting backend with PM2..."
pm2 delete forestwatch-api 2>/dev/null || true
pm2 start dist/index.js --name forestwatch-api
pm2 save

echo ""
echo "=== Deploy complete! ==="
echo "Backend running on port 4000"
echo "Health check: curl http://localhost:4000/health"
echo ""
echo "PM2 status:"
pm2 status
