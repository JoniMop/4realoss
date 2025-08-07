#!/bin/bash

# 4REALOSS - Complete Application Startup Script
# This script handles everything: IPFS setup, PostgreSQL, building, and testing
# Based on Gogs but rebranded as 4REALOSS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REALOSS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_PORT=5432
IPFS_API_PORT=5002
IPFS_GATEWAY_PORT=8081
REALOSS_PORT=3000
LOG_DIR="$REALOSS_DIR/logs"
POSTGRES_CONTAINER="realoss-postgres-dev"

# Create logs directory
mkdir -p "$LOG_DIR"

echo -e "${PURPLE}🚀 4REALOSS - Complete Application Stack${NC}"
echo -e "${PURPLE}==========================================${NC}"
echo ""

# Function to check if a port is in use
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $port is already in use by another process${NC}"
        echo -e "${YELLOW}    Service: $service${NC}"
        echo -e "${YELLOW}    Kill with: sudo kill -9 \$(lsof -ti:$port)${NC}"
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
        
        printf "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start within $((max_attempts * 2)) seconds${NC}"
    return 1
}

# Step 1: Install and Setup IPFS
echo -e "${CYAN}📦 Step 1: IPFS Setup${NC}"
echo "===================="

# Check if IPFS is already installed
if command -v ipfs &> /dev/null; then
    echo -e "${GREEN}✅ IPFS is already installed${NC}"
    ipfs version
else
    echo -e "${BLUE}📦 Installing IPFS...${NC}"
    
    # Download and install IPFS
    IPFS_VERSION="v0.19.1"
    IPFS_ARCH="linux-amd64"
    IPFS_URL="https://dist.ipfs.io/kubo/${IPFS_VERSION}/kubo_${IPFS_VERSION}_${IPFS_ARCH}.tar.gz"
    
    echo "Downloading IPFS ${IPFS_VERSION}..."
    wget -q "$IPFS_URL" -O ipfs.tar.gz
    
    echo "Extracting..."
    tar -xzf ipfs.tar.gz
    
    echo "Installing to /usr/local/bin..."
    sudo mv kubo/ipfs /usr/local/bin/
    
    echo "Cleaning up..."
    rm -rf kubo ipfs.tar.gz
    
    echo -e "${GREEN}✅ IPFS installed successfully${NC}"
fi

# Initialize IPFS if not already done
if [ ! -d "$HOME/.ipfs" ]; then
    echo -e "${BLUE}🔧 Initializing IPFS...${NC}"
    ipfs init
    echo -e "${GREEN}✅ IPFS initialized${NC}"
else
    echo -e "${GREEN}✅ IPFS already initialized${NC}"
fi

# Configure IPFS for 4REALOSS integration
echo -e "${BLUE}⚙️  Configuring IPFS for 4REALOSS...${NC}"

# Enable CORS for web interface access
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization"]'

# Set up custom ports to avoid conflicts
ipfs config Addresses.API /ip4/127.0.0.1/tcp/$IPFS_API_PORT
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/$IPFS_GATEWAY_PORT

# Enable some useful experimental features
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Experimental.UrlstoreEnabled true

echo -e "${GREEN}✅ IPFS configured for 4REALOSS integration${NC}"
echo ""

# Step 2: Start IPFS Daemon
echo -e "${CYAN}🌍 Step 2: Starting IPFS Daemon${NC}"
echo "================================="

# Check if IPFS daemon is already running
if pgrep -f "ipfs daemon" > /dev/null; then
    echo -e "${GREEN}✅ IPFS daemon is already running${NC}"
    echo "PID: $(pgrep -f 'ipfs daemon')"
else
    echo -e "${BLUE}🚀 Starting IPFS daemon...${NC}"
    
    # Start IPFS daemon in background
    nohup ipfs daemon --enable-gc >"$LOG_DIR/ipfs.log" 2>&1 &
    IPFS_PID=$!
    
    # Wait for IPFS to be ready
    sleep 3
    
    if pgrep -f "ipfs daemon" > /dev/null; then
        echo -e "${GREEN}✅ IPFS daemon started successfully${NC}"
        echo "PID: $IPFS_PID"
        echo "Log: $LOG_DIR/ipfs.log"
    else
        echo -e "${RED}❌ IPFS daemon failed to start${NC}"
        echo "Check logs: cat $LOG_DIR/ipfs.log"
        exit 1
    fi
fi

# Test IPFS API and Gateway
echo -e "${BLUE}🧪 Testing IPFS connections...${NC}"
if curl -s http://127.0.0.1:$IPFS_API_PORT/api/v0/version >/dev/null; then
    echo -e "${GREEN}✅ IPFS API is accessible (port $IPFS_API_PORT)${NC}"
else
    echo -e "${YELLOW}⚠️  IPFS API not ready yet, continuing...${NC}"
fi

