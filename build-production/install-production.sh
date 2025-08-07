#!/bin/bash
# 4REALOSS Production Installation Script (runs on VPS)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installing 4REALOSS Production${NC}"
echo "=================================="

# Install IPFS if not already installed
if ! command -v ipfs &> /dev/null; then
    echo -e "${BLUE}📦 Installing IPFS...${NC}"
    wget -q https://dist.ipfs.io/kubo/v0.19.1/kubo_v0.19.1_linux-amd64.tar.gz
    tar -xzf kubo_v0.19.1_linux-amd64.tar.gz
    sudo mv kubo/ipfs /usr/local/bin/
    rm -rf kubo kubo_v0.19.1_linux-amd64.tar.gz
    echo -e "${GREEN}✅ IPFS installed${NC}"
fi

# Initialize IPFS if not already done
if [ ! -d "/root/.ipfs" ]; then
    echo -e "${BLUE}🔧 Initializing IPFS...${NC}"
    ipfs init
    
    # Configure IPFS for production
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
    ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization"]'
    ipfs config Addresses.API /ip4/127.0.0.1/tcp/5002
    ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8081
    echo -e "${GREEN}✅ IPFS configured${NC}"
fi

# Stop old services
echo -e "${BLUE}🛑 Stopping old services...${NC}"
systemctl stop gogs || true
systemctl stop 4realoss || true
systemctl stop 4realoss-ipfs || true
docker stop $(docker ps -q) || true

# Start PostgreSQL
echo -e "${BLUE}🐘 Starting PostgreSQL...${NC}"
docker compose up -d postgres
sleep 10

# Install systemd services
echo -e "${BLUE}⚙️  Installing systemd services...${NC}"
cp systemd/4realoss.service /etc/systemd/system/
cp systemd/4realoss-ipfs.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable 4realoss-ipfs
systemctl enable 4realoss

# Install Nginx configuration
echo -e "${BLUE}🌐 Installing Nginx configuration...${NC}"
cp nginx-4realoss.conf /etc/nginx/sites-available/4realoss
ln -sf /etc/nginx/sites-available/4realoss /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Start services
echo -e "${BLUE}🚀 Starting services...${NC}"
systemctl start 4realoss-ipfs
sleep 5
systemctl start 4realoss

echo -e "${GREEN}✅ 4REALOSS Production Installation Complete!${NC}"
echo ""
echo "Services:"
echo "- 4REALOSS: systemctl status 4realoss"
echo "- IPFS: systemctl status 4realoss-ipfs"
echo "- PostgreSQL: docker ps"
echo ""
echo "Logs:"
echo "- 4REALOSS: journalctl -u 4realoss -f"
echo "- IPFS: journalctl -u 4realoss-ipfs -f"
echo ""
echo "Website: https://4realoss.com"
