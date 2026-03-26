#!/bin/bash
# Degens777Den Guaranteed Deployment Script
# Ensures the engine and tunnel are configured, launched, and verified.

set -e

# Configuration
PROJECT_NAME="degens777den"
COMPOSE_FILE="degens777den-compose.yml"
CREDENTIALS_FILE="cloudflared-credentials.json"
CONFIG_FILE="cloudflared-config.yaml"
APP_CONFIG="degens777den.yaml"
TIMEOUT=60

echo "🚀 Starting Guaranteed Deployment for $PROJECT_NAME..."

# 1. Validation
echo "🔍 Validating configuration..."
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "❌ ERROR: $CREDENTIALS_FILE missing!"
    echo "   Please run: cloudflared tunnel create degens777den-tunnel"
    echo "   And copy the generated JSON file here as $CREDENTIALS_FILE"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: $CONFIG_FILE missing!"
    exit 1
fi

# 2. Database Initialization
echo "🗄️  Initializing SQLite databases..."
touch degens777den-club.sqlite
touch degens777den-spin.sqlite
chmod 666 *.sqlite

# 3. Environment Preparation
echo "🐳 Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

# 4. Deployment
echo "🏗️  Launching containers..."
docker compose -f "$COMPOSE_FILE" up -d --force-recreate

# 5. Health Verification
echo "🩺 Verifying deployment health..."
SECONDS=0
while [ $SECONDS -lt $TIMEOUT ]; do
    ENGINE_STATUS=$(docker inspect --format='{{.State.Health.Status}}' degens777den-srv 2>/dev/null || echo "starting")
    TUNNEL_STATUS=$(docker inspect --format='{{.State.Health.Status}}' degens777den-tunnel 2>/dev/null || echo "starting")
    
    echo "   - Engine: $ENGINE_STATUS"
    echo "   - Tunnel: $TUNNEL_STATUS"
    
    if [ "$ENGINE_STATUS" == "healthy" ] && [ "$TUNNEL_STATUS" == "healthy" ]; then
        echo "✅ All services are healthy!"
        break
    fi
    
    if [ $SECONDS -ge $TIMEOUT ]; then
        echo "❌ ERROR: Deployment timed out after ${TIMEOUT}s"
        docker compose -f "$COMPOSE_FILE" logs
        exit 1
    fi
    
    sleep 5
done

# 6. Web Page Display Verification (Internal)
echo "🌐 Testing internal web page response..."
RESPONSE=$(docker exec degens777den-srv curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ping)
if [ "$RESPONSE" == "200" ]; then
    echo "✅ Internal web page is displaying correctly (Status 200)"
else
    echo "❌ ERROR: Web page returned status $RESPONSE"
    exit 1
fi

echo "--------------------------------------------------"
echo "🎉 DEPLOYMENT SUCCESSFUL!"
echo "   Site: https://cloutscape.org"
echo "   API:  https://api.cloutscape.org"
echo "--------------------------------------------------"
