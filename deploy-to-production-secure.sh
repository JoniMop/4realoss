#!/bin/bash

# 4REALOSS Secure Production Deployment Script
# Deploys with security best practices: dedicated user, strong passwords, restricted access

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

# Generate secure random passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)
SECRET_KEY=$(openssl rand -base64 64 | tr -d '=/+' | head -c 64)

echo -e "${PURPLE}🔒 4REALOSS Secure Production Deployment${NC}"
echo -e "${PURPLE}========================================${NC}"
echo "Target: $VPS_USER@$VPS_HOST:$DEPLOY_PATH"
echo "Domain: https://$VPS_DOMAIN"
echo ""

# Step 1: Build Production Package
echo -e "${CYAN}📦 Step 1: Building Secure Production Package${NC}"
echo "============================================="

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

echo -e "${BLUE}⚙️  Creating secure production configuration...${NC}"
# Create production app.ini with security hardening
cat > "$LOCAL_BUILD_DIR/conf/app.ini" << EOF
; 4REALOSS Secure Production Configuration
BRAND_NAME = 4RealOSS
RUN_USER = realoss
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
PASSWORD = $DB_PASSWORD
SSL_MODE = disable
PATH = 

[security]
INSTALL_LOCK = true
SECRET_KEY = $SECRET_KEY
COOKIE_USERNAME = gogs_awesome
COOKIE_REMEMBER_NAME = gogs_incredible
REVERSE_PROXY_AUTHENTICATION_USER = X-WEBAUTH-USER
COOKIE_SECURE = true
ENABLE_LOGIN_STATUS_COOKIE = true

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

[repository]
ROOT = /opt/4realoss/repositories
SCRIPT_TYPE = bash
FORCE_PRIVATE = false
MAX_CREATION_LIMIT = -1
PREFERRED_LICENSES = Apache License 2.0, MIT License
DISABLE_HTTP_GIT = false
ENABLE_LOCAL_PATH_MIGRATION = false
ENABLE_RAW_FILE_RENDER_MODE = false
COMMITS_FETCH_CONCURRENCY = 0
DEFAULT_BRANCH = master
EOF

# Create secure production Docker Compose
cat > "$LOCAL_BUILD_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: realoss-postgres-prod
    restart: unless-stopped
    environment:
      POSTGRES_DB: gogs
      POSTGRES_USER: gogs
      POSTGRES_PASSWORD: $DB_PASSWORD
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    ports:
      - "127.0.0.1:5432:5432"  # Bind only to localhost
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U gogs -d gogs"]
      interval: 10s
      timeout: 5s
      retries: 5
    security_opt:
      - no-new-privileges:true
    read_only: false
    tmpfs:
      - /tmp
      - /var/run/postgresql

volumes:
  postgres_data:
    driver: local
EOF

# Create production database init script
cat > "$LOCAL_BUILD_DIR/scripts/init-db.sql" << EOF
-- Initialize 4REALOSS Production Database
-- Grant privileges to the user on the database
GRANT ALL PRIVILEGES ON DATABASE gogs TO gogs;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gogs;
EOF

# Create systemd service files
mkdir -p "$LOCAL_BUILD_DIR/systemd"

# 4REALOSS service (runs as dedicated user)
cat > "$LOCAL_BUILD_DIR/systemd/4realoss.service" << EOF
[Unit]
Description=4REALOSS Git Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=realoss
Group=realoss
WorkingDirectory=/opt/4realoss
ExecStart=/opt/4realoss/realoss web --config /opt/4realoss/conf/app.ini
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/4realoss
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Environment
Environment=USER=realoss
Environment=HOME=/opt/4realoss
Environment=GOGS_WORK_DIR=/opt/4realoss

[Install]
WantedBy=multi-user.target
EOF

# IPFS service (runs as dedicated user)
cat > "$LOCAL_BUILD_DIR/systemd/4realoss-ipfs.service" << EOF
[Unit]
Description=4REALOSS IPFS Daemon
After=network.target
Before=4realoss.service

