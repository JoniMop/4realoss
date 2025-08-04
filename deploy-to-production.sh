#!/bin/bash

# 4REALOSS Production Deployment Script
# Deploys the updated 4REALOSS with PostgreSQL + IPFS to production VPS

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
LOCAL_BUILD_DIR="./build-production"

echo -e "${PURPLE}🚀 4REALOSS Production Deployment${NC}"
echo -e "${PURPLE}==================================${NC}"
echo "Target: $VPS_USER@$VPS_HOST:$DEPLOY_PATH"
echo "Domain: https://$VPS_DOMAIN"
echo ""

# Step 1: Build Production Package
echo -e "${CYAN}📦 Step 1: Building Production Package${NC}"
echo "===================================="

# Clean previous build
rm -rf "$LOCAL_BUILD_DIR"
mkdir -p "$LOCAL_BUILD_DIR"

echo -e "${BLUE}🔨 Building 4REALOSS binary...${NC}"
# Build for Linux (production server)
GOOS=linux GOARCH=amd64 go build -o "$LOCAL_BUILD_DIR/realoss" .
chmod +x "$LOCAL_BUILD_DIR/realoss"

echo -e "${BLUE}📋 Copying application files...${NC}"
# Copy essential directories and files
cp -r templates "$LOCAL_BUILD_DIR/"
cp -r public "$LOCAL_BUILD_DIR/"
cp -r conf "$LOCAL_BUILD_DIR/"
mkdir -p "$LOCAL_BUILD_DIR/custom"
mkdir -p "$LOCAL_BUILD_DIR/logs"
mkdir -p "$LOCAL_BUILD_DIR/scripts"

# Copy database initialization script
cp scripts/init-db.sql "$LOCAL_BUILD_DIR/scripts/" 2>/dev/null || echo "Creating init-db.sql..."

# Copy Docker Compose file
cp docker-compose.dev.yml "$LOCAL_BUILD_DIR/docker-compose.yml"

echo -e "${BLUE}⚙️  Creating production configuration...${NC}"
# Create production app.ini
cat > "$LOCAL_BUILD_DIR/conf/app.ini" << 'EOF'
; 4REALOSS Production Configuration
BRAND_NAME = 4RealOSS
RUN_USER = root
RUN_MODE = prod

[server]
EXTERNAL_URL = https://4realoss.com/
DOMAIN = 4realoss.com
PROTOCOL = http
HTTP_ADDR = 127.0.0.1
HTTP_PORT = 3000
CERT_FILE = 
KEY_FILE = 
LOCAL_ROOT_URL = http://127.0.0.1:3000/

OFFLINE_MODE = false
DISABLE_ROUTER_LOG = false
ENABLE_GZIP = true

[database]
TYPE = postgres
HOST = 127.0.0.1:5432
NAME = gogs
USER = gogs
PASSWORD = gogs_production_password_2025
SSL_MODE = disable
PATH = 

[security]
INSTALL_LOCK = true
SECRET_KEY = 4realoss-production-secret-key-2025-very-secure
COOKIE_USERNAME = gogs_awesome
COOKIE_REMEMBER_NAME = gogs_incredible
REVERSE_PROXY_AUTHENTICATION_USER = X-WEBAUTH-USER

[service]
ACTIVE_CODE_LIVE_MINUTES = 180
RESET_PASSWD_CODE_LIVE_MINUTES = 180
REGISTER_EMAIL_CONFIRM = false
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false
ENABLE_CACHE_AVATAR = false
ENABLE_NOTIFY_MAIL = false
ENABLE_REVERSE_PROXY_AUTHENTICATION = false
ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = false

[mailer]
ENABLED = false

[log]
MODE = file
LEVEL = Info
ROOT_PATH = /opt/4realoss/logs
ROTATE = true

[cron]
ENABLED = true
RUN_AT_START = false

[git]
MAX_GIT_DIFF_LINES = 10000
MAX_GIT_DIFF_LINE_CHARACTERS = 5000
MAX_GIT_DIFF_FILES = 100
GC_ARGS = 

[mirror]
DEFAULT_INTERVAL = 8h

[api]
MAX_RESPONSE_ITEMS = 50

[ui]
EXPLORE_PAGING_NUM = 20
ISSUE_PAGING_NUM = 10
FEED_MAX_COMMIT_NUM = 5
THEME_COLOR_META_TAG = #ff5343
MAX_DISPLAY_FILE_SIZE = 8388608

[ui.admin]
USER_PAGING_NUM = 50
REPO_PAGING_NUM = 50
NOTICE_PAGING_NUM = 25
ORG_PAGING_NUM = 50

[ui.user]
REPO_PAGING_NUM = 15

[prometheus]
ENABLED = false
EOF

