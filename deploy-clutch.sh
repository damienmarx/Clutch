#!/bin/bash

# Clutch Deployment Script
# Developed for damienmarx
# This script automates the deployment of the Clutch slots games server.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Clutch Deployment...${NC}"

# 1. Check for Go and dependencies
echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ Go is not installed. Please install Go >= 1.20${NC}"
    exit 1
fi

# 2. Build the server
echo -e "${YELLOW}🏗️ Building the Clutch server for Linux...${NC}"
go mod download && go mod verify
sudo chmod +x ./task/*.sh
./task/build-linux-x64.sh

# 3. Setup Deployment Directory
DEPLOY_DIR="/opt/clutch"
echo -e "${YELLOW}📂 Setting up deployment directory at $DEPLOY_DIR...${NC}"
sudo mkdir -p "$DEPLOY_DIR"
sudo cp bin/slot_linux_x64 "$DEPLOY_DIR/clutch-server"
sudo cp -r game "$DEPLOY_DIR/"
sudo cp -r config "$DEPLOY_DIR/"

# 4. Configure Service (Systemd)
echo -e "${YELLOW}📝 Configuring systemd service...${NC}"
SERVICE_FILE="/etc/systemd/system/clutch.service"
sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Clutch Slots Games Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$DEPLOY_DIR
ExecStart=$DEPLOY_DIR/clutch-server web
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

# 5. Start the service
echo -e "${YELLOW}⚙️ Starting Clutch service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable clutch
sudo systemctl restart clutch

# 6. Verify status
echo -e "${YELLOW}🔍 Checking service status...${NC}"
sudo systemctl status clutch --no-pager

echo -e "${GREEN}✨ Clutch deployment complete!${NC}"
echo -e "${YELLOW}The server is now running as a background service.${NC}"
echo -e "${YELLOW}To view logs, run:${NC}"
echo -e "${GREEN}sudo journalctl -u clutch -f${NC}"
