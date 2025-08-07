# 🐘 Gogs with PostgreSQL Local Development Setup

This guide helps you set up Gogs with PostgreSQL for local development and testing, including the Metamask authentication feature.

## 📋 Prerequisites

- **Docker & Docker Compose**: For PostgreSQL database
- **Go**: For building Gogs
- **IPFS**: For distributed file storage
- **Git**: For repository operations

### Install Docker (if not already installed)
```bash
# On Kali Linux/Debian
sudo apt update
sudo apt install docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### Install IPFS (if not already installed)
```bash
wget https://dist.ipfs.io/go-ipfs/v0.14.0/go-ipfs_v0.14.0_linux-amd64.tar.gz
tar -xzf go-ipfs_v0.14.0_linux-amd64.tar.gz
sudo mv go-ipfs/ipfs /usr/local/bin/
ipfs init
```

## 🚀 Quick Start

### 1. Start All Services
```bash
./start-gogs-postgres.sh
```

This will:
- ✅ Start PostgreSQL in Docker container
- ✅ Start IPFS daemon
- ✅ Build and start Gogs web server
- ✅ Configure everything automatically

### 2. Initial Setup
1. **Open**: http://127.0.0.1:3000
2. **Database settings** are pre-configured:
   - Database Type: `PostgreSQL`
   - Host: `127.0.0.1:5432`
   - Database Name: `gogs`
   - Username: `gogs`  
   - Password: `gogs_password`
3. **Complete the installation**
4. **Create your admin account**

### 3. Test Metamask Authentication
1. **Login page**: Click "Login with Metamask"
2. **Connect wallet**: Approve the connection
3. **Sign message**: Sign the authentication message
4. **Create repository**: Try creating a new repository
5. **Debug**: Check logs if you get 500 error

## 📊 Service Management

### Check Status
```bash
./status-gogs-postgres.sh
```

### Stop All Services
```bash
./stop-gogs-postgres.sh
```

### View Logs
```bash
# Gogs logs
tail -f logs/gogs.log

# IPFS logs  
tail -f logs/ipfs.log

# PostgreSQL logs
docker logs gogs-postgres-dev
```

## 🛠️ Database Management

### Connect to PostgreSQL
```bash
# Using Docker
docker exec -it gogs-postgres-dev psql -U gogs -d gogs

# Using local psql (if installed)
psql -h localhost -U gogs -d gogs
```

### Optional: pgAdmin Web Interface
```bash
# Start pgAdmin
docker compose -f docker-compose.dev.yml --profile tools up -d pgadmin

# Access: http://127.0.0.1:8080
# Login: admin@gogs.local / admin
```

### Reset Database
```bash
# Stop services
./stop-gogs-postgres.sh

# Remove database data
docker compose -f docker-compose.dev.yml down -v

# Start fresh
./start-gogs-postgres.sh
```

## 🔍 Debugging Repository Creation 500 Error

### 1. Enable Debug Logging
The configuration is already set to `LEVEL = Trace` in `conf/app.ini`.

### 2. Monitor Logs During Error
```bash
# In one terminal, watch Gogs logs
tail -f logs/gogs.log

# In another terminal, watch PostgreSQL logs
docker logs -f gogs-postgres-dev

# Try creating repository and watch the logs
```

### 3. Common Issues & Solutions

#### Database Connection Issues
```bash
# Test database connection
docker exec gogs-postgres-dev pg_isready -U gogs -d gogs

# Check if database exists
docker exec gogs-postgres-dev psql -U gogs -d gogs -c "\dt"
```

#### File Permission Issues
```bash
# Check data directory permissions
ls -la data/

# Fix permissions if needed
chmod -R 755 data/
```

#### Repository Directory Issues
```bash
# Check repository root
ls -la ~/gogs-repositories/

# Create if missing
mkdir -p ~/gogs-repositories/
```

### 4. Database Query Debugging
```sql
-- Connect to database
docker exec -it gogs-postgres-dev psql -U gogs -d gogs

-- Check users (including Metamask users)
SELECT id, name, email, lower_name FROM "user" WHERE email LIKE '0x%';

-- Check repositories
SELECT id, name, owner_id FROM repository;

-- Check for any constraints or issues
\d repository
```

## 🌐 Service URLs

- **Gogs Web**: http://127.0.0.1:3000
- **IPFS Web UI**: http://127.0.0.1:5002/webui
- **IPFS Gateway**: http://127.0.0.1:8081
- **PostgreSQL**: localhost:5432
- **pgAdmin** (optional): http://127.0.0.1:8080

## 🔄 Switching Between SQLite3 and PostgreSQL

The configuration is in `conf/app.ini`:

### For PostgreSQL (current):
```ini
[database]
TYPE = postgres
HOST = 127.0.0.1:5432
NAME = gogs
USER = gogs
PASSWORD = gogs_password
```

### For SQLite3:
```ini
[database]
TYPE = sqlite3
PATH = data/gogs.db
```

## 📝 Next Steps

1. **Test Metamask login** and repository creation
2. **Monitor logs** for any errors
3. **Report findings** - which specific error occurs
4. **Compare behavior** between SQLite3 (VPS) and PostgreSQL (local)

This setup closely mirrors a production environment and should help identify the root cause of the 500 error you're experiencing on your VPS.