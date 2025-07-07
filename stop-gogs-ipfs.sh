#!/bin/bash

# Gogs + IPFS Stop Script
# This script stops IPFS daemon and Gogs web server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping Gogs + IPFS Stack${NC}"
echo "================================================"

# Function to stop a service
stop_service() {
    local service_name=$1
    local process_pattern=$2
    
    if pgrep -f "$process_pattern" >/dev/null; then
        echo -e "${YELLOW}Stopping $service_name...${NC}"
        pkill -f "$process_pattern"
        
        # Wait for process to stop
        local attempts=0
        while pgrep -f "$process_pattern" >/dev/null && [ $attempts -lt 10 ]; do
            sleep 1
            ((attempts++))
        done
        
        if pgrep -f "$process_pattern" >/dev/null; then
            echo -e "${RED}⚠️  $service_name didn't stop gracefully, forcing shutdown...${NC}"
            pkill -9 -f "$process_pattern"
        fi
        
        echo -e "${GREEN}✅ $service_name stopped${NC}"
    else
        echo -e "${YELLOW}ℹ️  $service_name is not running${NC}"
    fi
}

# Stop Gogs web server
stop_service "Gogs Web Server" "gogs web"

# Stop IPFS daemon
stop_service "IPFS Daemon" "ipfs daemon"

echo ""
echo -e "${GREEN}🎉 All services have been stopped!${NC}"
echo "================================================" 