#!/bin/bash
# Fixed 4REALOSS Production Installation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing 4REALOSS Production Installation${NC}"
echo "=========================================="

# Install docker-compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BLUE}📦 Installing docker-compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ docker-compose installed${NC}"
fi

# Stop old services
echo -e "${BLUE}🛑 Stopping old services...${NC}"
systemctl stop gogs || true
systemctl stop 4realoss || true
systemctl stop 4realoss-ipfs || true
docker stop $(docker ps -q) || true

# Start PostgreSQL
echo -e "${BLUE}🐘 Starting PostgreSQL...${NC}"
docker-compose up -d postgres
sleep 10

# Wait for PostgreSQL to be ready
echo -e "${BLUE}⏳ Waiting for PostgreSQL...${NC}"
for i in {1..30}; do
    if docker exec realoss-postgres-prod pg_isready -U gogs -d gogs; then
        echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

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

# Check service status
echo -e "${BLUE}🔍 Checking service status...${NC}"
systemctl status 4realoss --no-pager -l
systemctl status 4realoss-ipfs --no-pager -l

echo -e "${GREEN}✅ 4REALOSS Production Installation Complete!${NC}"
echo ""
echo "Services:"
echo "- 4REALOSS: systemctl status 4realoss"
echo "- IPFS: systemctl status 4realoss-ipfs"
echo "- PostgreSQL: docker ps"
echo ""
echo "Test your site: curl -I http://localhost:3000"