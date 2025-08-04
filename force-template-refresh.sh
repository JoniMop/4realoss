#!/bin/bash

echo "🔄 Forcing template cache refresh..."

# Add timestamp to force browser cache invalidation
TIMESTAMP=$(date +%s)

# Update a visible console log to prove the template is fresh
sed -i "s/console.log('📂 View Files on IPFS:', directoryHash);/console.log('📂 View Files on IPFS [CACHE-BUST-$TIMESTAMP]:', directoryHash);/g" /opt/4realoss/templates/repo/header.tmpl

# Also update the fake hash generator with timestamp
sed -i "s/⚠️ Generated deterministic hash (NOT on IPFS):/⚠️ Generated deterministic hash [REFRESH-$TIMESTAMP] (NOT on IPFS):/g" /opt/4realoss/templates/repo/header.tmpl

# Restart service to reload templates
systemctl restart 4realoss

echo "✅ Template updated with timestamp: $TIMESTAMP"
echo "✅ 4REALOSS service restarted"
echo ""
echo "🧪 TEST STEPS:"
echo "1. Go to https://4realoss.com"
echo "2. Press Ctrl+Shift+R (hard refresh)"
echo "3. Open Console (F12)"
echo "4. Create repository"
echo "5. Look for console message with [$TIMESTAMP] to confirm fresh template"
echo ""
echo "If you still see old messages, the browser is EXTREMELY cached!"