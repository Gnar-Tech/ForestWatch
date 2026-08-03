#!/usr/bin/env bash
echo "=== tables ==="
docker exec forestwatch-db psql -U forestwatch -d forestwatch -c "\dt" 2>&1
echo "=== postgis version ==="
docker exec forestwatch-db psql -U forestwatch -d forestwatch -tAc "SELECT postgis_version();" 2>&1
echo "=== dump_sites columns ==="
docker exec forestwatch-db psql -U forestwatch -d forestwatch -c "\d dump_sites" 2>&1
