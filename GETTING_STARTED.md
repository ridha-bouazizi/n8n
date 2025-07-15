# 🚀 Quick Start Guide

Welcome to your enhanced n8n setup! This guide will help you get up and running quickly.

## 🎯 1. First Time Setup

### Option A: Using the Make Script (Recommended)
```powershell
# One-command setup
.\make.ps1 install
```

### Option B: Manual Setup
```powershell
# Copy environment configuration
Copy-Item .env.example .env

# Edit .env with your settings (important!)
notepad .env

# Start services
docker-compose up -d
```

## 🔧 2. Essential Configuration

Edit your `.env` file and change these critical settings:

```env
# Change these passwords!
N8N_BASIC_AUTH_PASSWORD=your_secure_password_here
POSTGRES_PASSWORD=your_postgres_password_here
REDIS_PASSWORD=your_redis_password_here

# Set your timezone
GENERIC_TIMEZONE=America/New_York

# Configure SMTP for notifications (optional)
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-password
```

## 🌐 3. Access Your n8n Instance

- **Main Interface**: http://localhost:5678
- **Username**: admin (or what you set in N8N_BASIC_AUTH_USER)
- **Password**: what you set in N8N_BASIC_AUTH_PASSWORD

## 🛠️ 4. Common Operations

```powershell
# Development mode (includes PgAdmin)
.\make.ps1 dev

# Production mode (includes Traefik)
.\make.ps1 prod

# View logs
.\make.ps1 logs

# Check health
.\make.ps1 status

# Create backup
.\make.ps1 backup

# Scale workers
.\make.ps1 scale 3

# Update to latest versions
.\make.ps1 update
```

## 🔍 5. Troubleshooting

### Service won't start?
```powershell
# Check logs
docker-compose logs n8n

# Restart services
.\make.ps1 restart
```

### Database issues?
```powershell
# Check database health
docker-compose exec postgres pg_isready -U n8n

# View database logs
docker-compose logs postgres
```

### Reset everything?
```powershell
# ⚠️ This deletes all data!
.\make.ps1 reset
```

## 📚 6. Next Steps

1. **Import the welcome workflow** from `workflows/welcome-workflow.json`
2. **Set up your first automation** using the n8n interface
3. **Configure webhooks** for external integrations
4. **Set up regular backups** using the included scripts
5. **Monitor your instance** with the health check scripts

## 🆘 7. Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Run `.\make.ps1 help` for available commands
- Visit [n8n Documentation](https://docs.n8n.io/)
- Join the [n8n Community](https://community.n8n.io/)

---

**⚠️ Security Reminder**: Always change default passwords and keep your instance updated!
