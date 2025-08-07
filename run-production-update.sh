#!/bin/bash

# 4REALOSS Production Update - Single Command
# Run this from your local machine, it will SSH and update production

echo "🚀 4REALOSS Production Update"
echo "============================="
echo "This will connect to your VPS and update the production system"
echo "You'll be prompted for your VPS password"
echo ""

# Execute the update remotely via SSH
ssh root@164.92.110.168 'bash -s' << 'EOF'

set -e

DEPLOY_PATH="/opt/4realoss"
BACKUP_PATH="/opt/4realoss-backup-$(date +%Y%m%d-%H%M)"

echo "🔄 Starting 4REALOSS Production Update on VPS..."

# Create backup first
echo "📦 Creating backup..."
mkdir -p "$BACKUP_PATH"
cp -r "$DEPLOY_PATH" "$BACKUP_PATH/4realoss-old"
echo "✅ Backup created at: $BACKUP_PATH"

# Show current configuration before changes
echo "📋 Current configuration paths:"
grep -E "^ROOT|^PATH|^ROOT_PATH|^RUN_USER" "$DEPLOY_PATH/conf/app.ini" || true
echo ""

# Stop services gracefully
echo "🛑 Stopping 4REALOSS service..."
systemctl stop 4realoss || true
sleep 2

# Fix hardcoded paths in configuration
echo "⚙️  Fixing hardcoded development paths..."

# Fix repository root path
if grep -q "ROOT.*= /home/kali/gogs-repositories" "$DEPLOY_PATH/conf/app.ini"; then
    sed -i 's|ROOT.*= /home/kali/gogs-repositories|ROOT = /opt/4realoss/repositories|g' "$DEPLOY_PATH/conf/app.ini"
    echo "✓ Fixed repository ROOT path"
fi

# Fix SQLite database path (if present)
if grep -q "PATH.*= /home/kali/Desktop/gogs/data/gogs.db" "$DEPLOY_PATH/conf/app.ini"; then
    sed -i 's|PATH.*= /home/kali/Desktop/gogs/data/gogs.db|PATH = /opt/4realoss/data/gogs.db|g' "$DEPLOY_PATH/conf/app.ini"
    echo "✓ Fixed database PATH"
fi

# Fix log path
if grep -q "ROOT_PATH.*= /home/kali/Desktop/gogs/log" "$DEPLOY_PATH/conf/app.ini"; then
    sed -i 's|ROOT_PATH.*= /home/kali/Desktop/gogs/log|ROOT_PATH = /opt/4realoss/logs|g' "$DEPLOY_PATH/conf/app.ini"
    echo "✓ Fixed log ROOT_PATH"
fi

# Fix run user
if grep -q "RUN_USER.*= kali" "$DEPLOY_PATH/conf/app.ini"; then
    sed -i 's|RUN_USER.*= kali|RUN_USER = gogs|g' "$DEPLOY_PATH/conf/app.ini"
    echo "✓ Fixed RUN_USER"
fi

# Show updated configuration
echo ""
echo "📋 Updated configuration paths:"
grep -E "^ROOT|^PATH|^ROOT_PATH|^RUN_USER" "$DEPLOY_PATH/conf/app.ini" || true
echo ""

# Create required directories with proper ownership
echo "📁 Creating/fixing directory structure..."
mkdir -p /opt/4realoss/repositories
mkdir -p /opt/4realoss/logs  
mkdir -p /opt/4realoss/data

# Set proper ownership and permissions
chown -R gogs:gogs "$DEPLOY_PATH"
chmod 755 "$DEPLOY_PATH/realoss" 2>/dev/null || true
chmod 640 "$DEPLOY_PATH/conf/app.ini"

echo "✅ Directory structure and permissions updated"

# Start services
echo "🚀 Starting 4REALOSS service..."
systemctl start 4realoss

# Wait for service to start and check status
echo "⏳ Waiting for service to start..."
sleep 5

if systemctl is-active --quiet 4realoss; then
    echo "✅ 4REALOSS service started successfully"
    
    # Test HTTP response
    echo "🧪 Testing HTTP response..."
    if curl -f -s http://127.0.0.1:3000/ > /dev/null; then
        echo "✅ HTTP service responding correctly"
    else
        echo "⚠️  HTTP service not responding (may still be starting)"
    fi
    
    # Test HTTPS response
    echo "🧪 Testing HTTPS response..."
    if curl -f -s https://4realoss.com/ > /dev/null; then
        echo "✅ HTTPS service responding correctly"
    else
        echo "⚠️  HTTPS service not responding (check SSL/nginx)"
    fi
    
else
    echo "❌ 4REALOSS service failed to start"
    echo "📋 Service status:"
    systemctl status 4realoss --no-pager -l
    echo ""
    echo "📝 Recent logs:"
    journalctl -u 4realoss -n 20 --no-pager
    exit 1
fi

# Final status check
echo ""
echo "🎉 4REALOSS Production Update Completed Successfully!"
echo ""
echo "📋 Update Summary:"
echo "- ✅ Configuration paths fixed for production"
echo "- ✅ Directory structure created/updated"
echo "- ✅ Proper ownership and permissions set"
echo "- ✅ Service restarted and verified"
echo "- ✅ HTTP/HTTPS responses tested"
echo "- ✅ Backup created at: $BACKUP_PATH"
echo ""
echo "🌐 Your site: https://4realoss.com"
echo "📊 Service status: $(systemctl is-active 4realoss)"
echo "📝 View logs: journalctl -u 4realoss -f"
echo ""
echo "✨ 4REALOSS is now running with production-ready configuration!"

EOF

echo ""
echo "🎊 Production update completed from your local machine!"
echo "Your 4REALOSS instance should now be running with fixed paths and proper configuration."