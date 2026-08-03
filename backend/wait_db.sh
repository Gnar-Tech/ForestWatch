#!/usr/bin/env bash
echo ">> Waiting for Postgres to be ready..."
for i in $(seq 1 30); do
  if docker exec forestwatch-db pg_isready -U forestwatch -d forestwatch >/dev/null 2>&1; then
    echo ">> Postgres is ready (attempt $i)."
    exit 0
  fi
  sleep 2
done
echo ">> Postgres did NOT become ready in time." >&2
exit 1
