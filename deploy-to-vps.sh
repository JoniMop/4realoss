#!/bin/bash

# Gogs + IPFS VPS Deployment Script
# Run this on your Ubuntu VPS after initial setup

set -e

echo "🚀 Setting up Gogs + IPFS on VPS"
echo "=================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing dependencies..."
sudo apt install -y git curl wget nginx certbot python3-certbot-nginx ufw

# Install Go
echo "🐹 Installing Go..."
cd /tmp
wget https://golang.org/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin

# Install IPFS
echo "🌐 Installing IPFS..."
cd /tmp
wget https://dist.ipfs.tech/kubo/v0.25.0/kubo_v0.25.0_linux-amd64.tar.gz
tar -xzf kubo_v0.25.0_linux-amd64.tar.gz
sudo mv kubo/ipfs /usr/local/bin/
ipfs --version

# Create application user
echo "👤 Creating gogs user..."
sudo useradd -m -s /bin/bash gogs
sudo mkdir -p /home/gogs/gogs-app
sudo chown gogs:gogs /home/gogs/gogs-app

# Clone your repository (replace with your repo URL)
echo "📥 Cloning application..."
sudo -u gogs git clone https://github.com/yourusername/gogs.git /home/gogs/gogs-app
cd /home/gogs/gogs-app

# Build Gogs
echo "🔨 Building Gogs..."
sudo -u gogs /usr/local/go/bin/go build

# Set up IPFS for gogs user
echo "⚙️ Setting up IPFS..."
sudo -u gogs ipfs init
sudo -u gogs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
sudo -u gogs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
sudo -u gogs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type"]'

# Create systemd services
echo "🔧 Creating systemd services..."

# IPFS service
sudo tee /etc/systemd/system/ipfs.service > /dev/null <<EOF
[Unit]
Description=IPFS daemon
After=network.target

[Service]
Type=notify
User=gogs
Group=gogs
Environment=IPFS_PATH=/home/gogs/.ipfs
ExecStart=/usr/local/bin/ipfs daemon --enable-gc
Restart=on-failure
RestartSec=10
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

# Gogs service
sudo tee /etc/systemd/system/gogs.service > /dev/null <<EOF
[Unit]
Description=Gogs Git Service
After=network.target ipfs.service
Wants=ipfs.service

[Service]
Type=simple
User=gogs
Group=gogs
WorkingDirectory=/home/gogs/gogs-app
ExecStart=/home/gogs/gogs-app/gogs web
Restart=always
RestartSec=10
Environment=USER=gogs HOME=/home/gogs

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
echo "🚀 Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable ipfs gogs
sudo systemctl start ipfs
sleep 5
sudo systemctl start gogs

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "✅ Basic setup complete!"
echo ""
echo "🌐 Next steps:"
echo "1. Point your domain DNS A record to this server's IP"
echo "2. Run: sudo ./setup-domain.sh yourdomain.com"
echo "3. Your site will be available at https://yourdomain.com" 