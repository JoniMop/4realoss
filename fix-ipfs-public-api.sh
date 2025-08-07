#!/bin/bash
# Fix IPFS template to use public VPS IP instead of localhost

echo "🔧 Updating IPFS template to use VPS public IP..."

# Replace localhost with VPS IP address in the template
sed -i 's|http://127.0.0.1:5002|http://164.92.110.168:5002|g' /opt/4realoss/templates/repo/header.tmpl

# Also update the local gateway reference
sed -i 's|http://127.0.0.1:8081|http://164.92.110.168:8081|g' /opt/4realoss/templates/repo/header.tmpl

echo "✅ Updated IPFS API endpoints to use public VPS IP"

# Configure IPFS to bind to all interfaces (already done, but let's ensure it)
/usr/local/bin/ipfs config Addresses.API /ip4/0.0.0.0/tcp/5002
/usr/local/bin/ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8081

echo "✅ IPFS configured to listen on all interfaces"

# Restart services to apply changes
systemctl restart 4realoss-ipfs
systemctl restart 4realoss

echo "✅ Services restarted"
echo ""
echo "🧪 Browser should now access IPFS API at: http://164.92.110.168:5002"
echo "🧪 Public gateway available at: http://164.92.110.168:8081"