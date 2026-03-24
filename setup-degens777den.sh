#!/bin/bash
# Degens777Den Setup Script
# Unified Slots Platform for cloutscape.org

set -e

echo "Starting Degens777Den Setup..."

# 1. Check for Cloudflare Tunnel Credentials
if [ ! -f "cloudflared-credentials.json" ]; then
  echo "Error: cloudflared-credentials.json not found!"
  echo "Please generate credentials with: cloudflared tunnel create degens777den-tunnel"
  exit 1
fi

# 2. Initialize Local SQLite Databases
echo "Initializing Local SQLite Databases..."
touch degens777den-club.sqlite
touch degens777den-spin.sqlite

# 3. Pull the Latest Game Engine Image
echo "Pulling latest slots engine image..."
docker pull schwarzlichtbezirk/slotopol:latest

# 4. Launch the Unified Platform
echo "Launching Degens777Den Unified Platform..."
docker compose -f degens777den-compose.yml up -d

echo "Setup Complete!"
echo "API: api.cloutscape.org (proxied via Cloudflare Tunnel)"
echo "Frontend: cloutscape.org (proxied via Cloudflare Tunnel)"
echo "Local DB: degens777den-club.sqlite"
echo "Degens777Den is now active!"
