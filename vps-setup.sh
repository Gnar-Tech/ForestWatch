#!/usr/bin/env bash
set -euo pipefail

# ForestWatch VPS Setup Script
# Run as root on a fresh Debian 12 VPS
# Usage: bash vps-setup.sh

echo "=== ForestWatch VPS Setup ==="

# 1. Update system
echo "[1/7] Updating system packages..."
apt-get update -y
apt-get upgrade -y

# 2. Install Node.js 20 LTS
echo "[2/7] Installing Node.js 20 LTS..."
if ! command -v node &>/dev/null || [[ "$(node -v)" != v20* ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"

# 3. Install PM2 globally
echo "[3/7] Installing PM2..."
npm install -g pm2

# 4. Install Nginx
echo "[4/7] Installing Nginx..."
apt-get install -y nginx

# 5. Install Certbot for Let's Encrypt SSL (optional, needs domain)
echo "[5/7] Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# 6. Configure firewall
echo "[6/7] Configuring firewall (UFW)..."
apt-get install -y ufw
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# 7. Create app directory and user
echo "[7/7] Creating app directory..."
mkdir -p /opt/forestwatch
mkdir -p /opt/forestwatch/uploads

echo ""
echo "=== Setup complete! ==="
echo "Next steps:"
echo "  1. Run: bash vps-deploy.sh"
echo "  2. (Optional) Set up SSL: certbot --nginx -d your-domain.com"
echo ""
echo "PM2 startup config (run once):"
echo "  pm2 startup systemd -u root --env /root"
echo "  pm2 save"