[Service]
Type=notify
User=realoss
Group=realoss
WorkingDirectory=/opt/4realoss
ExecStart=/usr/local/bin/ipfs daemon --enable-gc
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/4realoss
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Environment
Environment=IPFS_PATH=/opt/4realoss/.ipfs

[Install]
WantedBy=multi-user.target
EOF

# Create enhanced Nginx configuration
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

    # SSL Security - Modern configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' cdn.jsdelivr.net unpkg.com; style-src 'self' 'unsafe-inline' cdn.jsdelivr.net; img-src 'self' data: https:; font-src 'self' cdn.jsdelivr.net; connect-src 'self' https://api.pinata.cloud" always;

    # Hide server version
    server_tokens off;

    # Client upload limits
    client_max_body_size 500M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=3r/m;
    limit_req_zone $binary_remote_addr zone=general:10m rate=30r/m;

    # Proxy to 4REALOSS
    location / {
        limit_req zone=general burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Stricter rate limiting for login endpoints
    location ~* ^/(user/login|user/sign_up) {
        limit_req zone=login burst=3 nodelay;
        
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # IPFS Gateway (optional - for direct access)
    location /ipfs/ {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Block access to sensitive files
    location ~ /\.(ht|git|env) {
        deny all;
        return 404;
    }
}
EOF

# Create secure deployment script for VPS
cat > "$LOCAL_BUILD_DIR/install-production-secure.sh" << 'EOF'
#!/bin/bash
# 4REALOSS Secure Production Installation Script (runs on VPS)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔒 Installing 4REALOSS Production (Secure)${NC}"
echo "=============================================="

# Create dedicated user for 4REALOSS
if ! id "realoss" &>/dev/null; then
    echo -e "${BLUE}👤 Creating dedicated user 'realoss'...${NC}"
    useradd --system --home-dir /opt/4realoss --shell /bin/bash --comment "4REALOSS Service User" realoss
    mkdir -p /opt/4realoss
    chown realoss:realoss /opt/4realoss
    echo -e "${GREEN}✅ User 'realoss' created${NC}"
else
    echo -e "${YELLOW}⚠️  User 'realoss' already exists${NC}"
fi

# Install IPFS if not already installed
if ! command -v ipfs &> /dev/null; then
    echo -e "${BLUE}📦 Installing IPFS...${NC}"
    wget -q https://dist.ipfs.io/kubo/v0.19.1/kubo_v0.19.1_linux-amd64.tar.gz
    tar -xzf kubo_v0.19.1_linux-amd64.tar.gz
    sudo mv kubo/ipfs /usr/local/bin/
    rm -rf kubo kubo_v0.19.1_linux-amd64.tar.gz
    echo -e "${GREEN}✅ IPFS installed${NC}"
fi

# Initialize IPFS for the realoss user
if [ ! -d "/opt/4realoss/.ipfs" ]; then
    echo -e "${BLUE}🔧 Initializing IPFS for realoss user...${NC}"
    sudo -u realoss ipfs init
    
    # Configure IPFS for production (secure defaults)
    sudo -u realoss ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://127.0.0.1:3000"]'
    sudo -u realoss ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
    sudo -u realoss ipfs config Addresses.API /ip4/127.0.0.1/tcp/5002
    sudo -u realoss ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8081
    
    # Disable unnecessary features for security
    sudo -u realoss ipfs config --json Experimental.FilestoreEnabled false
    sudo -u realoss ipfs config --json Experimental.UrlstoreEnabled false
    echo -e "${GREEN}✅ IPFS configured securely${NC}"
fi

# Set up file permissions
echo -e "${BLUE}🔐 Setting up secure file permissions...${NC}"
chown -R realoss:realoss /opt/4realoss
chmod 750 /opt/4realoss
chmod 640 /opt/4realoss/conf/app.ini
chmod +x /opt/4realoss/realoss

# Stop old services
echo -e "${BLUE}🛑 Stopping old services...${NC}"
systemctl stop gogs || true
systemctl stop 4realoss || true
systemctl stop 4realoss-ipfs || true
docker stop $(docker ps -q) || true

# Start PostgreSQL
echo -e "${BLUE}🐘 Starting PostgreSQL...${NC}"
docker compose up -d postgres
sleep 15

# Wait for PostgreSQL to be ready
echo -e "${BLUE}⏳ Waiting for PostgreSQL to be ready...${NC}"
while ! docker exec realoss-postgres-prod pg_isready -U gogs -d gogs; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

# Install systemd services
echo -e "${BLUE}⚙️  Installing systemd services...${NC}"
cp systemd/4realoss.service /etc/systemd/system/
cp systemd/4realoss-ipfs.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable 4realoss-ipfs
systemctl enable 4realoss

# Configure firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw --force enable
    echo -e "${GREEN}✅ Firewall configured${NC}"
fi

# Install fail2ban for additional security
if command -v apt-get &> /dev/null; then
    echo -e "${BLUE}🛡️  Installing fail2ban...${NC}"
    apt-get update
    apt-get install -y fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    echo -e "${GREEN}✅ fail2ban installed${NC}"
fi

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

echo -e "${GREEN}✅ 4REALOSS Secure Production Installation Complete!${NC}"
echo ""
echo "Security features enabled:"
echo "- ✅ Dedicated 'realoss' system user"
echo "- ✅ Restricted file permissions"
echo "- ✅ PostgreSQL bound to localhost only"
echo "- ✅ IPFS API restricted to localhost"
echo "- ✅ Strong SSL/TLS configuration"
echo "- ✅ Security headers enabled"
echo "- ✅ Rate limiting configured"
echo "- ✅ Firewall configured (UFW)"
echo "- ✅ fail2ban installed"
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

chmod +x "$LOCAL_BUILD_DIR/install-production-secure.sh"

echo -e "${GREEN}✅ Secure production package built successfully${NC}"
echo -e "${BLUE}📦 Package location: $LOCAL_BUILD_DIR${NC}"
echo ""
echo -e "${GREEN}🔒 Security improvements:${NC}"
echo "- Dedicated 'realoss' system user (no root execution)"
echo "- Strong random passwords generated"
echo "- PostgreSQL restricted to localhost"
echo "- Enhanced security headers"
echo "- Rate limiting configured"
echo "- Systemd security hardening"
echo "- Firewall and fail2ban integration"
echo ""

# Save the generated passwords for reference
echo -e "${YELLOW}📝 Generated credentials (save these securely):${NC}"
echo "Database Password: $DB_PASSWORD"
echo "Secret Key: $SECRET_KEY"
echo ""

# Step 2: Deploy to VPS
echo -e "${CYAN}🚀 Step 2: Deploying to VPS (Secure)${NC}"
echo "====================================="

echo -e "${YELLOW}⚠️  Before deployment, please:${NC}"
echo "1. Ensure SSH key authentication is set up"
echo "2. Update DNS to point to your VPS IP"
echo "3. Save the generated passwords above"
echo ""

read -p "Continue with secure deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    echo "To deploy later, run: $0 with the same configuration"
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
"

# Upload files
rsync -avz --progress "$LOCAL_BUILD_DIR/" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/"

# Run installation script
echo -e "${BLUE}🔧 Running secure installation on VPS...${NC}"
ssh "$VPS_USER@$VPS_HOST" "cd '$DEPLOY_PATH' && sudo ./install-production-secure.sh"

echo -e "${GREEN}🎉 Secure Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Set up SSL certificate: ssh $VPS_USER@$VPS_HOST 'sudo certbot --nginx -d 4realoss.com -d www.4realoss.com'"
echo "2. Check service status: ssh $VPS_USER@$VPS_HOST 'systemctl status 4realoss'"
echo "3. Monitor logs: ssh $VPS_USER@$VPS_HOST 'journalctl -u 4realoss -f'"
echo "4. Visit your site: https://4realoss.com"
echo ""
echo -e "${BLUE}🔒 Security monitoring:${NC}"
echo "- Check fail2ban: ssh $VPS_USER@$VPS_HOST 'fail2ban-client status'"
echo "- Monitor firewall: ssh $VPS_USER@$VPS_HOST 'ufw status'"
echo "- Review security logs: ssh $VPS_USER@$VPS_HOST 'journalctl -f | grep -i security'"