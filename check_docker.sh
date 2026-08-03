#!/usr/bin/env bash
echo "=== docker ps ==="
docker ps 2>&1
echo "=== exit: $? ==="