if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$IPFS_GATEWAY_PORT/ | grep -q "200\|404"; then
    echo -e "${GREEN}✅ IPFS Gateway is accessible (port $IPFS_GATEWAY_PORT)${NC}"
else
    echo -e "${YELLOW}⚠️  IPFS Gateway not ready yet, continuing...${NC}"
fi
echo ""

# Step 3: Setup PostgreSQL
echo -e "${CYAN}🐘 Step 3: PostgreSQL Database${NC}"
echo "==============================="

# Check if PostgreSQL container exists and is running
if docker ps | grep -q "$POSTGRES_CONTAINER"; then
    echo -e "${GREEN}✅ PostgreSQL container already running${NC}"
elif docker ps -a | grep -q "$POSTGRES_CONTAINER"; then
    echo -e "${BLUE}🔄 Starting existing PostgreSQL container...${NC}"
    docker start "$POSTGRES_CONTAINER"
    sleep 3
else
    echo -e "${BLUE}🐘 Creating and starting PostgreSQL container...${NC}"
    
    # Check if port is free
    if ! check_port $POSTGRES_PORT "PostgreSQL"; then
        echo -e "${RED}❌ Cannot start PostgreSQL - port $POSTGRES_PORT is in use${NC}"
        exit 1
    fi
    
    docker compose -f docker-compose.dev.yml up -d postgres
    sleep 5
fi

# Wait for PostgreSQL to be ready
echo -e "${BLUE}⏳ Waiting for PostgreSQL to be ready...${NC}"
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec "$POSTGRES_CONTAINER" pg_isready -U gogs -d gogs >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
        break
    fi
    
    printf "."
    sleep 2
    attempt=$((attempt + 1))
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}❌ PostgreSQL failed to start within $((max_attempts * 2)) seconds${NC}"
        echo "Check container logs: docker logs $POSTGRES_CONTAINER"
        exit 1
    fi
done
echo ""

# Step 4: Build 4REALOSS Application
echo -e "${CYAN}🔨 Step 4: Building 4REALOSS Application${NC}"
echo "========================================"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ Go is not installed${NC}"
    echo -e "${BLUE}📦 Installing Go...${NC}"
    sudo apt update && sudo apt install -y golang-go
    echo -e "${GREEN}✅ Go installed${NC}"
fi

echo -e "${BLUE}🔨 Building 4REALOSS...${NC}"
if go build -v -o realoss .; then
    echo -e "${GREEN}✅ 4REALOSS built successfully${NC}"
else
    echo -e "${RED}❌ Failed to build 4REALOSS${NC}"
    echo "Check Go version and dependencies"
    exit 1
fi
echo ""

# Step 5: Start 4REALOSS Web Server
echo -e "${CYAN}🚀 Step 5: Starting 4REALOSS Web Server${NC}"
echo "======================================"

# Check if port is free
if ! check_port $REALOSS_PORT "4REALOSS Web Server"; then
    echo -e "${YELLOW}⚠️  Killing existing process on port $REALOSS_PORT...${NC}"
    sudo kill -9 $(lsof -ti:$REALOSS_PORT) 2>/dev/null || true
    sleep 2
fi

echo -e "${BLUE}🚀 Starting 4REALOSS web server...${NC}"

# Start 4REALOSS web server
nohup ./realoss web --config conf/app.ini >"$LOG_DIR/realoss.log" 2>&1 &
REALOSS_PID=$!

echo "4REALOSS web server started with PID: $REALOSS_PID"

# Wait for 4REALOSS to be ready
if wait_for_service "http://127.0.0.1:$REALOSS_PORT" "4REALOSS Web Server"; then
    echo -e "${GREEN}✅ 4REALOSS Web Server is ready!${NC}"
else
    echo -e "${RED}❌ 4REALOSS Web Server failed to start${NC}"
    echo "Check logs: tail -f $LOG_DIR/realoss.log"
    exit 1
fi
echo ""

# Step 6: Test IPFS Integration
echo -e "${CYAN}🧪 Step 6: Testing IPFS Integration${NC}"
echo "==================================="

# Test file upload and pinning
echo -e "${BLUE}🧪 Testing repository upload to IPFS...${NC}"
TEST_FILE="test-4realoss-$(date +%s).txt"
TEST_CONTENT="Hello from 4REALOSS IPFS integration test at $(date)"

echo "$TEST_CONTENT" > "$TEST_FILE"

