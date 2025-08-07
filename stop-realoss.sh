#!/bin/bash

# 4REALOSS - Stop All Services Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🛑 4REALOSS - Stopping All Services${NC}"
echo -e "${PURPLE}===================================${NC}"
echo ""

# Stop 4REALOSS web server
echo -e "${BLUE}🔥 Stopping 4REALOSS web server...${NC}"
if pgrep -f "./realoss web" > /dev/null; then
    pkill -f "./realoss web" && echo -e "${GREEN}✅ 4REALOSS web server stopped${NC}"
else
    echo -e "${YELLOW}⚠️  4REALOSS web server not running${NC}"
fi

# Stop IPFS daemon
echo -e "${BLUE}🌍 Stopping IPFS daemon...${NC}"
if pgrep -f "ipfs daemon" > /dev/null; then
    pkill -f "ipfs daemon" && echo -e "${GREEN}✅ IPFS daemon stopped${NC}"
else
    echo -e "${YELLOW}⚠️  IPFS daemon not running${NC}"
fi

# Stop PostgreSQL container
echo -e "${BLUE}🐘 Stopping PostgreSQL container...${NC}"
if docker ps | grep -q "realoss-postgres-dev"; then
    docker stop realoss-postgres-dev && echo -e "${GREEN}✅ PostgreSQL container stopped${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL container not running${NC}"
fi

echo ""
echo -e "${GREEN}✅ All 4REALOSS services stopped${NC}"
echo ""
echo -e "${BLUE}💡 To completely remove PostgreSQL data:${NC}"
echo "   docker rm realoss-postgres-dev"
echo "   docker volume rm $(docker volume ls -q | grep postgres)"
echo ""
echo -e "${BLUE}💡 To restart everything:${NC}"
echo "   ./start-realoss.sh"