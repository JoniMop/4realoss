#!/bin/bash

# Complete 4REALOSS Production Update - Binary + Frontend + Config
# This uploads the latest code AND fixes configuration

set -e

echo "🚀 Complete 4REALOSS Production Update"
echo "======================================"
echo "This will:"
echo "1. Build latest 4REALOSS binary with all your changes"
echo "2. Upload new binary and frontend files to production"
echo "3. Fix configuration paths"
echo "4. Restart services"
echo ""

# Build latest version locally first
LOCAL_BUILD_DIR="./build-complete-update"
rm -rf "$LOCAL_BUILD_DIR"
mkdir -p "$LOCAL_BUILD_DIR"

echo "🔨 Building latest 4REALOSS binary locally..."
GOOS=linux GOARCH=amd64 go build -buildvcs=false -o "$LOCAL_BUILD_DIR/realoss" .
chmod +x "$LOCAL_BUILD_DIR/realoss"

echo "📋 Preparing updated files..."
cp -r templates "$LOCAL_BUILD_DIR/"
cp -r public "$LOCAL_BUILD_DIR/"
cp -r conf "$LOCAL_BUILD_DIR/"

# Create the complete update script
cat > "$LOCAL_BUILD_DIR/deploy-update.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

DEPLOY_PATH="/opt/4realoss"
BACKUP_PATH="/opt/4realoss-backup-$(date +%Y%m%d-%H%M)"

echo "🔄 Starting Complete 4REALOSS Update on VPS..."

# Create backup
echo "📦 Creating backup..."
mkdir -p "$BACKUP_PATH"
cp -r "$DEPLOY_PATH" "$BACKUP_PATH/4realoss-old"
echo "✅ Backup created at: $BACKUP_PATH"

# Stop services
echo "🛑 Stopping services..."
systemctl stop 4realoss || true
sleep 2

# Backup current configuration
echo "💾 Preserving current configuration..."
cp "$DEPLOY_PATH/conf/app.ini" /tmp/app.ini.backup

# Install new binary and files
echo "📁 Installing updated binary and files..."
cp ./realoss "$DEPLOY_PATH/"
cp -r ./templates "$DEPLOY_PATH/"
cp -r ./public "$DEPLOY_PATH/"

# Restore and fix configuration
echo "⚙️  Updating configuration with production paths..."
cp /tmp/app.ini.backup "$DEPLOY_PATH/conf/app.ini"

# Fix all hardcoded development paths
sed -i 's|ROOT.*= /home/kali/gogs-repositories|ROOT = /opt/4realoss/repositories|g' "$DEPLOY_PATH/conf/app.ini"
sed -i 's|PATH.*= /home/kali/Desktop/gogs/data/gogs.db|PATH = /opt/4realoss/data/gogs.db|g' "$DEPLOY_PATH/conf/app.ini"
sed -i 's|ROOT_PATH.*= /home/kali/Desktop/gogs/log|ROOT_PATH = /opt/4realoss/logs|g' "$DEPLOY_PATH/conf/app.ini"
sed -i 's|RUN_USER.*= kali|RUN_USER = gogs|g' "$DEPLOY_PATH/conf/app.ini"

# Ensure proper ownership and permissions
echo "🔐 Setting proper permissions..."
chown -R gogs:gogs "$DEPLOY_PATH"
chmod +x "$DEPLOY_PATH/realoss"
chmod 640 "$DEPLOY_PATH/conf/app.ini"

# Create required directories
mkdir -p /opt/4realoss/repositories /opt/4realoss/logs /opt/4realoss/data
chown gogs:gogs /opt/4realoss/repositories /opt/4realoss/logs /opt/4realoss/data

# Start services
echo "🚀 Starting updated services..."
systemctl start 4realoss

# Wait and verify
sleep 5
if systemctl is-active --quiet 4realoss; then
    echo "✅ Service started successfully"
    
    # Get version info
    echo "📋 Version info:"
    cd "$DEPLOY_PATH" && ./realoss --version || echo "Version check failed"
    
    # Test HTTP
    if curl -f -s http://127.0.0.1:3000/ > /dev/null; then
        echo "✅ HTTP responding"
    else
        echo "⚠️  HTTP not responding"
    fi
    
    # Test HTTPS
    if curl -f -s https://4realoss.com/ > /dev/null; then
        echo "✅ HTTPS responding"
    else
        echo "⚠️  HTTPS not responding"
    fi
    
else
    echo "❌ Service failed to start"
    systemctl status 4realoss --no-pager
    exit 1
fi

echo ""
echo "🎉 Complete Update Finished!"
echo "- ✅ Latest binary deployed"
echo "- ✅ Frontend files updated" 
echo "- ✅ Configuration fixed"
echo "- ✅ Services restarted"
echo "- ✅ Backup at: $BACKUP_PATH"
echo ""
echo "🌐 Site: https://4realoss.com"
echo "🔄 Clear browser cache to see changes!"

DEPLOY_SCRIPT

chmod +x "$LOCAL_BUILD_DIR/deploy-update.sh"

echo "✅ Update package prepared locally"
echo ""

# Now upload and run on VPS
echo "📤 Uploading complete update to VPS..."
echo "You'll need to enter your VPS password for the upload and execution:"
echo ""

# Create a here-document that uploads files via SSH
ssh root@164.92.110.168 'bash -s' << UPLOAD_SCRIPT

echo "🔄 Preparing update on VPS..."
rm -rf /tmp/4realoss-complete-update
mkdir -p /tmp/4realoss-complete-update

UPLOAD_SCRIPT

# Upload files using tar through SSH to avoid multiple password prompts
echo "📦 Creating and uploading update package..."
cd "$LOCAL_BUILD_DIR"
tar czf - . | ssh root@164.92.110.168 'cd /tmp/4realoss-complete-update && tar xzf -'

# Execute the update
echo "🚀 Running complete update on VPS..."
ssh root@164.92.110.168 'cd /tmp/4realoss-complete-update && ./deploy-update.sh'

# Cleanup
ssh root@164.92.110.168 'rm -rf /tmp/4realoss-complete-update'

echo ""
echo "🎊 Complete Production Update Finished!"
echo ""
echo "🔄 IMPORTANT: Clear your browser cache and hard refresh (Ctrl+F5)"
echo "🌐 Visit: https://4realoss.com"
echo "🔍 You should now see:"
echo "   - Updated Phantom wallet integration"
echo "   - Latest frontend changes"
echo "   - All new features and fixes"
echo ""
echo "✨ Your 4REALOSS is now fully updated with latest code!"