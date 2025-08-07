#!/bin/bash
# Fix IPFS CORS to allow browser access

echo "🔧 Configuring IPFS CORS for browser access..."

# Stop IPFS daemon first
systemctl stop 4realoss-ipfs

# Configure CORS settings
/usr/local/bin/ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
/usr/local/bin/ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
/usr/local/bin/ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization"]'

# Also configure the API to listen on all interfaces (so 4realoss can access it)
/usr/local/bin/ipfs config Addresses.API /ip4/0.0.0.0/tcp/5002

echo "✅ IPFS CORS configured"

# Restart IPFS daemon
systemctl start 4realoss-ipfs

echo "✅ IPFS daemon restarted with CORS support"
echo "🧪 Browser should now be able to access IPFS API"