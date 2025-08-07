#!/bin/bash
# This script runs on the VPS to perform the update

set -e

DEPLOY_PATH="/opt/4realoss"
BACKUP_PATH="/opt/4realoss-backup-$(date +%Y%m%d-%H%M)"

echo "🔄 Starting 4REALOSS Production Update on VPS..."

# Create backup
echo "📦 Creating backup..."
mkdir -p "$BACKUP_PATH"
cp -r "$DEPLOY_PATH" "$BACKUP_PATH/4realoss-old"
echo "✅ Backup created at: $BACKUP_PATH"

# Stop services gracefully
echo "🛑 Stopping services..."
systemctl stop 4realoss || true
sleep 2

# Backup current configuration and data
echo "💾 Preserving current configuration and data..."
cp "$DEPLOY_PATH/conf/app.ini" /tmp/app.ini.current || echo "No current config found"
cp "$DEPLOY_PATH/docker-compose.yml" /tmp/docker-compose.yml.current || echo "No docker-compose found"

# Copy new files (preserve some existing ones)
echo "📁 Installing updated files..."
cp -f realoss "$DEPLOY_PATH/"
cp -rf templates "$DEPLOY_PATH/"
cp -rf public "$DEPLOY_PATH/"

# Update configuration with fixed paths
echo "⚙️  Updating configuration..."
if [ -f "/tmp/app.ini.current" ]; then
    # Keep existing configuration but fix any hardcoded paths
    cp /tmp/app.ini.current "$DEPLOY_PATH/conf/app.ini"
    
    # Fix hardcoded paths in existing config
    sed -i 's|ROOT.*= /home/kali/gogs-repositories|ROOT = /opt/4realoss/repositories|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|PATH.*= /home/kali/Desktop/gogs/data/gogs.db|PATH = /opt/4realoss/data/gogs.db|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|ROOT_PATH.*= /home/kali/Desktop/gogs/log|ROOT_PATH = /opt/4realoss/logs|g' "$DEPLOY_PATH/conf/app.ini"
    sed -i 's|RUN_USER.*= kali|RUN_USER = gogs|g' "$DEPLOY_PATH/conf/app.ini"
    
    echo "✅ Configuration updated with path fixes"
else
    # Use new configuration
    echo "Using new configuration template..."
    cp conf/app.ini "$DEPLOY_PATH/conf/"
fi

# Ensure proper permissions
echo "🔐 Setting permissions..."
chown -R gogs:gogs "$DEPLOY_PATH"
chmod 755 "$DEPLOY_PATH/realoss"
chmod 640 "$DEPLOY_PATH/conf/app.ini"

# Create repositories directory if it doesn't exist
mkdir -p /opt/4realoss/repositories
chown gogs:gogs /opt/4realoss/repositories

# Create logs directory
mkdir -p /opt/4realoss/logs
chown gogs:gogs /opt/4realoss/logs

# Start services
echo "🚀 Starting updated services..."
systemctl start 4realoss

# Wait a moment and check status
sleep 3
if systemctl is-active --quiet 4realoss; then
    echo "✅ 4REALOSS service started successfully"
else
    echo "❌ 4REALOSS service failed to start"
    echo "📋 Service status:"
    systemctl status 4realoss --no-pager -l
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

echo ""
echo "🎉 4REALOSS Production Update Completed!"
echo ""
echo "📋 Update Summary:"
echo "- ✅ Binary updated to latest version"
echo "- ✅ Templates and public files updated" 
echo "- ✅ Configuration paths fixed"
echo "- ✅ Permissions corrected"
echo "- ✅ Services restarted"
echo "- ✅ Backup created at: $BACKUP_PATH"
echo ""
echo "🌐 Your site: https://4realoss.com"
echo "📊 Check status: systemctl status 4realoss"
echo "📝 View logs: journalctl -u 4realoss -f"
