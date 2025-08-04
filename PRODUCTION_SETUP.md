# 4REALOSS Production Setup Guide

This guide will help you deploy 4REALOSS to your production VPS with PostgreSQL + IPFS integration.

## Prerequisites

- VPS with Ubuntu/Debian (your current setup: `root@164.92.110.168`)
- Domain pointing to your VPS IP (`4realoss.com` → `164.92.110.168`)
- Docker and Docker Compose installed
- Nginx installed
- SSH access to your VPS

## Migration Options

### Option 1: Full Migration (Recommended)
Migrates your existing SQLite3 data to the new PostgreSQL + IPFS setup:

```bash
chmod +x migrate-to-production.sh
./migrate-to-production.sh
```

### Option 2: Fresh Deployment
Deploy a fresh 4REALOSS installation (loses existing data):

```bash
chmod +x deploy-to-production.sh
./deploy-to-production.sh
```

## What Gets Deployed

### Services
- **4REALOSS Web Server**: Main application (systemd service)
- **IPFS Daemon**: For repository publishing (systemd service)  
- **PostgreSQL**: Database (Docker container)
- **Nginx**: Reverse proxy with SSL

### Configuration Files
- `/opt/4realoss/conf/app.ini` - Main application config
- `/etc/systemd/system/4realoss.service` - Web server service
- `/etc/systemd/system/4realoss-ipfs.service` - IPFS daemon service
- `/etc/nginx/sites-available/4realoss` - Nginx configuration
- `/opt/4realoss/docker-compose.yml` - PostgreSQL container

## Post-Deployment Steps

### 1. Verify Services
```bash
ssh root@164.92.110.168 'systemctl status 4realoss 4realoss-ipfs'
```

### 2. Set Up SSL Certificate
```bash
ssh root@164.92.110.168 'certbot --nginx -d 4realoss.com -d www.4realoss.com'
```

### 3. Test Your Site
- Visit: https://4realoss.com
- Test Metamask login
- Create a test repository
- Verify IPFS integration

## Service Management

### Start/Stop Services
```bash
# On VPS
systemctl start 4realoss-ipfs    # Start IPFS first
systemctl start 4realoss         # Then start 4REALOSS
systemctl stop 4realoss          # Stop in reverse order
systemctl stop 4realoss-ipfs
```

### View Logs
```bash
# 4REALOSS application logs
journalctl -u 4realoss -f

# IPFS daemon logs  
journalctl -u 4realoss-ipfs -f

# PostgreSQL logs
docker logs realoss-postgres-prod

# Application file logs
tail -f /opt/4realoss/logs/gogs.log
```

### Restart Services
```bash
systemctl restart 4realoss-ipfs
sleep 5
systemctl restart 4realoss
```

## Database Management

### Connect to PostgreSQL
```bash
docker exec -it realoss-postgres-prod psql -U gogs -d gogs
```

### Backup Database
```bash
docker exec realoss-postgres-prod pg_dump -U gogs gogs > backup-$(date +%Y%m%d).sql
```

### Restore Database
```bash
docker exec -i realoss-postgres-prod psql -U gogs -d gogs < backup-20250803.sql
```

## IPFS Management

### Check IPFS Status
```bash
# IPFS node info
ipfs id

# Connected peers
ipfs swarm peers | wc -l

# Gateway test
curl http://127.0.0.1:8081/ipfs/QmQPeNsJPyVWPFDVHb77w8G42Fvo15z4bG2X8D2GhfbSXc/readme
```

### Configure IPFS
```bash
# API access (already configured)
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'

# Gateway port (already set to 8081)
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8081
```

## Troubleshooting

### Common Issues

**1. Service Won't Start**
```bash
# Check logs
journalctl -u 4realoss -n 50

# Check configuration
/opt/4realoss/realoss web --config /opt/4realoss/conf/app.ini --help
```

**2. Database Connection Issues**
```bash
# Check PostgreSQL container
docker ps | grep postgres
docker logs realoss-postgres-prod

# Test connection
docker exec realoss-postgres-prod pg_isready -U gogs -d gogs
```

**3. IPFS Not Working**
```bash
# Check IPFS daemon
systemctl status 4realoss-ipfs
ipfs version

# Reinitialize if needed
systemctl stop 4realoss-ipfs
rm -rf /root/.ipfs
ipfs init
systemctl start 4realoss-ipfs
```

**4. SSL Certificate Issues**
```bash
# Renew certificate
certbot renew

# Test Nginx config
nginx -t
systemctl reload nginx
```

### Performance Tuning

**PostgreSQL**
Edit `/opt/4realoss/docker-compose.yml` and add:
```yaml
environment:
  POSTGRES_SHARED_PRELOAD_LIBRARIES: pg_stat_statements
  POSTGRES_MAX_CONNECTIONS: 100
  POSTGRES_SHARED_BUFFERS: 256MB
```

**Nginx**
Edit `/etc/nginx/sites-enabled/4realoss`:
```nginx
# Add to server block
gzip on;
gzip_types text/css application/javascript text/javascript application/json;
```

## Security Considerations

### Firewall
```bash
# Allow only necessary ports
ufw allow 22      # SSH
ufw allow 80      # HTTP
ufw allow 443     # HTTPS
ufw enable
```

### Database Security
- Change default passwords in `app.ini` and `docker-compose.yml`
- Restrict PostgreSQL to localhost only
- Regular database backups

### IPFS Security
- IPFS runs on localhost only (API: 5002, Gateway: 8081)
- Consider using Pinata for additional reliability

## Monitoring

### Health Check Script
Create `/opt/4realoss/health-check.sh`:
```bash
#!/bin/bash
# Simple health monitoring
curl -f http://127.0.0.1:3000/ || echo "4REALOSS down"
curl -f http://127.0.0.1:8081/ipfs/QmQPeNsJPyVWPFDVHb77w8G42Fvo15z4bG2X8D2GhfbSXc/readme || echo "IPFS down"
docker exec realoss-postgres-prod pg_isready -U gogs -d gogs || echo "PostgreSQL down"
```

### Log Rotation
4REALOSS automatically rotates logs. To adjust:
```ini
# In /opt/4realoss/conf/app.ini
[log]
ROTATE = true
MAX_LINES = 1000000
MAX_SIZE_SHIFT = 28
DAILY_ROTATE = true
MAX_DAYS = 7
```

## Backup Strategy

### Full Backup Script
Create `/opt/4realoss/backup.sh`:
```bash
#!/bin/bash
BACKUP_DIR="/opt/4realoss-backups"
DATE=$(date +%Y%m%d-%H%M)

mkdir -p "$BACKUP_DIR"

# Database backup
docker exec realoss-postgres-prod pg_dump -U gogs gogs > "$BACKUP_DIR/db-$DATE.sql"

# Repository backup
tar -czf "$BACKUP_DIR/repos-$DATE.tar.gz" -C /opt/4realoss repositories

# Configuration backup
cp /opt/4realoss/conf/app.ini "$BACKUP_DIR/app.ini-$DATE"

# Clean old backups (keep 7 days)
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
```

## Updates

To update 4REALOSS:
1. Build new version locally
2. Run deployment script
3. Services will restart automatically
4. Database migrations run automatically

## Support

- **Local testing**: Use `./start-realoss.sh` for development
- **Logs**: Always check logs first for troubleshooting
- **Database**: Use PostgreSQL tools for advanced database management
- **IPFS**: Monitor peer connections and gateway availability