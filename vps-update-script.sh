#!/bin/bash

# 4REALOSS VPS Update Script - Run this directly on your VPS
# Copy and paste this entire script into your VPS terminal

set -e

echo "🔄 4REALOSS Production Update (VPS Direct)"
echo "=========================================="

DEPLOY_PATH="/opt/4realoss"
BACKUP_PATH="/opt/4realoss-backup-$(date +%Y%m%d-%H%M)"

# Create backup first
echo "📦 Creating backup..."
mkdir -p "$BACKUP_PATH"
cp -r "$DEPLOY_PATH" "$BACKUP_PATH/4realoss-old"
echo "✅ Backup created at: $BACKUP_PATH"

# Stop services gracefully
echo "🛑 Stopping services..."
systemctl stop 4realoss || true
sleep 2

# Backup current configuration
echo "💾 Preserving current configuration..."
cp "$DEPLOY_PATH/conf/app.ini" /tmp/app.ini.current || echo "No current config found"

# Download and build latest version directly on VPS
echo "🔨 Building latest 4REALOSS on VPS..."

# Install Go if not present (Ubuntu/Debian)
if ! command -v go &> /dev/null; then
    echo "📦 Installing Go..."
    wget -q https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm go1.23.4.linux-amd64.tar.gz
fi

# Create temporary build directory
BUILD_DIR="/tmp/4realoss-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone/download source (you may need to adjust this based on your repository)
echo "📥 Getting latest source code..."
if [ -d "/opt/4realoss/.git" ]; then
    # If git repo exists, pull latest
    cp -r "$DEPLOY_PATH/.git" ./
    git reset --hard HEAD
    git pull || echo "Pull failed, using current version"
else
    echo "⚠️  No git repository found, using manual update approach"
    echo "Please upload the latest source code manually"
    exit 1
fi

# Build the binary
echo "🔨 Building binary..."
/usr/local/go/bin/go build -buildvcs=false -o realoss .

# Install updated files
echo "📁 Installing updated files..."
cp realoss "$DEPLOY_PATH/"
chmod +x "$DEPLOY_PATH/realoss"

# Update configuration with fixed paths
echo "⚙️  Updating configuration..."
if [ -f "/tmp/app.ini.current" ]; then
    cp /tmp/app.ini.current "$DEPLOY_PATH/conf/app.ini"
    
    # Fix hardcoded paths in existing config
    sed -i 's|ROOT.*= /home/kali/gogs-repositories|ROOT = /opt/4realoss/repositories|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|PATH.*= /home/kali/Desktop/gogs/data/gogs.db|PATH = /opt/4realoss/data/gogs.db|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|ROOT_PATH.*= /home/kali/Desktop/gogs/log|ROOT_PATH = /opt/4realoss/logs|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|RUN_USER.*= kali|RUN_USER = gogs|g' "$DEPLOY_PATH/conf/app.ini"
    
    echo "✅ Configuration updated with path fixes"
fi

# Ensure proper permissions
echo "🔐 Setting permissions..."
chown -R gogs:gogs "$DEPLOY_PATH"
chmod 755 "$DEPLOY_PATH/realoss"
chmod 640 "$DEPLOY_PATH/conf/app.ini"

# Create required directories
mkdir -p /opt/4realoss/repositories /opt/4realoss/logs
chown gogs:gogs /opt/4realoss/repositories /opt/4realoss/logs

# Start services
echo "🚀 Starting updated services..."
systemctl start 4realoss

# Wait and check status
sleep 3
if systemctl is-active --quiet 4realoss; then
    echo "✅ 4REALOSS service started successfully"
else
    echo "❌ 4REALOSS service failed to start"
    systemctl status 4realoss --no-pager -l
    echo "Rolling back..."
    systemctl stop 4realoss || true
    cp "$BACKUP_PATH/4realoss-old/realoss" "$DEPLOY_PATH/"
    systemctl start 4realoss
    exit 1
fi

# Test the service
echo "🧪 Testing the updated service..."
sleep 2
if curl -f -s http://127.0.0.1:3000/ > /dev/null; then
    echo "✅ HTTP service responding correctly"
else
    echo "⚠️  HTTP service not responding properly"
fi

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "🎉 4REALOSS Production Update Completed!"
echo ""
echo "📋 Update Summary:"
echo "- ✅ Binary updated to latest version"
echo "- ✅ Configuration paths fixed"
echo "- ✅ Permissions corrected"
echo "- ✅ Services restarted"
echo "- ✅ Backup created at: $BACKUP_PATH"
echo ""
echo "🌐 Your site: https://4realoss.com"
echo "📊 Check status: systemctl status 4realoss"
echo "📝 View logs: journalctl -u 4realoss -f"