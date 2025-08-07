#!/bin/bash

# Gogs + IPFS + PostgreSQL Stop Script
# This script stops all services: Gogs, IPFS, and PostgreSQL

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

POSTGRES_CONTAINER="gogs-postgres-dev"

echo -e "${BLUE}🛑 Stopping Gogs + PostgreSQL + IPFS Stack${NC}"
echo "================================================"

# Stop Gogs web server
echo -e "${BLUE}🔍 Stopping Gogs web server...${NC}"
if pgrep -f "gogs web" >/dev/null; then
    pkill -f "gogs web"
    echo -e "${GREEN}✅ Gogs web server stopped${NC}"
else
    echo -e "${YELLOW}⚠️  Gogs web server was not running${NC}"
fi

# Stop IPFS daemon
echo -e "${BLUE}🔍 Stopping IPFS daemon...${NC}"
if pgrep -f "ipfs daemon" >/dev/null; then
    pkill -f "ipfs daemon"
    echo -e "${GREEN}✅ IPFS daemon stopped${NC}"
else
    echo -e "${YELLOW}⚠️  IPFS daemon was not running${NC}"
fi

# Stop PostgreSQL container
echo -e "${BLUE}🔍 Stopping PostgreSQL container...${NC}"
if docker ps | grep -q $POSTGRES_CONTAINER; then
    docker stop $POSTGRES_CONTAINER
    echo -e "${GREEN}✅ PostgreSQL container stopped${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL container was not running${NC}"
fi

# Optional: Stop pgAdmin if running
if docker ps | grep -q "gogs-pgadmin-dev"; then
    echo -e "${BLUE}🔍 Stopping pgAdmin container...${NC}"
    docker stop gogs-pgadmin-dev
    echo -e "${GREEN}✅ pgAdmin container stopped${NC}"
fi

echo ""
echo -e "${GREEN}🎉 All services stopped successfully!${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "   - To remove PostgreSQL data: docker compose -f docker-compose.dev.yml down -v"
echo "   - To start services again: ./start-gogs-postgres.sh"
echo "   - To check status: ./status-gogs-postgres.sh"