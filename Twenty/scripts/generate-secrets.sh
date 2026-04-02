#!/usr/bin/env bash
# generate-secrets.sh
# Copies .env.example → .env and injects randomised secrets.
# Run once before first deployment:  bash scripts/generate-secrets.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [[ -f .env ]]; then
  echo "WARNING: .env already exists. Overwriting will invalidate existing data!"
  read -r -p "Continue and overwrite? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

cp .env.example .env

# Detect Unraid/host IP (first non-loopback address)
UNRAID_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [[ -z "$UNRAID_IP" ]]; then
  echo "WARNING: Could not detect host IP. Set SERVER_URL manually in .env"
  UNRAID_IP="YOUR_SERVER_IP"
fi

# Generate secrets (hex avoids base64 special chars that break PG connection strings)
APP_SECRET=$(openssl rand -base64 32)
PG_PASS=$(openssl rand -hex 24)

sed -i "s|UNRAID_IP|${UNRAID_IP}|g"                        .env
sed -i "s|replace_with_strong_password|${PG_PASS}|g"       .env
sed -i "s|replace_with_random_secret|${APP_SECRET}|g"      .env

# Create storage dirs with correct ownership for container UID 1000 (app user)
mkdir -p storage/{db-data,server-data,redis-data}
chown -R 1000:1000 storage/server-data

echo ""
echo "Done! .env generated with:"
echo "  SERVER_URL  = http://${UNRAID_IP}:$(grep '^TWENTY_PORT' .env | cut -d= -f2)"
echo "  APP_SECRET  = (set)"
echo "  PG_PASS     = (set)"
echo ""
echo "Review .env before starting containers:"
echo "  grep -v '^#' .env | grep -v '^$'"
