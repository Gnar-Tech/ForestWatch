#!/usr/bin/env bash
BASE="http://localhost:4000"
echo "=== GET /health ==="
curl -s "$BASE/health"; echo
echo "=== POST /api/dump-sites (multipart, no photo) ==="
curl -s -F "title=Test pile by trailhead" \
        -F "description=Bags of household trash" \
        -F "category=household" \
        -F "severity=high" \
        -F "latitude=45.5231" \
        -F "longitude=-122.6765" \
        -F "reporterName=SmokeTest" \
        -F "clientId=smoke-001" \
        "$BASE/api/dump-sites"; echo
echo "=== POST again with same clientId (idempotency check) ==="
curl -s -F "title=dup" -F "latitude=45.5231" -F "longitude=-122.6765" -F "clientId=smoke-001" "$BASE/api/dump-sites"; echo
echo "=== GET /api/dump-sites ==="
curl -s "$BASE/api/dump-sites"; echo
echo "=== POST /api/auth/register ==="
curl -s -H "Content-Type: application/json" \
     -d '{"email":"vol@example.com","name":"Vol Unteer","password":"password123"}' \
     "$BASE/api/auth/register"; echo
