#!/bin/bash
# Fix IPFS integration in production template

echo "🔧 Fixing IPFS integration..."

# Update the template to use local IPFS instead of placeholder Pinata keys
sed -i "s/const PINATA_API_KEY = 'YOUR_PINATA_API_KEY_HERE';/const PINATA_API_KEY = ''; \/\/ Using local IPFS instead/g" /opt/4realoss/templates/repo/header.tmpl
sed -i "s/const PINATA_SECRET = 'YOUR_PINATA_SECRET_HERE';/const PINATA_SECRET = ''; \/\/ Using local IPFS instead/g" /opt/4realoss/templates/repo/header.tmpl

echo "✅ IPFS template updated to use local IPFS node"
echo "🔄 Restart 4REALOSS to apply changes"
systemctl restart 4realoss

echo "✅ 4REALOSS restarted - IPFS integration should now work!"
echo ""
echo "Test by:"
echo "1. Create a new repository on https://4realoss.com"
echo "2. The IPFS hash should now be real and accessible"