#!/bin/bash

# Update Favicon Only - Simple approach for production
echo "🎨 4RealOSS Favicon Update"
echo "=========================="
echo "This script will help you update just the favicon files on production"
echo ""

echo "🔧 Here are the manual steps to update your favicon:"
echo ""
echo "1. Copy the new favicon files to your VPS:"
echo "   scp public/img/favicon.png root@164.92.110.168:/opt/4realoss/public/img/"
echo "   scp public/img/favicon-16.png root@164.92.110.168:/opt/4realoss/public/img/"
echo "   scp public/img/favicon.ico root@164.92.110.168:/opt/4realoss/public/img/"
echo ""
echo "2. Update the head template:"
echo "   scp templates/base/head.tmpl root@164.92.110.168:/opt/4realoss/templates/base/"
echo ""
echo "3. Restart the 4REALOSS service:"
echo "   ssh root@164.92.110.168 'systemctl restart 4realoss'"
echo ""
echo "4. Clear your browser cache and visit https://4realoss.com"
echo ""

# Alternative: Try to upload via SSH with timeout
echo "🚀 Or run these commands in your terminal:"
echo ""

cat << 'COMMANDS'
# Upload favicon files
scp public/img/favicon.png root@164.92.110.168:/opt/4realoss/public/img/
scp public/img/favicon-16.png root@164.92.110.168:/opt/4realoss/public/img/
scp public/img/favicon.ico root@164.92.110.168:/opt/4realoss/public/img/

# Upload updated head template
scp templates/base/head.tmpl root@164.92.110.168:/opt/4realoss/templates/base/

# Restart service
ssh root@164.92.110.168 'chown gogs:gogs /opt/4realoss/public/img/favicon* && chown gogs:gogs /opt/4realoss/templates/base/head.tmpl && systemctl restart 4realoss'
COMMANDS

echo ""
echo "✨ After running these commands:"
echo "1. Clear your browser cache completely (Ctrl+Shift+Delete)"
echo "2. Visit https://4realoss.com"
echo "3. You should see the new 4RealOSS '4R' favicon instead of the old Gogs 'G'"
echo ""
echo "🎯 The new favicon shows '4R' in a purple circle, representing 4RealOSS branding!"