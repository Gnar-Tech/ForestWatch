#!/usr/bin/env bash
echo "=== node / npm ==="
node --version 2>&1
npm --version 2>&1
echo "=== docker ==="
docker --version 2>&1 || echo "DOCKER NOT FOUND"
docker compose version 2>&1 || echo "DOCKER COMPOSE NOT FOUND"
echo "=== docker daemon running? ==="
docker info --format '{{.ServerVersion}}' 2>&1 | head -n 3 || echo "DAEMON NOT RUNNING"
echo "=== local psql? ==="
psql --version 2>&1 || echo "no psql on PATH"
echo "=== backend node_modules present? ==="
ls -d /c/data/A-Coding/webdev/ForestWatch/backend/node_modules 2>&1 || echo "NOT INSTALLED"
echo "=== backend .env present? ==="
ls /c/data/A-Coding/webdev/ForestWatch/backend/.env 2>&1 || echo "NO .env"
echo "=== ports 4000 / 5432 in use? ==="
netstat -ano | grep -E ':4000|:5432' | head -n 10 || echo "neither in use"
