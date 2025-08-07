#!/bin/bash

# Domain and SSL Setup Script
# Usage: ./setup-domain.sh yourdomain.com

if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 mygogs.com"
    exit 1
fi

DOMAIN=$1

echo "🌐 Setting up domain: $DOMAIN"
echo "=================================="

# Create nginx configuration
echo "📝 Creating nginx configuration..."
sudo tee /etc/nginx/sites-available/gogs > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Redirect all HTTP requests to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL configuration will be added by certbot
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Main application proxy
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # IPFS API proxy (for local IPFS calls)
    location /ipfs-api/ {
        proxy_pass http://127.0.0.1:5002/api/v0/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for IPFS API
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }

    # IPFS Gateway proxy (optional, for local gateway access)
    location /ipfs/ {
        proxy_pass http://127.0.0.1:8081/ipfs/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # File upload size limit (for repository uploads)
    client_max_body_size 100M;
}
EOF

# Enable the site
echo "🔗 Enabling nginx site..."
sudo ln -sf /etc/nginx/sites-available/gogs /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed!"
    exit 1
fi

# Reload nginx
echo "🔄 Reloading nginx..."
sudo systemctl reload nginx

# Get SSL certificate
echo "🔒 Getting SSL certificate from Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate obtained successfully!"
    
    # Set up automatic renewal
    echo "⏰ Setting up automatic certificate renewal..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    echo ""
    echo "🎉 Setup complete!"
    echo "=================================="
    echo "✅ Your site is now available at:"
    echo "   🌐 https://$DOMAIN"
    echo "   🌐 https://www.$DOMAIN"
    echo ""
    echo "📊 Service status:"
    sudo systemctl status gogs --no-pager -l
    sudo systemctl status ipfs --no-pager -l
    echo ""
    echo "📝 Useful commands:"
    echo "   View logs: sudo journalctl -u gogs -f"
    echo "   View IPFS logs: sudo journalctl -u ipfs -f"
    echo "   Restart services: sudo systemctl restart gogs ipfs"
    echo ""
    echo "🔧 Configuration files:"
    echo "   Nginx: /etc/nginx/sites-available/gogs"
    echo "   Gogs: /home/gogs/gogs-app"
    echo "   IPFS: /home/gogs/.ipfs"
    
else
    echo "❌ Failed to obtain SSL certificate!"
    echo "🔍 Please check:"
    echo "   1. Domain DNS is pointing to this server"
    echo "   2. Ports 80 and 443 are open"
    echo "   3. Domain is accessible from the internet"
    exit 1
fi 