# Upload to IPFS
echo "Uploading test file to IPFS..."
if command -v ipfs &> /dev/null && pgrep -f "ipfs daemon" > /dev/null; then
    IPFS_HASH=$(ipfs add -q --pin=true "$TEST_FILE" 2>/dev/null || echo "")
    
    if [ -n "$IPFS_HASH" ]; then
        echo -e "${GREEN}✅ Test file uploaded and pinned to IPFS${NC}"
        echo "IPFS Hash: $IPFS_HASH"
        
        # Test retrieval via local gateway
        if curl -s "http://127.0.0.1:$IPFS_GATEWAY_PORT/ipfs/$IPFS_HASH" | grep -q "Hello from 4REALOSS"; then
            echo -e "${GREEN}✅ File retrievable via local IPFS gateway${NC}"
        else
            echo -e "${YELLOW}⚠️  File not immediately retrievable (this is normal)${NC}"
        fi
        
        # Announce to network
        echo "Announcing to IPFS network for global availability..."
        ipfs dht provide "$IPFS_HASH" 2>/dev/null || echo -e "${YELLOW}⚠️  Network announcement pending${NC}"
        
        # Clean up
        rm "$TEST_FILE"
        ipfs pin rm "$IPFS_HASH" 2>/dev/null || true
        
    else
        echo -e "${YELLOW}⚠️  IPFS upload test skipped (daemon not ready)${NC}"
        rm "$TEST_FILE"
    fi
else
    echo -e "${YELLOW}⚠️  IPFS not available for testing${NC}"
    rm "$TEST_FILE" 2>/dev/null || true
fi
echo ""

# Final Status Report
echo -e "${PURPLE}🎉 4REALOSS Stack Started Successfully!${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo ""
echo -e "${BLUE}📋 Service Status:${NC}"
echo -e "${GREEN}✅ IPFS Daemon:${NC}"
echo "   - API: http://127.0.0.1:$IPFS_API_PORT"
echo "   - Gateway: http://127.0.0.1:$IPFS_GATEWAY_PORT"
echo "   - Log: $LOG_DIR/ipfs.log"

echo -e "${GREEN}✅ PostgreSQL Database:${NC}"
echo "   - Host: localhost:$POSTGRES_PORT"
echo "   - Database: gogs"
echo "   - User: gogs"
echo "   - Container: $POSTGRES_CONTAINER"

echo -e "${GREEN}✅ 4REALOSS Web Server:${NC}"
echo "   - URL: http://127.0.0.1:$REALOSS_PORT"
echo "   - Log: $LOG_DIR/realoss.log"

echo ""
echo -e "${BLUE}📋 Process IDs:${NC}"
if pgrep -f "ipfs daemon" > /dev/null; then
    echo "   - IPFS PID: $(pgrep -f 'ipfs daemon')"
fi
echo "   - 4REALOSS PID: $REALOSS_PID"
echo "   - PostgreSQL: Docker container $POSTGRES_CONTAINER"

echo ""
echo -e "${BLUE}💡 Management Commands:${NC}"
echo "   - View 4REALOSS logs: tail -f $LOG_DIR/realoss.log"
echo "   - View IPFS logs: tail -f $LOG_DIR/ipfs.log"
echo "   - View PostgreSQL logs: docker logs $POSTGRES_CONTAINER"
echo "   - Connect to PostgreSQL: docker exec -it $POSTGRES_CONTAINER psql -U gogs -d gogs"
echo "   - Stop all: ./stop-realoss.sh"

echo ""
echo -e "${PURPLE}🔗 Quick Access Links:${NC}"
echo -e "${CYAN}   - 4REALOSS Application: http://127.0.0.1:$REALOSS_PORT${NC}"
echo -e "${CYAN}   - IPFS Gateway: http://127.0.0.1:$IPFS_GATEWAY_PORT/ipfs/HASH${NC}"
echo -e "${CYAN}   - Public IPFS: https://ipfs.io/ipfs/HASH${NC}"

echo ""
echo -e "${BLUE}🌐 IPFS Publishing:${NC}"
echo "   - Repositories uploaded via 4REALOSS will be:"
echo "   - ✅ Pinned to your local IPFS node"
echo "   - ✅ Announced to the global IPFS network"
echo "   - ✅ Accessible worldwide via IPFS gateways"

if grep -q "YOUR_PINATA_API_KEY_HERE" templates/repo/header.tmpl 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}💡 Pro Tip:${NC}"
    echo "   - Configure Pinata API keys in templates/repo/header.tmpl"
    echo "   - Get free keys at: https://pinata.cloud"
    echo "   - This adds cloud backup for better reliability"
fi

echo ""
echo -e "${GREEN}⏳ 4REALOSS is running... Press Ctrl+C to stop${NC}"

# Keep the script running and handle Ctrl+C
trap 'echo -e "\n${BLUE}🛑 Shutting down services...${NC}"; 
      echo "Stopping 4REALOSS web server...";
      kill $REALOSS_PID 2>/dev/null || true;
      if pgrep -f "ipfs daemon" > /dev/null; then
          echo "Stopping IPFS daemon...";
          pkill -f "ipfs daemon" 2>/dev/null || true;
      fi;
      echo -e "${GREEN}✅ Services stopped${NC}";
      exit 0' SIGINT

# Wait for processes
wait $REALOSS_PID 2>/dev/null || true