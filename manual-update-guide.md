# 🚀 Manual Production Update Guide

The automated script had SSH authentication issues. Here's how to manually update your production system:

## 📦 Step 1: Upload Files

The update package is ready at: `./build-production-update/`

### Upload to VPS:
```bash
# Method 1: Using SCP with password
scp -r ./build-production-update/ root@164.92.110.168:/tmp/4realoss-update/

# Method 2: Using rsync with password
rsync -avz --progress ./build-production-update/ root@164.92.110.168:/tmp/4realoss-update/
```

## 🔧 Step 2: Run Update on VPS

SSH into your VPS:
```bash
ssh root@164.92.110.168
```

Then run these commands on the VPS:

```bash
# Navigate to update directory
cd /tmp/4realoss-update

# Make script executable
chmod +x run-update.sh

# Run the update
./run-update.sh
```

## 📋 What the Update Script Does:

1. **Creates backup** at `/opt/4realoss-backup-[timestamp]`
2. **Stops 4REALOSS service** briefly
3. **Updates binary** to latest version with all fixes
4. **Updates templates and public files**
5. **Fixes hardcoded paths** in configuration
6. **Preserves your database, SSL, nginx config**
7. **Restarts service** and verifies it's working

## 🧪 Expected Output:

```
🔄 Starting 4REALOSS Production Update on VPS...
📦 Creating backup...
✅ Backup created at: /opt/4realoss-backup-[timestamp]
🛑 Stopping services...
💾 Preserving current configuration and data...
📁 Installing updated files...
⚙️  Updating configuration...
✅ Configuration updated with path fixes
🔐 Setting permissions...
🚀 Starting updated services...
✅ 4REALOSS service started successfully
🧪 Testing the updated service...
✅ HTTP service responding correctly
🎉 4REALOSS Production Update Completed!
```

## 🔍 Verify Update Success:

After running the update, verify everything is working:

```bash
# Check service status
systemctl status 4realoss

# Check version
cd /opt/4realoss && ./realoss --version

# Test HTTP
curl -I http://localhost:3000/

# Test HTTPS
curl -I https://4realoss.com/
```

## 🛡️ Safety & Rollback:

- **Backup created**: If anything goes wrong, your backup is at `/opt/4realoss-backup-[timestamp]`
- **Quick rollback**: If needed, stop service and restore from backup
- **Database preserved**: PostgreSQL container keeps running throughout

## 🎯 Key Improvements Applied:

✅ **Latest binary** with all recent code changes  
✅ **Fixed hardcoded paths** (`/home/kali` → `/opt/4realoss`)  
✅ **Updated templates** and public files  
✅ **Preserved your SSL certificate** and nginx config  
✅ **Maintained database** and IPFS integration  

Ready to proceed with manual update!