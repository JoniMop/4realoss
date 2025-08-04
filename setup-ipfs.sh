#!/bin/bash

# IPFS Setup Script for Gogs Integration
# This script installs and configures IPFS for local repository publishing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌍 Setting up IPFS for Gogs Repository Publishing${NC}"
echo "=================================================="

# Check if IPFS is already installed
if command -v ipfs &> /dev/null; then
    echo -e "${GREEN}✅ IPFS is already installed${NC}"
    ipfs version
else
    echo -e "${BLUE}📦 Installing IPFS...${NC}"
    
    # Download and install IPFS
    IPFS_VERSION="v0.19.1"
    IPFS_ARCH="linux-amd64"
    IPFS_URL="https://dist.ipfs.io/kubo/${IPFS_VERSION}/kubo_${IPFS_VERSION}_${IPFS_ARCH}.tar.gz"
    
    echo "Downloading IPFS ${IPFS_VERSION}..."
    wget -q "$IPFS_URL" -O ipfs.tar.gz
    
    echo "Extracting..."
    tar -xzf ipfs.tar.gz
    
    echo "Installing to /usr/local/bin..."
    sudo mv kubo/ipfs /usr/local/bin/
    
    echo "Cleaning up..."
    rm -rf kubo ipfs.tar.gz
    
    echo -e "${GREEN}✅ IPFS installed successfully${NC}"
fi

# Initialize IPFS if not already done
if [ ! -d "$HOME/.ipfs" ]; then
    echo -e "${BLUE}🔧 Initializing IPFS...${NC}"
    ipfs init
    echo -e "${GREEN}✅ IPFS initialized${NC}"
else
    echo -e "${GREEN}✅ IPFS already initialized${NC}"
fi

# Configure IPFS for Gogs integration
echo -e "${BLUE}⚙️  Configuring IPFS for Gogs...${NC}"

# Enable CORS for web interface access
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization"]'

# Set up custom ports to avoid conflicts
ipfs config Addresses.API /ip4/127.0.0.1/tcp/5002
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8081

# Enable some useful experimental features
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Experimental.UrlstoreEnabled true

echo -e "${GREEN}✅ IPFS configured for Gogs integration${NC}"

# Create systemd service for IPFS
echo -e "${BLUE}🔧 Creating IPFS systemd service...${NC}"

sudo tee /etc/systemd/system/ipfs.service > /dev/null <<EOF
[Unit]
Description=IPFS Daemon
Documentation=https://docs.ipfs.io/
After=network.target

[Service]
Type=notify
User=$USER
Environment=IPFS_PATH=$HOME/.ipfs
ExecStart=/usr/local/bin/ipfs daemon --enable-gc
Restart=on-failure
RestartSec=10
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable IPFS service
sudo systemctl daemon-reload
sudo systemctl enable ipfs

echo -e "${GREEN}✅ IPFS systemd service created and enabled${NC}"

# Start IPFS daemon
echo -e "${BLUE}🚀 Starting IPFS daemon...${NC}"
sudo systemctl start ipfs

# Wait a moment for startup
sleep 3

# Check IPFS status
if systemctl is-active --quiet ipfs; then
    echo -e "${GREEN}✅ IPFS daemon is running${NC}"
    
    # Test IPFS API
    if curl -s http://127.0.0.1:5002/api/v0/version >/dev/null; then
        echo -e "${GREEN}✅ IPFS API is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  IPFS API might not be ready yet${NC}"
    fi
    
    # Test IPFS Gateway
    if curl -s http://127.0.0.1:8081/ >/dev/null; then
        echo -e "${GREEN}✅ IPFS Gateway is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  IPFS Gateway might not be ready yet${NC}"
    fi
else
    echo -e "${RED}❌ IPFS daemon failed to start${NC}"
    echo "Check logs with: sudo journalctl -u ipfs -f"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 IPFS Setup Complete!${NC}"
echo "============================================"
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo "  • IPFS API: http://127.0.0.1:5002"
echo "  • IPFS Gateway: http://127.0.0.1:8081"  
echo "  • IPFS Path: $HOME/.ipfs"
echo "  • Service: ipfs.service (enabled)"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo "  • Start IPFS: sudo systemctl start ipfs"
echo "  • Stop IPFS: sudo systemctl stop ipfs" 
echo "  • Status: sudo systemctl status ipfs"
echo "  • Logs: sudo journalctl -u ipfs -f"
echo ""
echo -e "${BLUE}🌐 Next Steps:${NC}"
echo "  1. Restart Gogs to use the new IPFS node"
echo "  2. Try uploading a repository to IPFS again"
echo "  3. Your files will be pinned locally and announced to the network"
echo ""
echo -e "${YELLOW}💡 Pro Tip:${NC}"
echo "  For better global availability, consider also setting up Pinata"
echo "  as a backup service for redundant pinning!"