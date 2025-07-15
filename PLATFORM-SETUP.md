# Platform-Specific Setup Guide

This document provides platform-specific instructions for setting up and managing your enhanced n8n installation.

## 🪟 Windows Setup

### Prerequisites
- Docker Desktop for Windows
- PowerShell 5.1+ (built into Windows 10/11)
- Git for Windows (optional, for cloning)

### Quick Start
```powershell
# Clone or download the project
git clone <your-repo-url>
cd n8n

# Run the installer
.\make.ps1 install

# Start in development mode
.\make.ps1 dev
```

### Windows-Specific Scripts
- `make.ps1` - Main command runner
- `scripts\manage.ps1` - Service management
- `scripts\backup.ps1` - Backup creation
- `scripts\restore.ps1` - Data restoration
- `scripts\health-check.ps1` - Health monitoring

### Windows Commands
```powershell
# Quick development setup
.\make.ps1 dev

# Create backup
.\scripts\backup.ps1

# Check health
.\scripts\health-check.ps1 -Detailed

# Scale workers
.\scripts\manage.ps1 scale 3
```

## 🐧 Linux Setup

### Prerequisites
- Docker Engine 20.10+
- Docker Compose v2+
- Bash shell
- curl (for health checks)

### Installation (Ubuntu/Debian)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### Quick Start
```bash
# Clone the project
git clone <your-repo-url>
cd n8n

# Make scripts executable
chmod +x scripts/*.sh make.sh

# Run the installer
./make.sh install

# Start in development mode
./make.sh dev
```

### Linux-Specific Scripts
- `make.sh` - Main command runner
- `scripts/manage.sh` - Service management
- `scripts/backup.sh` - Backup creation
- `scripts/restore.sh` - Data restoration
- `scripts/health-check.sh` - Health monitoring

### Linux Commands
```bash
# Quick development setup
./make.sh dev

# Create backup
./scripts/backup.sh

# Check health with JSON output
./scripts/health-check.sh --json

# Scale workers
./scripts/manage.sh scale 3
```

## 🍎 macOS Setup

### Prerequisites
- Docker Desktop for Mac
- Homebrew (optional, for easier installation)

### Installation with Homebrew
```bash
# Install Docker Desktop
brew install --cask docker

# Or install Docker via Homebrew
brew install docker docker-compose
```

### Quick Start
```bash
# Clone the project
git clone <your-repo-url>
cd n8n

# Make scripts executable
chmod +x scripts/*.sh make.sh

# Run the installer
./make.sh install

# Start in development mode
./make.sh dev
```

### macOS Commands
Same as Linux - use the `.sh` scripts:
```bash
# Quick development setup
./make.sh dev

# Create backup
./scripts/backup.sh

# Monitor with detailed output
./scripts/health-check.sh --detailed
```

## 🔧 Platform-Specific Configuration

### Windows-Specific Settings
```env
# In .env file - Windows paths use backslashes in some contexts
# But Docker volumes use forward slashes
GENERIC_TIMEZONE=America/New_York

# For Windows, you might prefer different ports
N8N_PORT=5678
```

### Linux-Specific Settings
```env
# Typical Linux timezone
GENERIC_TIMEZONE=UTC

# Common Linux file permissions
# Ensure Docker has access to bind mount directories
```

### macOS-Specific Settings
```env
# macOS timezone examples
GENERIC_TIMEZONE=America/Los_Angeles

# Docker Desktop for Mac specific considerations
# File sharing must be enabled for project directory
```

## 🚨 Troubleshooting by Platform

### Windows Issues

**PowerShell Execution Policy:**
```powershell
# If scripts don't run, update execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Path Issues:**
```powershell
# Use full paths if relative paths don't work
cd C:\projects\n8n
.\make.ps1 install
```

**Docker Desktop Issues:**
- Ensure Docker Desktop is running
- Check WSL2 backend is enabled
- Verify file sharing is enabled for your project directory

### Linux Issues

**Permission Denied:**
```bash
# Make scripts executable
chmod +x scripts/*.sh make.sh

# Fix Docker permissions
sudo usermod -aG docker $USER
# Log out and back in
```

**Port Conflicts:**
```bash
# Check what's using port 5678
sudo netstat -tulpn | grep 5678

# Kill process if needed
sudo fuser -k 5678/tcp
```

### macOS Issues

**Docker Desktop Not Started:**
```bash
# Start Docker Desktop
open /Applications/Docker.app
```

**File Sharing:**
- Ensure your project directory is in Docker's file sharing list
- Go to Docker Desktop > Settings > Resources > File Sharing

## 🔄 Cross-Platform Tips

### Environment Files
- Use the same `.env` file across platforms
- Paths in Docker volumes use forward slashes on all platforms
- Use environment variables for platform-specific settings

### Script Equivalency
| Task | Windows | Linux/macOS |
|------|---------|-------------|
| Start services | `.\make.ps1 start` | `./make.sh start` |
| Development mode | `.\make.ps1 dev` | `./make.sh dev` |
| Create backup | `.\scripts\backup.ps1` | `./scripts/backup.sh` |
| Health check | `.\scripts\health-check.ps1` | `./scripts/health-check.sh` |

### Common Commands
These work the same on all platforms:
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
docker-compose ps
```

## 📁 File Structure Notes

```
n8n/
├── scripts/
│   ├── *.ps1          # Windows PowerShell scripts
│   ├── *.sh           # Linux/macOS Bash scripts
│   └── init-data.sh   # PostgreSQL initialization (cross-platform)
├── make.ps1           # Windows command runner
├── make.sh            # Linux/macOS command runner
├── docker-compose.yml # Cross-platform Docker configuration
└── .env.example       # Cross-platform environment template
```

## 🌟 Best Practices

1. **Always use the appropriate scripts for your platform**
2. **Keep .env files consistent across environments**
3. **Test scripts on your target platform before deployment**
4. **Use absolute paths when relative paths cause issues**
5. **Ensure Docker has proper permissions on all platforms**

---

Choose the appropriate section for your platform and follow the specific instructions for the best experience!
