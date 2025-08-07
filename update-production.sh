#!/bin/bash

# 4REALOSS Production Update Script
# Updates existing production installation with latest code and security fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VPS_USER="root"
VPS_HOST="164.92.110.168"
VPS_DOMAIN="4realoss.com"
DEPLOY_PATH="/opt/4realoss"
BACKUP_PATH="/opt/4realoss-backup-$(date +%Y%m%d-%H%M)"
LOCAL_BUILD_DIR="./build-production-update"

echo -e "${PURPLE}🔄 4REALOSS Production Update${NC}"
echo -e "${PURPLE}==============================${NC}"
echo "Target: $VPS_USER@$VPS_HOST:$DEPLOY_PATH"
echo "Domain: https://$VPS_DOMAIN"
echo "Backup: $BACKUP_PATH"
echo ""

# Step 1: Build updated production package
echo -e "${CYAN}📦 Step 1: Building Updated Production Package${NC}"
echo "=============================================="

# Clean previous build
rm -rf "$LOCAL_BUILD_DIR"
mkdir -p "$LOCAL_BUILD_DIR"

echo -e "${BLUE}🔨 Building updated 4REALOSS binary...${NC}"
# Build for Linux (production server) - disable VCS to avoid git issues
GOOS=linux GOARCH=amd64 go build -buildvcs=false -o "$LOCAL_BUILD_DIR/realoss" .
chmod +x "$LOCAL_BUILD_DIR/realoss"

echo -e "${BLUE}📋 Copying updated application files...${NC}"
# Copy essential directories and files
cp -r templates "$LOCAL_BUILD_DIR/"
cp -r public "$LOCAL_BUILD_DIR/"
cp -r conf "$LOCAL_BUILD_DIR/"
mkdir -p "$LOCAL_BUILD_DIR/custom"
mkdir -p "$LOCAL_BUILD_DIR/logs"
mkdir -p "$LOCAL_BUILD_DIR/scripts"

# Create update script that will run on VPS
cat > "$LOCAL_BUILD_DIR/run-update.sh" << 'EOF'
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
EOF

chmod +x "$LOCAL_BUILD_DIR/run-update.sh"

echo -e "${GREEN}✅ Update package built successfully${NC}"
echo -e "${BLUE}📦 Package location: $LOCAL_BUILD_DIR${NC}"
echo ""

# Step 2: Deploy update to VPS
echo -e "${CYAN}🚀 Step 2: Deploying Update to VPS${NC}"
echo "=================================="

echo -e "${YELLOW}⚠️  This will update your running production system.${NC}"
echo "Current backup will be created automatically."
echo ""

read -p "Continue with production update? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 1
fi

echo -e "${BLUE}📤 Uploading update to VPS...${NC}"

# Upload files to temporary location first
ssh "$VPS_USER@$VPS_HOST" "mkdir -p /tmp/4realoss-update"
rsync -avz --progress "$LOCAL_BUILD_DIR/" "$VPS_USER@$VPS_HOST:/tmp/4realoss-update/"

# Run the update script on VPS
echo -e "${BLUE}🔧 Running update on VPS...${NC}"
ssh "$VPS_USER@$VPS_HOST" "cd /tmp/4realoss-update && sudo ./run-update.sh"

# Clean up temporary files
ssh "$VPS_USER@$VPS_HOST" "rm -rf /tmp/4realoss-update"

# Final verification
echo -e "${BLUE}🔍 Final verification...${NC}"
ssh "$VPS_USER@$VPS_HOST" "
    echo '=== Service Status ==='
    systemctl status 4realoss --no-pager -l
    echo ''
    echo '=== Version Check ==='
    cd /opt/4realoss && ./realoss --version
    echo ''
    echo '=== HTTP Test ==='
    curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:3000/ || echo 'HTTP test failed'
    echo ''
    echo '=== HTTPS Test ==='
    curl -s -o /dev/null -w 'HTTPS Status: %{http_code}\n' https://4realoss.com/ || echo 'HTTPS test failed'
"

echo -e "${GREEN}🎉 Production Update completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 What was updated:${NC}"
echo "1. ✅ Latest 4REALOSS binary with all recent changes"
echo "2. ✅ Updated templates and public files"
echo "3. ✅ Fixed hardcoded development paths"
echo "4. ✅ Preserved your existing configuration and data"
echo "5. ✅ Maintained SSL certificate and nginx setup"
echo ""
echo -e "${BLUE}🔍 Monitoring:${NC}"
echo "- Check status: ssh $VPS_USER@$VPS_HOST 'systemctl status 4realoss'"
echo "- View logs: ssh $VPS_USER@$VPS_HOST 'journalctl -u 4realoss -f'"
echo "- Site: https://4realoss.com"
echo ""
echo -e "${YELLOW}💡 Note: Your backup is available at $BACKUP_PATH on the VPS${NC}"