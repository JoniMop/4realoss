# 🚀 Gogs + IPFS Production Deployment Guide

This guide will help you deploy your Gogs + IPFS application to a live server with a real domain and SSL certificate.

## 📋 Prerequisites

- A domain name (e.g., from Namecheap, GoDaddy, Cloudflare)
- A VPS/server (Ubuntu 20.04+ recommended)
- SSH access to your server
- Basic terminal knowledge

## 💰 Estimated Costs

| Service | Monthly Cost | Purpose |
|---------|-------------|---------|
| Domain | ~$1-2/month | Your website address |
| VPS (DigitalOcean/Linode) | $6-12/month | Server hosting |
| **Total** | **$7-14/month** | Full deployment |

## 🎯 Quick Deployment (5 Steps)

### Step 1: Get Your Infrastructure

1. **Buy a domain** (e.g., `yourgogs.com`)
2. **Create a VPS**:
   - DigitalOcean: Ubuntu 22.04, $6/month droplet
   - Linode: Ubuntu 22.04, $5/month nanode
   - AWS EC2: t2.micro (free tier eligible)

### Step 2: Point Domain to Server

In your domain registrar's DNS settings:
```
Type: A Record
Name: @ (or blank)
Value: YOUR_SERVER_IP_ADDRESS
TTL: 600 (or 3600 for stability)

Type: A Record  
Name: www
Value: YOUR_SERVER_IP_ADDRESS
TTL: 600 (or 3600 for stability)
```

**Note:** Different registrars have different TTL requirements:
- **GoDaddy**: 600-604800 seconds (10 minutes to 1 week)
- **Namecheap**: 60-604800 seconds  
- **Cloudflare**: 60-604800 seconds
- **General recommendation**: Use 600 (10 min) for initial setup, then 3600 (1 hour) for stability

### Step 3: Connect to Your Server

```bash
ssh root@YOUR_SERVER_IP
```

### Step 4: Run Deployment Scripts

First, upload these deployment files to your server:

```bash
# Download deployment scripts
wget https://raw.githubusercontent.com/yourusername/gogs/main/deploy-to-vps.sh
wget https://raw.githubusercontent.com/yourusername/gogs/main/setup-domain.sh
wget https://raw.githubusercontent.com/yourusername/gogs/main/update-for-production.sh

# Make them executable
chmod +x *.sh

# Run the VPS setup (installs everything)
./deploy-to-vps.sh

# Set up your domain and SSL
./setup-domain.sh yourdomain.com

# Update configuration for production
./update-for-production.sh yourdomain.com
```

### Step 5: Test Your Deployment

Visit `https://yourdomain.com` - you should see your Gogs instance!

## 🔧 Detailed Steps

### 1. Server Setup (deploy-to-vps.sh)

This script will:
- ✅ Update the system
- ✅ Install Go, IPFS, Nginx, Certbot
- ✅ Create system users and services
- ✅ Build and start Gogs + IPFS
- ✅ Configure firewall

### 2. Domain & SSL Setup (setup-domain.sh)

This script will:
- ✅ Configure Nginx reverse proxy
- ✅ Set up SSL certificates (Let's Encrypt)
- ✅ Configure HTTPS redirects
- ✅ Set up automatic certificate renewal

### 3. Production Configuration (update-for-production.sh)

This script will:
- ✅ Update Gogs configuration for your domain
- ✅ Fix IPFS API URLs for production
- ✅ Add required JavaScript libraries via CDN
- ✅ Restart all services

## 🌐 What You Get

After deployment, your site will have:

- ✅ **HTTPS with valid SSL certificate**
- ✅ **Custom domain** (yourdomain.com)
- ✅ **Git repository hosting** (like GitHub)
- ✅ **IPFS integration** for decentralized storage
- ✅ **Arbitrum blockchain** integration
- ✅ **Automatic HTTPS redirects**
- ✅ **Production-ready configuration**

## 🧪 Testing Your Deployment

1. Visit `https://yourdomain.com`
2. Create a user account
3. Create a test repository
4. Try the "Push to IPFS & Arbitrum" button
5. Check that MetaMask integration works

## 📊 Managing Your Deployment

### View Service Status
```bash
sudo systemctl status gogs ipfs nginx
```

### View Logs
```bash
# Gogs logs
sudo journalctl -u gogs -f

# IPFS logs  
sudo journalctl -u ipfs -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
sudo systemctl restart gogs ipfs
sudo systemctl reload nginx
```

### Update Your Application
```bash
cd /home/gogs/gogs-app
sudo -u gogs git pull
sudo -u gogs go build
sudo systemctl restart gogs
```

## 🔒 Security Best Practices

The deployment scripts automatically configure:

- ✅ UFW firewall (only SSH, HTTP, HTTPS open)
- ✅ Security headers in Nginx
- ✅ SSL/TLS encryption
- ✅ Dedicated system user for services
- ✅ Automatic certificate renewal

## 🛠 Customization

### Change Gogs Configuration
Edit `/home/gogs/gogs-app/conf/app.ini` and restart Gogs:
```bash
sudo systemctl restart gogs
```

### Add Pinata API Keys
Edit the header template to add your Pinata credentials for better IPFS pinning:
```bash
sudo -u gogs nano /home/gogs/gogs-app/templates/repo/header.tmpl
# Find PINATA_API_KEY and PINATA_SECRET lines
```

### Custom Domain for IPFS Gateway
The nginx configuration creates these endpoints:
- `https://yourdomain.com/ipfs-api/` → IPFS API
- `https://yourdomain.com/ipfs/` → IPFS Gateway

## ❗ Troubleshooting

### Common Issues

**SSL Certificate Failed**
```bash
# Check DNS propagation
dig yourdomain.com

# Verify domain points to your server
nslookup yourdomain.com
```

**Services Won't Start**
```bash
# Check what went wrong
sudo journalctl -u gogs -n 50
sudo journalctl -u ipfs -n 50
```

**IPFS Upload Not Working**
```bash
# Check IPFS is running
sudo systemctl status ipfs

# Test IPFS API
curl http://127.0.0.1:5002/api/v0/version
```

**MetaMask Not Connecting**
- Ensure you have the Ethers.js library loaded
- Check browser console for JavaScript errors
- Verify Arbitrum network is configured in MetaMask

## 🎉 Success!

Your Gogs + IPFS application is now live! Users can:

1. **Host Git repositories** like GitHub
2. **Upload to IPFS** with one click  
3. **Register on Arbitrum blockchain** for permanent records
4. **Access via your custom domain** with HTTPS

## 🔄 Ongoing Maintenance

- **SSL certificates** renew automatically
- **System updates**: Run `sudo apt update && sudo apt upgrade` monthly
- **Backups**: Consider backing up `/home/gogs/gogs-app/data/`
- **Monitoring**: Check logs occasionally for any issues

## 💡 Next Steps

Consider adding:
- Custom email configuration for notifications
- Database backup automation  
- Monitoring/alerting (e.g., Uptime Robot)
- CDN for better global performance (Cloudflare)
- Additional IPFS pinning services for redundancy

---

🎊 **Congratulations!** Your decentralized Git hosting platform is now live and ready for users! 