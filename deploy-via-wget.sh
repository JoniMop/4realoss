#!/bin/bash

# Simple deployment method - run this on your VPS directly
# This downloads and runs the update

echo "🚀 4REALOSS Production Update (Direct Method)"
echo "============================================="

# Create temp directory
mkdir -p /tmp/4realoss-update
cd /tmp/4realoss-update

# Download the update files (you'll need to serve these temporarily)
echo "📥 This method requires the update files to be available via HTTP"
echo "Alternative: Copy the files manually as shown below"
echo ""

cat << 'MANUAL_COPY_INSTRUCTIONS'
MANUAL COPY METHOD:
===================

1. On your local machine, copy this file to your VPS:
   scp ./build-production-update/run-update.sh root@164.92.110.168:/tmp/

2. Copy the binary:
   scp ./build-production-update/realoss root@164.92.110.168:/tmp/

3. Copy directories:
   scp -r ./build-production-update/templates root@164.92.110.168:/tmp/
   scp -r ./build-production-update/public root@164.92.110.168:/tmp/
   scp -r ./build-production-update/conf root@164.92.110.168:/tmp/

4. Then on your VPS, run:
   cd /tmp
   chmod +x run-update.sh
   ./run-update.sh

MANUAL_COPY_INSTRUCTIONS

echo ""
echo "OR use the simple one-liner update script below:"
echo ""