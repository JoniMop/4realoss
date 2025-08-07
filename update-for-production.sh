#!/bin/bash

# Production Configuration Update Script
# Usage: ./update-for-production.sh yourdomain.com

if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 mygogs.com"
    exit 1
fi

DOMAIN=$1
GOGS_DIR="/home/gogs/gogs-app"

echo "🔧 Updating configuration for production domain: $DOMAIN"
echo "============================================================"

# Update app.ini configuration
echo "📝 Updating Gogs configuration..."
sudo -u gogs tee $GOGS_DIR/conf/app.ini > /dev/null <<EOF
# Gogs Production Configuration

[server]
PROTOCOL = http
DOMAIN = $DOMAIN
HTTP_ADDR = 127.0.0.1
HTTP_PORT = 3000
ROOT_URL = https://$DOMAIN/
DISABLE_SSH = false
SSH_PORT = 22
START_SSH_SERVER = false
OFFLINE_MODE = false

[database]
DB_TYPE = sqlite3
HOST = 127.0.0.1:3306
NAME = gogs
USER = root
PASSWD = 
SSL_MODE = disable
PATH = data/gogs.db

[security]
INSTALL_LOCK = true
SECRET_KEY = $(openssl rand -base64 32)
LOGIN_REMEMBER_DAYS = 7
COOKIE_USERNAME = gogs_awesome
COOKIE_REMEMBER_NAME = gogs_incredible
REVERSE_PROXY_AUTHENTICATION = false
DISABLE_GIT_HOOKS = false

[service]
ACTIVE_CODE_LIVE_MINUTES = 180
RESET_PASSWD_CODE_LIVE_MINUTES = 180
REGISTER_EMAIL_CONFIRM = false
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false
ENABLE_NOTIFY_MAIL = false
ENABLE_REVERSE_PROXY_AUTO_REGISTER = false
ENABLE_CAPTCHA = false

[picture]
DISABLE_GRAVATAR = false
ENABLE_FEDERATED_AVATAR = true

[session]
PROVIDER = file
PROVIDER_CONFIG = data/sessions
COOKIE_SECURE = true
COOKIE_NAME = i_like_gogs

[log]
MODE = file
LEVEL = Info
ROOT_PATH = $GOGS_DIR/log

[git]
MAX_GIT_DIFF_LINES = 10000
MAX_GIT_DIFF_LINE_CHARACTERS = 500
MAX_GIT_DIFF_FILES = 100
GC_ARGS = 

[other]
SHOW_FOOTER_BRANDING = true
SHOW_FOOTER_VERSION = true
EOF

# Create a production version of the header template
echo "🌐 Creating production header template..."
sudo -u gogs cp $GOGS_DIR/templates/repo/header.tmpl $GOGS_DIR/templates/repo/header.tmpl.backup

# Update the JavaScript in header.tmpl to use the production domain
sudo -u gogs sed -i "s|http://127.0.0.1:5002/api/v0/|https://$DOMAIN/ipfs-api/|g" $GOGS_DIR/templates/repo/header.tmpl
sudo -u gogs sed -i "s|http://127.0.0.1:8081/ipfs/|https://$DOMAIN/ipfs/|g" $GOGS_DIR/templates/repo/header.tmpl

echo "🔒 Adding CDN libraries for production..."
# Add required libraries (JSZip and Ethers) via CDN
sudo -u gogs sed -i '104i\
<script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>\
<script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/5.7.2/ethers.umd.min.js"></script>' $GOGS_DIR/templates/repo/header.tmpl

# Update configuration permissions
echo "🔐 Setting proper permissions..."
sudo chown -R gogs:gogs $GOGS_DIR
sudo chmod 755 $GOGS_DIR
sudo chmod 644 $GOGS_DIR/conf/app.ini

# Restart services
echo "🔄 Restarting services..."
sudo systemctl restart gogs ipfs
sudo systemctl reload nginx

echo ""
echo "✅ Production configuration complete!"
echo "===================================="
echo "🌐 Your site should now be fully functional at: https://$DOMAIN"
echo ""
echo "🔧 What was updated:"
echo "   ✅ Gogs configuration (app.ini) for HTTPS and domain"
echo "   ✅ IPFS API URLs updated to use domain proxy"
echo "   ✅ CDN libraries added for JSZip and Ethers"
echo "   ✅ Services restarted"
echo ""
echo "📊 Service status:"
sudo systemctl status gogs --no-pager -l
echo ""
echo "🧪 Test your deployment:"
echo "   1. Visit https://$DOMAIN"
echo "   2. Create a test repository"
echo "   3. Try the 'Push to IPFS & Arbitrum' button"
echo ""
echo "💡 If you encounter issues:"
echo "   - Check logs: sudo journalctl -u gogs -f"
echo "   - Check nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "   - Verify DNS: dig $DOMAIN" 