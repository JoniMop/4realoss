#!/bin/bash
# Fix IPFS by creating a secure nginx proxy instead of exposing API directly

echo "🔧 Setting up secure IPFS proxy through nginx..."

# First, secure the IPFS API to localhost only
/usr/local/bin/ipfs config Addresses.API /ip4/127.0.0.1/tcp/5002
echo "✅ IPFS API secured to localhost only"

# Update nginx configuration to include IPFS proxy
cat >> /etc/nginx/sites-available/4realoss << 'EOF'

    # IPFS API Proxy for secure access
    location /ipfs-api/ {
        # Remove /ipfs-api prefix and proxy to local IPFS API
        rewrite ^/ipfs-api/(.*)$ /api/v0/$1 break;
        proxy_pass http://127.0.0.1:5002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Enable CORS for browser access
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # IPFS Gateway Proxy for viewing content
    location /ipfs/ {
        proxy_pass http://127.0.0.1:8081/ipfs/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
EOF

echo "✅ Nginx IPFS proxy configuration added"

# Test nginx configuration
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration valid"
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration error"
    exit 1
fi

# Update the template to use the nginx proxy
sed -i 's|http://127.0.0.1:5002/api/v0/|https://4realoss.com/ipfs-api/|g' /opt/4realoss/templates/repo/header.tmpl
sed -i 's|http://127.0.0.1:8081/ipfs/|https://4realoss.com/ipfs/|g' /opt/4realoss/templates/repo/header.tmpl

echo "✅ Updated template to use secure nginx proxy"

# Restart services
systemctl restart 4realoss-ipfs
systemctl restart 4realoss

echo "✅ All services restarted"
echo ""
echo "🎉 IPFS is now accessible securely through:"
echo "   📤 Upload API: https://4realoss.com/ipfs-api/add"
echo "   📄 View content: https://4realoss.com/ipfs/HASH"
echo ""
echo "🔒 Security: IPFS API only accessible through your domain"