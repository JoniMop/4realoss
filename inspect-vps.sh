#!/bin/bash

# VPS Inspection Script - Run this on your VPS to check current state
# Usage: ssh root@164.92.110.168 'bash -s' < inspect-vps.sh

echo "🔍 4REALOSS VPS Inspection Report"
echo "=================================="
echo "Date: $(date)"
echo "Server: $(hostname)"
echo ""

echo "📊 System Information"
echo "--------------------"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime | cut -d',' -f1)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "💾 Disk Usage"
echo "-------------"
df -h / /opt 2>/dev/null | head -3
echo ""

echo "🗂️  Current Directory Structure"
echo "------------------------------"
echo "Checking for existing installations..."
echo ""

if [ -d "/opt/gogs" ]; then
    echo "✅ Found OLD Gogs installation at /opt/gogs"
    ls -la /opt/gogs/ | head -10
    echo ""
    
    if [ -f "/opt/gogs/gogs" ]; then
        echo "Binary: $(/opt/gogs/gogs --version 2>/dev/null || echo 'Not executable')"
    fi
    echo ""
fi

if [ -d "/opt/4realoss" ]; then
    echo "✅ Found 4REALOSS installation at /opt/4realoss"
    ls -la /opt/4realoss/ | head -10
    echo ""
    
    if [ -f "/opt/4realoss/realoss" ]; then
        echo "Binary: $(/opt/4realoss/realoss --version 2>/dev/null || echo 'Not executable')"
    fi
    echo ""
fi

echo "🐳 Docker Status"
echo "---------------"
if command -v docker &> /dev/null; then
    echo "Docker version: $(docker --version)"
    echo ""
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running or docker not accessible"
    echo ""
    echo "All containers:"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo "No containers found"
else
    echo "❌ Docker not installed"
fi
echo ""

echo "🔧 Services Status"
echo "------------------"
echo "Checking systemd services..."
for service in gogs 4realoss 4realoss-ipfs nginx postgresql; do
    if systemctl list-unit-files | grep -q "^$service.service"; then
        status=$(systemctl is-active $service 2>/dev/null || echo "not-found")
        enabled=$(systemctl is-enabled $service 2>/dev/null || echo "not-found")
        echo "$service: $status ($enabled)"
    else
        echo "$service: not installed"
    fi
done
echo ""

echo "🌐 Network Services"
echo "------------------"
echo "Listening ports:"
netstat -tlnp 2>/dev/null | grep -E ':(80|443|3000|5432|8080|5002|8081)' || echo "netstat not available, trying ss..."
ss -tlnp 2>/dev/null | grep -E ':(80|443|3000|5432|8080|5002|8081)' || echo "No relevant ports found"
echo ""

echo "🗃️  Database Status"
echo "------------------"
if command -v psql &> /dev/null; then
    echo "PostgreSQL client installed"
    if systemctl is-active postgresql &>/dev/null; then
        echo "PostgreSQL service: active"
    else
        echo "PostgreSQL service: not active or not installed"
    fi
else
    echo "PostgreSQL client not installed"
fi

# Check for SQLite databases
echo ""
echo "SQLite databases found:"
find /opt -name "*.db" 2>/dev/null | head -5 || echo "None found"
echo ""

echo "📂 Configuration Files"
echo "----------------------"
echo "Checking for configuration files..."

if [ -f "/opt/gogs/custom/conf/app.ini" ]; then
    echo "✅ Found OLD Gogs config: /opt/gogs/custom/conf/app.ini"
    echo "Database type: $(grep -E '^TYPE' /opt/gogs/custom/conf/app.ini | head -1)"
    echo "External URL: $(grep -E '^EXTERNAL_URL' /opt/gogs/custom/conf/app.ini | head -1)"
fi

if [ -f "/opt/4realoss/conf/app.ini" ]; then
    echo "✅ Found 4REALOSS config: /opt/4realoss/conf/app.ini"
    echo "Database type: $(grep -E '^TYPE' /opt/4realoss/conf/app.ini | head -1)"
    echo "External URL: $(grep -E '^EXTERNAL_URL' /opt/4realoss/conf/app.ini | head -1)"
fi
echo ""

echo "🌍 Nginx Configuration"
echo "----------------------"
if command -v nginx &> /dev/null; then
    echo "Nginx version: $(nginx -v 2>&1)"
    echo ""
    echo "Sites enabled:"
    ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "Sites-enabled directory not found"
    echo ""
    echo "Nginx status: $(systemctl is-active nginx 2>/dev/null || echo 'not active')"
