#!/bin/bash

# Gogs + IPFS + PostgreSQL Status Script
# This script checks the status of all services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

POSTGRES_CONTAINER="gogs-postgres-dev"

echo -e "${BLUE}📊 Gogs + PostgreSQL + IPFS Status Check${NC}"
echo "================================================"

# Function to check service status
check_service() {
    local service_name=$1
    local process_pattern=$2
    local port=$3
    local test_url=$4
    
    echo -e "${BLUE}🔍 Checking $service_name...${NC}"
    
    # Check if process is running
    if pgrep -f "$process_pattern" >/dev/null; then
        local pid=$(pgrep -f "$process_pattern")
        echo -e "   ${GREEN}✅ Process running (PID: $pid)${NC}"
        
        # Check if port is listening
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Port $port is listening${NC}"
            
            # Check if service responds
            if [ -n "$test_url" ] && curl -s "$test_url" >/dev/null 2>&1; then
                echo -e "   ${GREEN}✅ Service responding at $test_url${NC}"
                return 0
            elif [ -n "$test_url" ]; then
                echo -e "   ${RED}❌ Service not responding at $test_url${NC}"
                return 1
            else
                return 0
            fi
        else
            echo -e "   ${RED}❌ Port $port is not listening${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Process not running${NC}"
        return 1
    fi
}

# Function to check PostgreSQL container
check_postgres() {
    echo -e "${BLUE}🔍 Checking PostgreSQL Container...${NC}"
    
    if docker ps | grep -q $POSTGRES_CONTAINER; then
        echo -e "   ${GREEN}✅ Container running${NC}"
        
        # Check if PostgreSQL is ready
        if docker exec $POSTGRES_CONTAINER pg_isready -U gogs -d gogs >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Database accepting connections${NC}"
            
            # Get database info
            local db_info=$(docker exec $POSTGRES_CONTAINER psql -U gogs -d gogs -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
            if [ -n "$db_info" ]; then
                echo -e "   ${GREEN}✅ Database query successful${NC}"
                echo -e "   ${BLUE}ℹ️  Version: ${db_info:0:50}...${NC}"
            fi
            return 0
        else
            echo -e "   ${RED}❌ Database not accepting connections${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Container not running${NC}"
        return 1
    fi
}

# Check PostgreSQL
postgres_status=0
if check_postgres; then
    postgres_status=1
    echo -e "   ${GREEN}🌐 Database: localhost:5432${NC}"
    echo -e "   ${GREEN}📊 Management: docker exec -it $POSTGRES_CONTAINER psql -U gogs -d gogs${NC}"
fi

echo ""

# Check IPFS daemon
ipfs_status=0
if check_service "IPFS Daemon" "ipfs daemon" 5002 "http://127.0.0.1:5002/api/v0/version"; then
    ipfs_status=1
    echo -e "   ${GREEN}🌐 IPFS Gateway: http://127.0.0.1:8081${NC}"
    echo -e "   ${GREEN}🎛️  IPFS Web UI: http://127.0.0.1:5002/webui${NC}"
fi

echo ""

# Check Gogs web server
gogs_status=0
if check_service "Gogs Web Server" "gogs web" 3000 "http://127.0.0.1:3000"; then
    gogs_status=1
    echo -e "   ${GREEN}🌐 Gogs Web Interface: http://127.0.0.1:3000${NC}"
fi

echo ""

# Check optional pgAdmin
echo -e "${BLUE}🔍 Checking pgAdmin (optional)...${NC}"
if docker ps | grep -q "gogs-pgadmin-dev"; then
    echo -e "   ${GREEN}✅ pgAdmin running at http://127.0.0.1:8080${NC}"
    echo -e "   ${BLUE}ℹ️  Login: admin@gogs.local / admin${NC}"
else
    echo -e "   ${YELLOW}⚠️  pgAdmin not running (optional)${NC}"
    echo -e "   ${BLUE}💡 Start with: docker compose -f docker-compose.dev.yml --profile tools up -d pgadmin${NC}"
fi

echo ""
echo "================================================"

# Overall status
total_services=$((postgres_status + ipfs_status + gogs_status))

if [ $total_services -eq 3 ]; then
    echo -e "${GREEN}🎉 All services are running properly!${NC}"
    echo ""
    echo -e "${GREEN}🔗 Quick Links:${NC}"
    echo "   - Gogs: http://127.0.0.1:3000"
    echo "   - IPFS Web UI: http://127.0.0.1:5002/webui"
    echo "   - IPFS Gateway: http://127.0.0.1:8081"
    echo "   - PostgreSQL: localhost:5432"
    echo ""
    echo -e "${YELLOW}💡 Management Commands:${NC}"
    echo "   - View Gogs logs: tail -f logs/gogs.log"
    echo "   - View IPFS logs: tail -f logs/ipfs.log"
    echo "   - View PostgreSQL logs: docker logs $POSTGRES_CONTAINER"
    echo "   - Connect to database: docker exec -it $POSTGRES_CONTAINER psql -U gogs -d gogs"
    echo "   - Stop services: ./stop-gogs-postgres.sh"
    exit 0
elif [ $total_services -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Some services are running, but not all${NC}"
    echo ""
    if [ $postgres_status -eq 0 ]; then
        echo -e "${RED}❌ PostgreSQL is not running${NC}"
    fi
    if [ $ipfs_status -eq 0 ]; then
        echo -e "${RED}❌ IPFS is not running${NC}"
    fi
    if [ $gogs_status -eq 0 ]; then
        echo -e "${RED}❌ Gogs is not running${NC}"
    fi
    echo ""
    echo -e "${BLUE}💡 To start all services: ./start-gogs-postgres.sh${NC}"
    exit 1
else
    echo -e "${RED}❌ No services are running${NC}"
    echo ""
    echo -e "${BLUE}💡 To start all services: ./start-gogs-postgres.sh${NC}"
    exit 1
fi