#!/bin/bash

# Gogs + IPFS Status Script
# This script checks the status of IPFS daemon and Gogs web server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Gogs + IPFS Status Check${NC}"
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
echo "================================================"

# Overall status
if [ $ipfs_status -eq 1 ] && [ $gogs_status -eq 1 ]; then
    echo -e "${GREEN}🎉 All services are running properly!${NC}"
    echo ""
    echo -e "${GREEN}🔗 Quick Links:${NC}"
    echo "   - Gogs: http://127.0.0.1:3000"
    echo "   - IPFS Web UI: http://127.0.0.1:5002/webui"
    echo "   - IPFS Gateway: http://127.0.0.1:8081"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "   - View logs: tail -f logs/gogs.log"
    echo "   - View logs: tail -f logs/ipfs.log"
    echo "   - Stop services: ./stop-gogs-ipfs.sh"
    exit 0
elif [ $ipfs_status -eq 1 ] || [ $gogs_status -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Some services are running, but not all${NC}"
    echo ""
    if [ $ipfs_status -eq 0 ]; then
        echo -e "${RED}❌ IPFS is not running${NC}"
    fi
    if [ $gogs_status -eq 0 ]; then
        echo -e "${RED}❌ Gogs is not running${NC}"
    fi
    echo ""
    echo -e "${BLUE}💡 To start all services: ./start-gogs-ipfs.sh${NC}"
    exit 1
else
    echo -e "${RED}❌ No services are running${NC}"
    echo ""
    echo -e "${BLUE}💡 To start all services: ./start-gogs-ipfs.sh${NC}"
    exit 1
fi 