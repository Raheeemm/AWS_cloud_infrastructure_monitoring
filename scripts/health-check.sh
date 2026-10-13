#!/bin/bash

set -u

echo "================================"
echo " AWS Infrastructure Health Check"
echo "================================"

FAILED=0

echo
echo "[1/2] Checking Nginx service..."

if systemctl is-active --quiet nginx; then
    echo "[PASS] Nginx service is running."
else
    echo "[FAIL] Nginx service is not running."
    FAILED=1
fi

echo
echo "[2/2] Checking local HTTP endpoint..."

if curl -fsS --max-time 5 http://localhost/ -o /dev/null; then
    echo "[PASS] HTTP endpoint is responding."
else
    echo "[FAIL] HTTP endpoint is not responding."
    FAILED=1
fi

echo

if [ "$FAILED" -eq 0 ]; then
    echo "[SUCCESS] All health checks passed."
    exit 0
else
    echo "[FAILURE] One or more health checks failed."
    exit 1
fi