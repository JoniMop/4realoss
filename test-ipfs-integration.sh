#!/bin/bash

# Test script to verify IPFS integration with Gogs
# Run this after setting up IPFS to ensure everything works

set -e

# Colors for output  
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing IPFS Integration with Gogs${NC}"
echo "=========================================="

# Test 1: Check if IPFS is installed
echo -e "${BLUE}1. Checking IPFS installation...${NC}"
if command -v ipfs &> /dev/null; then
    echo -e "${GREEN}✅ IPFS is installed${NC}"
    ipfs version
else
    echo -e "${RED}❌ IPFS is not installed${NC}"
    echo "Run: ./setup-ipfs.sh to install"
    exit 1
fi

# Test 2: Check if IPFS daemon is running
echo -e "${BLUE}2. Checking IPFS daemon...${NC}"
if pgrep -f "ipfs daemon" > /dev/null; then
    echo -e "${GREEN}✅ IPFS daemon is running${NC}"
    echo "PID: $(pgrep -f 'ipfs daemon')"
else
    echo -e "${YELLOW}⚠️  IPFS daemon is not running${NC}"
    echo "Starting IPFS daemon..."
    if systemctl is-enabled ipfs &>/dev/null; then
        sudo systemctl start ipfs
        sleep 3
        if pgrep -f "ipfs daemon" > /dev/null; then
            echo -e "${GREEN}✅ IPFS daemon started${NC}"
        else
            echo -e "${RED}❌ Failed to start IPFS daemon${NC}"
            exit 1
        fi
    else
        echo "Start manually: ipfs daemon --enable-gc &"
        exit 1
    fi
fi

# Test 3: Check IPFS API accessibility
echo -e "${BLUE}3. Testing IPFS API (port 5002)...${NC}"
if curl -s http://127.0.0.1:5002/api/v0/version >/dev/null; then
    echo -e "${GREEN}✅ IPFS API is accessible${NC}"
    API_VERSION=$(curl -s http://127.0.0.1:5002/api/v0/version | grep -o '"Version":"[^"]*"' | cut -d'"' -f4)
    echo "API Version: $API_VERSION"
else
    echo -e "${RED}❌ IPFS API is not accessible on port 5002${NC}"
    echo "Expected: http://127.0.0.1:5002/api/v0/version"
    exit 1
fi

# Test 4: Check IPFS Gateway
echo -e "${BLUE}4. Testing IPFS Gateway (port 8081)...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8081/ | grep -q "200\|404"; then
    echo -e "${GREEN}✅ IPFS Gateway is accessible${NC}"
    echo "Gateway: http://127.0.0.1:8081/"
else
    echo -e "${RED}❌ IPFS Gateway is not accessible on port 8081${NC}"
    echo "Expected: http://127.0.0.1:8081/"
    exit 1  
fi

# Test 5: Test file upload and pinning
echo -e "${BLUE}5. Testing file upload and pinning...${NC}"
TEST_FILE="test-gogs-$(date +%s).txt"
TEST_CONTENT="Hello from Gogs IPFS integration test at $(date)"

echo "$TEST_CONTENT" > "$TEST_FILE"

# Upload to IPFS
echo "Uploading test file..."
IPFS_HASH=$(ipfs add -q --pin=true "$TEST_FILE")

if [ -n "$IPFS_HASH" ]; then
    echo -e "${GREEN}✅ File uploaded and pinned${NC}"
    echo "IPFS Hash: $IPFS_HASH"
    
    # Test retrieval via API
    echo "Testing retrieval via local API..."
    if curl -s "http://127.0.0.1:5002/api/v0/cat?arg=$IPFS_HASH" | grep -q "Hello from Gogs"; then
        echo -e "${GREEN}✅ File retrievable via API${NC}"
    else
        echo -e "${YELLOW}⚠️  File not immediately retrievable via API${NC}"
    fi
    
    # Test retrieval via gateway
    echo "Testing retrieval via local gateway..."
    if curl -s "http://127.0.0.1:8081/ipfs/$IPFS_HASH" | grep -q "Hello from Gogs"; then
        echo -e "${GREEN}✅ File retrievable via local gateway${NC}"
    else
        echo -e "${YELLOW}⚠️  File not immediately retrievable via gateway${NC}"
    fi
    
    # Announce to network
    echo "Announcing to IPFS network..."
    if ipfs dht provide "$IPFS_HASH" 2>/dev/null; then
        echo -e "${GREEN}✅ File announced to network${NC}" 
    else
        echo -e "${YELLOW}⚠️  Could not announce to network (this is normal for new nodes)${NC}"
    fi
    
    # Clean up
    rm "$TEST_FILE"
    ipfs pin rm "$IPFS_HASH" 2>/dev/null || true
    
else
    echo -e "${RED}❌ Failed to upload file to IPFS${NC}"
    rm "$TEST_FILE"
    exit 1
fi

# Test 6: Check Pinata configuration (if configured)
echo -e "${BLUE}6. Checking Pinata configuration...${NC}"
if grep -q "YOUR_PINATA_API_KEY_HERE" templates/repo/header.tmpl; then
    echo -e "${YELLOW}⚠️  Pinata API keys not configured${NC}"
    echo "Edit templates/repo/header.tmpl to add your Pinata keys for cloud backup"
else
    echo -e "${GREEN}✅ Pinata API keys are configured${NC}"
fi

echo ""
echo -e "${GREEN}🎉 IPFS Integration Test Complete!${NC}"
echo "=========================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • IPFS Daemon: ✅ Running on API port 5002"
echo "  • IPFS Gateway: ✅ Running on port 8081"
echo "  • File Upload/Pin: ✅ Working"
echo ""
echo -e "${BLUE}🌐 Next Steps:${NC}"
echo "  1. Restart Gogs: sudo systemctl restart your-gogs-service"
echo "  2. Or restart manually if running via script"
echo "  3. Try uploading a repository to IPFS from Gogs interface"
echo "  4. Files will be pinned locally and announced to the network"
echo ""
echo -e "${BLUE}🔗 Access URLs:${NC}"
echo "  • Gogs: http://127.0.0.1:3000"
echo "  • IPFS Gateway: http://127.0.0.1:8081/ipfs/HASH"
echo "  • Public Gateway: https://ipfs.io/ipfs/HASH"