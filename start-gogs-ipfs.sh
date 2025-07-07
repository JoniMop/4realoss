#!/bin/bash

# Gogs + IPFS Startup Script
# This script starts IPFS daemon and Gogs web server with proper configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IPFS_API_PORT=5002
IPFS_GATEWAY_PORT=8081
GOGS_PORT=3000
LOG_DIR="$GOGS_DIR/logs"

# Create logs directory
mkdir -p "$LOG_DIR"

echo -e "${BLUE}🚀 Starting Gogs + IPFS Stack${NC}"
echo "================================================"

# Function to check if a port is in use
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $port is already in use by another process${NC}"
        echo "   This might interfere with $service"
        echo "   You can kill the process with: sudo lsof -ti:$port | xargs kill -9"
        return 1
    fi
    return 0
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    
    echo -e "\n${RED}❌ $service_name failed to start within $max_attempts seconds${NC}"
    return 1
}

# Function to cleanup processes on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down services...${NC}"
    
    # Kill Gogs
    if pgrep -f "gogs web" >/dev/null; then
        echo "Stopping Gogs web server..."
        pkill -f "gogs web" || true
    fi
    
    # Kill IPFS
    if pgrep -f "ipfs daemon" >/dev/null; then
        echo "Stopping IPFS daemon..."
        pkill -f "ipfs daemon" || true
    fi
    
    echo -e "${GREEN}✅ Services stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if we're in the right directory
if [ ! -f "$GOGS_DIR/gogs" ]; then
    echo -e "${RED}❌ Gogs binary not found. Please run 'go build -o gogs .' first${NC}"
    exit 1
fi

# Check port availability
echo -e "${BLUE}🔍 Checking port availability...${NC}"
check_port $IPFS_API_PORT "IPFS API"
check_port $IPFS_GATEWAY_PORT "IPFS Gateway"
check_port $GOGS_PORT "Gogs Web Server"

# Configure IPFS CORS settings
echo -e "${BLUE}⚙️  Configuring IPFS CORS settings...${NC}"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' 2>/dev/null || {
    echo -e "${RED}❌ Failed to configure IPFS CORS. Is IPFS installed?${NC}"
    exit 1
}
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]' 2>/dev/null
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Content-Type"]' 2>/dev/null

# Start IPFS daemon
echo -e "${BLUE}🌐 Starting IPFS daemon...${NC}"
ipfs daemon > "$LOG_DIR/ipfs.log" 2>&1 &
IPFS_PID=$!
echo "IPFS daemon started with PID: $IPFS_PID"

# Wait for IPFS to be ready
if ! wait_for_service "http://127.0.0.1:$IPFS_API_PORT/api/v0/version" "IPFS API"; then
    echo -e "${RED}❌ IPFS daemon failed to start${NC}"
    cleanup
    exit 1
fi

# Build Gogs if needed
echo -e "${BLUE}🔨 Building Gogs...${NC}"
if ! go build -o gogs .; then
    echo -e "${RED}❌ Failed to build Gogs${NC}"
    cleanup
    exit 1
fi

# Start Gogs web server
echo -e "${BLUE}🚀 Starting Gogs web server...${NC}"
./gogs web > "$LOG_DIR/gogs.log" 2>&1 &
GOGS_PID=$!
echo "Gogs web server started with PID: $GOGS_PID"

# Wait for Gogs to be ready
if ! wait_for_service "http://127.0.0.1:$GOGS_PORT" "Gogs Web Server"; then
    echo -e "${RED}❌ Gogs web server failed to start${NC}"
    cleanup
    exit 1
fi

# Display status
echo ""
echo -e "${GREEN}🎉 All services are running successfully!${NC}"
echo "================================================"
echo -e "${GREEN}✅ IPFS Daemon:${NC}"
echo "   - API: http://127.0.0.1:$IPFS_API_PORT"
echo "   - Gateway: http://127.0.0.1:$IPFS_GATEWAY_PORT"
echo "   - Web UI: http://127.0.0.1:$IPFS_API_PORT/webui"
echo "   - Log: $LOG_DIR/ipfs.log"
echo ""
echo -e "${GREEN}✅ Gogs Web Server:${NC}"
echo "   - URL: http://127.0.0.1:$GOGS_PORT"
echo "   - Log: $LOG_DIR/gogs.log"
echo ""
echo -e "${BLUE}📋 Process IDs:${NC}"
echo "   - IPFS PID: $IPFS_PID"
echo "   - Gogs PID: $GOGS_PID"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "   - Press Ctrl+C to stop all services"
echo "   - View logs: tail -f $LOG_DIR/ipfs.log"
echo "   - View logs: tail -f $LOG_DIR/gogs.log"
echo "   - IPFS files uploaded via the web interface will be accessible at:"
echo "     https://ipfs.io/ipfs/[hash] (public gateway)"
echo "     http://127.0.0.1:$IPFS_GATEWAY_PORT/ipfs/[hash] (local gateway)"
echo ""
echo -e "${GREEN}🔗 Quick Links:${NC}"
echo "   - Gogs: http://127.0.0.1:$GOGS_PORT"
echo "   - IPFS Web UI: http://127.0.0.1:$IPFS_API_PORT/webui"
echo ""
echo -e "${BLUE}⏳ Services are running... Press Ctrl+C to stop${NC}"

# Keep the script running and monitor processes
while true; do
    sleep 5
    
    # Check if IPFS is still running
    if ! kill -0 $IPFS_PID 2>/dev/null; then
        echo -e "${RED}❌ IPFS daemon has stopped unexpectedly${NC}"
        cleanup
        exit 1
    fi
    
    # Check if Gogs is still running
    if ! kill -0 $GOGS_PID 2>/dev/null; then
        echo -e "${RED}❌ Gogs web server has stopped unexpectedly${NC}"
        cleanup
        exit 1
    fi
done 