else
    echo "❌ Nginx not installed"
fi
echo ""

echo "🔒 SSL Certificates"
echo "------------------"
if [ -d "/etc/letsencrypt/live/4realoss.com" ]; then
    echo "✅ SSL certificate found for 4realoss.com"
    echo "Certificate files:"
    ls -la /etc/letsencrypt/live/4realoss.com/ 2>/dev/null
    echo ""
    echo "Certificate expiry:"
    openssl x509 -in /etc/letsencrypt/live/4realoss.com/cert.pem -noout -dates 2>/dev/null || echo "Could not read certificate"
else
    echo "❌ No SSL certificate found for 4realoss.com"
fi
echo ""

echo "👤 Users and Permissions"
echo "------------------------"
echo "Current user: $(whoami)"
echo ""
echo "Checking for 'realoss' user:"
if id realoss &>/dev/null; then
    echo "✅ User 'realoss' exists"
    echo "Home: $(getent passwd realoss | cut -d: -f6)"
    echo "Shell: $(getent passwd realoss | cut -d: -f7)"
else
    echo "❌ User 'realoss' does not exist"
fi
echo ""

echo "🗂️  Repository Data"
echo "------------------"
for repo_path in "/opt/gogs/repositories" "/opt/4realoss/repositories" "/home/gogs/gogs-repositories"; do
    if [ -d "$repo_path" ]; then
        echo "✅ Found repositories at: $repo_path"
        echo "Size: $(du -sh $repo_path 2>/dev/null | cut -f1)"
        echo "Count: $(find $repo_path -name "*.git" -type d 2>/dev/null | wc -l) repositories"
        echo ""
    fi
done

echo "🔍 IPFS Status"
echo "-------------"
if command -v ipfs &> /dev/null; then
    echo "IPFS version: $(ipfs version 2>/dev/null | head -1)"
    echo "IPFS repo: $(ipfs config Addresses.API 2>/dev/null || echo 'Not initialized')"
    
    # Check if IPFS is running
    if pgrep -f "ipfs daemon" > /dev/null; then
        echo "IPFS daemon: running"
        echo "Peers: $(ipfs swarm peers 2>/dev/null | wc -l || echo 'unknown')"
    else
        echo "IPFS daemon: not running"
    fi
else
    echo "❌ IPFS not installed"
fi
echo ""

echo "🚨 Potential Issues"
echo "------------------"
issues_found=0

# Check for port conflicts
if netstat -tln 2>/dev/null | grep -q ":3000" || ss -tln 2>/dev/null | grep -q ":3000"; then
    echo "⚠️  Port 3000 is already in use"
    ((issues_found++))
fi

if netstat -tln 2>/dev/null | grep -q ":5432" || ss -tln 2>/dev/null | grep -q ":5432"; then
    echo "⚠️  Port 5432 (PostgreSQL) is already in use"
    ((issues_found++))
fi

# Check disk space
root_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$root_usage" -gt 85 ]; then
    echo "⚠️  Root filesystem is ${root_usage}% full"
    ((issues_found++))
fi

if [ $issues_found -eq 0 ]; then
    echo "✅ No obvious issues detected"
fi

echo ""
echo "📋 Summary"
echo "==========="
echo "This VPS appears to be:"
if [ -d "/opt/gogs" ] && [ -d "/opt/4realoss" ]; then
    echo "- Running BOTH old Gogs AND 4REALOSS installations"
    echo "- RECOMMENDATION: Backup old data before deployment"
elif [ -d "/opt/gogs" ]; then
    echo "- Running an OLD Gogs installation"
    echo "- RECOMMENDATION: Use migrate-to-production.sh to preserve data"
elif [ -d "/opt/4realoss" ]; then
    echo "- Already running 4REALOSS"
    echo "- RECOMMENDATION: Check if update is needed"
else
    echo "- Clean (no existing Git hosting detected)"
    echo "- RECOMMENDATION: Fresh deployment is safe"
fi

echo ""
echo "🚀 Next Steps:"
echo "1. Review this report for any concerning issues"
echo "2. If data exists, decide on migration vs fresh install"
echo "3. Run appropriate deployment script"
echo ""
echo "Generated: $(date)"