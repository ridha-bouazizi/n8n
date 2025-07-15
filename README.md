# 🚀 Enhanced n8n Automation Platform

A comprehensive, production-ready setup for n8n workflow automation platform with PostgreSQL database, Redis queue management, and advanced configuration options.

## 📋 Table of Contents

- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Production Deployment](#-production-deployment)
- [Backup & Restore](#-backup--restore)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## ✨ Features

- **🗄️ PostgreSQL Database**: Persistent data storage with health checks
- **⚡ Redis Queue Management**: Scalable workflow execution
- **🔒 Enhanced Security**: Authentication, secure configurations
- **📊 Monitoring**: Health checks and metrics collection
- **🔄 Auto-scaling**: Worker processes for better performance
- **🛡️ Reverse Proxy**: Traefik integration for production
- **📦 Easy Backup**: Automated backup and restore scripts
- **🐳 Docker Compose**: One-command deployment
- **🔧 Flexible Configuration**: Environment-based settings
- **🌍 Cross-Platform**: Scripts for Windows, Linux, and macOS

## 🔧 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM
- 10GB free disk space

## 🚀 Quick Start

1. **Clone or download this repository**
   ```powershell
   git clone <your-repo-url>
   cd n8n
   ```

2. **Configure environment variables**
   ```powershell
   # Copy and edit the environment file
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

3. **Start the services**
   ```powershell
   # Start with basic setup (development)
   docker-compose up -d

   # Or start with all services (production)
   docker-compose --profile production up -d
   ```

4. **Access n8n**
   - Open your browser to http://localhost:5678
   - Default credentials: `admin` / `change_this_secure_password_123!`
   - **⚠️ Change default credentials immediately!**

## ⚙️ Configuration

### Environment Variables

Key configuration options in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_BASIC_AUTH_USER` | Admin username | `admin` |
| `N8N_BASIC_AUTH_PASSWORD` | Admin password | `change_this_secure_password_123!` |
| `POSTGRES_PASSWORD` | Database password | `secure_postgres_password_456!` |
| `REDIS_PASSWORD` | Redis password | `secure_redis_password_789!` |
| `N8N_WORKER_REPLICAS` | Number of worker processes | `1` |
| `GENERIC_TIMEZONE` | Timezone for scheduling | `UTC` |

### Security Configuration

1. **Change default passwords** in `.env`
2. **Enable HTTPS** for production (set `N8N_PROTOCOL=https`)
3. **Configure firewall** to restrict access
4. **Set up SSL certificates** for domain access

## �️ Management Tools

This project includes comprehensive management scripts for both Windows and Linux/macOS:

### Cross-Platform Scripts

| Feature | Windows | Linux/macOS |
|---------|---------|-------------|
| **Main Management** | `scripts\manage.ps1` | `scripts/manage.sh` |
| **Backup System** | `scripts\backup.ps1` | `scripts/backup.sh` |
| **Restore System** | `scripts\restore.ps1` | `scripts/restore.sh` |
| **Health Monitoring** | `scripts\health-check.ps1` | `scripts/health-check.sh` |
| **Quick Commands** | `make.ps1` | `make.sh` |

### Management Script Usage

**Windows:**
```powershell
# Start services
.\scripts\manage.ps1 start

# Start in development mode
.\scripts\manage.ps1 start --dev

# View logs with follow
.\scripts\manage.ps1 logs n8n --follow

# Create backup
.\scripts\manage.ps1 backup

# Scale workers
.\scripts\manage.ps1 scale 3
```

**Linux/macOS:**
```bash
# Start services
./scripts/manage.sh start

# Start in development mode
./scripts/manage.sh start --dev

# View logs with follow
./scripts/manage.sh logs n8n --follow

# Create backup
./scripts/manage.sh backup

# Scale workers
./scripts/manage.sh scale 3
```

### Quick Commands (Make-style)

**Windows:**
```powershell
# Complete setup
.\make.ps1 install

# Development mode
.\make.ps1 dev

# Production mode
.\make.ps1 prod

# Health check
.\make.ps1 test
```

**Linux/macOS:**
```bash
# Complete setup
./make.sh install

# Development mode
./make.sh dev

# Production mode
./make.sh prod

# Health check
./make.sh test
```

## 📖 Usage

### Basic Operations

**Windows (PowerShell):**
```powershell
# Start services
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart n8n

# Update to latest version
docker-compose pull
docker-compose up -d
```

**Linux/macOS (Bash):**
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart n8n

# Update to latest version
docker-compose pull
docker-compose up -d
```

### Scaling Workers

**Windows:**
```powershell
# Scale worker processes
docker-compose up -d --scale n8n-worker=3
```

**Linux/macOS:**
```bash
# Scale worker processes
docker-compose up -d --scale n8n-worker=3
```

### Development Mode

**Windows:**
```powershell
# Copy development environment
cp .env.development .env

# Start in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

**Linux/macOS:**
```bash
# Copy development environment
cp .env.development .env

# Start in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## 🌐 Production Deployment

### With Reverse Proxy (Traefik)

1. **Configure domain** in `.env`:
   ```env
   DOMAIN_NAME=yourdomain.com
   SUBDOMAIN=n8n
   N8N_PROTOCOL=https
   ```

2. **Start with production profile**:
   ```powershell
   docker-compose --profile production up -d
   ```

3. **Access via domain**: https://n8n.yourdomain.com

### SSL/TLS Configuration

The setup includes automatic SSL certificate generation via Let's Encrypt when using Traefik.

## 💾 Backup & Restore

### Automated Backups

**Windows:**
```powershell
# Manual backup
.\scripts\backup.ps1

# Restore from backup
.\scripts\restore.ps1 backup-2025-01-15
```

**Linux/macOS:**
```bash
# Manual backup
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-2025-01-15
```

### What's Backed Up

- PostgreSQL database
- n8n user data and workflows
- Configuration files
- Custom nodes and credentials

## 📊 Monitoring

### Health Checks

All services include health checks:
- n8n: HTTP endpoint monitoring
- PostgreSQL: Database connectivity
- Redis: Cache availability

### Logs

**Windows:**
```powershell
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f n8n
docker-compose logs -f postgres

# View last 100 lines
docker-compose logs --tail=100 n8n
```

**Linux/macOS:**
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f n8n
docker-compose logs -f postgres

# View last 100 lines
docker-compose logs --tail=100 n8n
```

### Metrics

n8n metrics are enabled by default and available at:
- Prometheus metrics: http://localhost:5678/metrics

## 🔍 Troubleshooting

### Common Issues

1. **Port already in use**
   ```powershell
   # Change N8N_PORT in .env file
   N8N_PORT=5679
   ```

2. **Database connection failed**
   ```powershell
   # Check PostgreSQL logs
   docker-compose logs postgres
   
   # Restart database
   docker-compose restart postgres
   ```

3. **Memory issues**
   ```powershell
   # Check resource usage
   docker stats
   
   # Reduce worker count
   N8N_WORKER_REPLICAS=1
   ```

4. **Permission issues**
   ```powershell
   # Fix volume permissions
   docker-compose down
   docker volume rm n8n_n8n_data
   docker-compose up -d
   ```

### Debug Mode

```powershell
# Enable debug logging
# In .env file:
N8N_LOG_LEVEL=debug
NODE_ENV=development

# Restart services
docker-compose restart n8n
```

### Reset Everything

```powershell
# ⚠️ WARNING: This will delete all data!
docker-compose down -v
docker-compose up -d
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- [n8n Community Forum](https://community.n8n.io/)
- [GitHub Issues](https://github.com/n8n-io/n8n/issues)
- [Discord Community](https://discord.gg/n8n)

---

**⚠️ Security Note**: Always change default passwords and keep your installation updated!