# Create production Docker Compose
cat > "$LOCAL_BUILD_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: realoss-postgres-prod
    restart: unless-stopped
    environment:
      POSTGRES_DB: gogs
      POSTGRES_USER: gogs
      POSTGRES_PASSWORD: gogs_production_password_2025
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U gogs -d gogs"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
    driver: local
EOF

# Create production database init script
cat > "$LOCAL_BUILD_DIR/scripts/init-db.sql" << 'EOF'
-- Initialize 4REALOSS Production Database
-- Create the database (will be created by POSTGRES_DB env var)
-- CREATE DATABASE gogs;

-- Create the user (will be created by POSTGRES_USER env var)
-- CREATE USER gogs WITH PASSWORD 'gogs_production_password_2025';

-- Grant privileges to the user on the database
GRANT ALL PRIVILEGES ON DATABASE gogs TO gogs;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gogs;
EOF

# Create systemd service files
mkdir -p "$LOCAL_BUILD_DIR/systemd"

# 4REALOSS service
cat > "$LOCAL_BUILD_DIR/systemd/4realoss.service" << 'EOF'
[Unit]
Description=4REALOSS Git Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/4realoss
ExecStart=/opt/4realoss/realoss web --config /opt/4realoss/conf/app.ini
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment=USER=root
Environment=HOME=/root
Environment=GOGS_WORK_DIR=/opt/4realoss

[Install]
WantedBy=multi-user.target
EOF

# IPFS service
cat > "$LOCAL_BUILD_DIR/systemd/4realoss-ipfs.service" << 'EOF'
[Unit]
Description=4REALOSS IPFS Daemon
After=network.target
Before=4realoss.service

[Service]
Type=notify
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/ipfs daemon --enable-gc
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment=IPFS_PATH=/root/.ipfs

[Install]
WantedBy=multi-user.target
EOF

# Create Nginx configuration
cat > "$LOCAL_BUILD_DIR/nginx-4realoss.conf" << 'EOF'
server {
    listen 80;
    server_name 4realoss.com www.4realoss.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name 4realoss.com www.4realoss.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/4realoss.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/4realoss.com/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;

    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Client upload limits
    client_max_body_size 500M;

    # Proxy to 4REALOSS
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # IPFS Gateway (optional - for direct access)
    location /ipfs/ {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Create deployment script for VPS
cat > "$LOCAL_BUILD_DIR/install-production.sh" << 'EOF'
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
EOF

chmod +x "$LOCAL_BUILD_DIR/install-production.sh"

echo -e "${GREEN}✅ Production package built successfully${NC}"
echo -e "${BLUE}📦 Package location: $LOCAL_BUILD_DIR${NC}"
echo ""

# Step 2: Deploy to VPS
echo -e "${CYAN}🚀 Step 2: Deploying to VPS${NC}"
echo "============================"

echo -e "${YELLOW}⚠️  Before deployment, please:${NC}"
echo "1. Update VPS_USER, VPS_HOST in this script"
echo "2. Set up SSH key authentication to your VPS"
echo "3. Update passwords in the configuration files"
echo "4. Ensure your domain DNS points to your VPS IP"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo -e "${BLUE}📤 Uploading to VPS...${NC}"

# Create backup of existing installation
ssh "$VPS_USER@$VPS_HOST" "
    if [ -d '$DEPLOY_PATH' ]; then
        echo 'Creating backup of existing installation...'
        sudo cp -r '$DEPLOY_PATH' '$BACKUP_PATH'
        echo 'Backup created at: $BACKUP_PATH'
    fi
    sudo mkdir -p '$DEPLOY_PATH'
    sudo chown $VPS_USER:$VPS_USER '$DEPLOY_PATH'
"

# Upload files
rsync -avz --progress "$LOCAL_BUILD_DIR/" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/"

# Run installation script
echo -e "${BLUE}🔧 Running installation on VPS...${NC}"
ssh "$VPS_USER@$VPS_HOST" "cd '$DEPLOY_PATH' && sudo ./install-production.sh"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Set up SSL certificate: sudo certbot --nginx -d 4realoss.com -d www.4realoss.com"
echo "2. Check service status: ssh $VPS_USER@$VPS_HOST 'systemctl status 4realoss'"
echo "3. Monitor logs: ssh $VPS_USER@$VPS_HOST 'journalctl -u 4realoss -f'"
echo "4. Visit your site: https://4realoss.com"
echo ""
echo -e "${BLUE}🛠️  Troubleshooting commands:${NC}"
echo "- Restart services: ssh $VPS_USER@$VPS_HOST 'systemctl restart 4realoss-ipfs && systemctl restart 4realoss'"
echo "- Check PostgreSQL: ssh $VPS_USER@$VPS_HOST 'docker logs realoss-postgres-prod'"
echo "- View application logs: ssh $VPS_USER@$VPS_HOST 'tail -f /opt/4realoss/logs/gogs.log'"