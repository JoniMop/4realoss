#!/bin/bash
# Fix the nginx configuration by placing IPFS proxy in the correct location

echo "🔧 Fixing nginx configuration..."

# Create a clean nginx config
cat > /etc/nginx/sites-available/4realoss << 'EOF'
server {
    listen 80;
    server_name 4realoss.com www.4realoss.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name 4realoss.com www.4realoss.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/4realoss.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/4realoss.com/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;

    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Client upload limits
    client_max_body_size 500M;

    # IPFS API Proxy for secure access (must be before generic / location)
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

    # Proxy to 4REALOSS (must be last as it's a catch-all)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

echo "✅ Clean nginx configuration created"

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

# Restart 4REALOSS to pick up template changes
systemctl restart 4realoss

echo "✅ 4REALOSS restarted"
echo ""
echo "🎉 IPFS is now accessible securely through HTTPS:"
echo "   📤 Upload API: https://4realoss.com/ipfs-api/add"
echo "   📄 View content: https://4realoss.com/ipfs/HASH"
echo ""
echo "🔒 Security: IPFS API only accessible through your domain with HTTPS"