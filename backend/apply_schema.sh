#!/usr/bin/env bash
set -e
SCHEMA="/c/data/A-Coding/webdev/ForestWatch/backend/src/db/schema.sql"
echo ">> Applying schema.sql to forestwatch DB..."
docker exec -i forestwatch-db psql -U forestwatch -d forestwatch -v ON_ERROR_STOP=1 < "$SCHEMA"
echo ">> Done. Public-schema tables now:"
docker exec forestwatch-db psql -U forestwatch -d forestwatch -c "\dt public.*"
