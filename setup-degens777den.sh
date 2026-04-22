#!/bin/bash
# ==============================================================================
# setup-degens777den.sh
# Clutch Engine Setup Script for Degens777Den / cloutscape.org
# 
# This script builds and starts the Clutch engine with the degens777den.yaml
# configuration, ensuring it listens on port 8081 for Kodakclout integration.
# Replaces the previous Docker-based setup with a native PM2 deployment.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log "Setting up Clutch engine for Degens777Den..."

# 1. Ensure Go is installed
if ! command -v go &> /dev/null; then
    error "Go is not installed. Please install Go >= 1.20"
fi

# 2. Ensure config exists
if [ ! -f degens777den.yaml ]; then
    error "degens777den.yaml not found in $SCRIPT_DIR"
fi

# 3. Ensure port-http is set to 8081
sed -i 's/port-http:.*/port-http: ":8081"/g' degens777den.yaml
log "Ensured port-http is set to :8081 in degens777den.yaml"

# 4. Initialize SQLite databases if they don't exist
touch degens777den-club.sqlite
touch degens777den-spin.sqlite
chmod 664 degens777den-club.sqlite degens777den-spin.sqlite
log "SQLite databases initialized."

# 5. Build the binary if it doesn't exist or is outdated
if [ ! -f clutch-server ]; then
    log "Building Clutch server binary..."
    go mod download
    go build -o clutch-server main.go
    log "Build complete."
else
    log "clutch-server binary already exists. Skipping build."
fi

# 6. Stop any existing PM2 process
pm2 delete clutch-engine 2>/dev/null || true

# 7. Start Clutch engine with PM2
log "Starting Clutch engine with PM2..."
pm2 start ./clutch-server --name clutch-engine -- web -c degens777den.yaml

# 8. Wait for engine to be ready
log "Waiting for Clutch engine to start..."
sleep 5
for i in {1..6}; do
    if curl -s http://localhost:8081/ping >/dev/null; then
        log "Clutch engine is responding on port 8081."
        break
    fi
    if [ $i -eq 6 ]; then
        error "Clutch engine failed to start or respond on port 8081."
    fi
    warn "Waiting for Clutch engine... attempt $i/6"
    sleep 5
done

# 9. Verify game list is available
GAME_COUNT=$(curl -s "http://localhost:8081/game/list?inc=all" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('list', [])))" 2>/dev/null || echo "0")
log "Clutch engine is serving $GAME_COUNT games."

pm2 save

echo "=============================================================================="
echo -e "${GREEN}Clutch engine setup complete!${NC}"
echo "=============================================================================="
echo " - Engine URL:    http://localhost:8081"
echo " - Ping:          http://localhost:8081/ping"
echo " - Game List:     http://localhost:8081/game/list?inc=all"
echo " - PM2 Process:   clutch-engine"
echo " - Games served:  $GAME_COUNT"
echo "=============================================================================="
