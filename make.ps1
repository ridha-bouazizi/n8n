# n8n Project Makefile for Windows PowerShell
# Usage: .\make.ps1 [target]

param(
    [Parameter(Position=0)]
    [ValidateSet("help", "install", "start", "stop", "restart", "dev", "prod", "logs", "status", "backup", "restore", "update", "clean", "reset", "test", "scale")]
    [string]$Target = "help"
)

$ErrorActionPreference = "Stop"

function Write-Target {
    param($Message)
    Write-Host "🎯 $Message" -ForegroundColor Green
}

function Write-Step {
    param($Message)
    Write-Host "   $Message" -ForegroundColor Blue
}

function Show-Help {
    Write-Host @"
🚀 n8n Enhanced Setup - Available Targets
=========================================

Installation & Setup:
  install     Initial setup and configuration
  
Service Management:
  start       Start all services
  stop        Stop all services  
  restart     Restart all services
  dev         Start in development mode
  prod        Start in production mode
  
Monitoring & Logs:
  status      Show service status and health
  logs        Show service logs
  test        Run health checks
  
Maintenance:
  backup      Create backup of all data
  restore     Restore from backup (requires backup name)
  update      Update all services to latest versions
  clean       Clean up unused Docker resources
  reset       Reset all data (⚠️ DESTRUCTIVE!)
  
Scaling:
  scale       Scale worker processes (requires number)

Examples:
  .\make.ps1 install
  .\make.ps1 dev
  .\make.ps1 backup
  .\make.ps1 scale 3

"@ -ForegroundColor Cyan
}

switch ($Target) {
    "help" {
        Show-Help
    }
    
    "install" {
        Write-Target "Setting up n8n enhanced environment"
        
        Write-Step "Checking prerequisites..."
        if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker is not installed or not in PATH"
        }
        if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
            throw "Docker Compose is not installed or not in PATH"
        }
        
        Write-Step "Creating .env file from example..."
        if (!(Test-Path ".env")) {
            Copy-Item ".env.example" ".env"
            Write-Host "   ⚠️  Please edit .env file with your configuration" -ForegroundColor Yellow
        } else {
            Write-Host "   .env file already exists" -ForegroundColor Gray
        }
        
        Write-Step "Creating necessary directories..."
        @("shared", "workflows", "backups", "logs", "certs") | ForEach-Object {
            if (!(Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-Host "   Created directory: $_" -ForegroundColor Gray
            }
        }
        
        Write-Step "Pulling Docker images..."
        docker-compose pull
        
        Write-Step "Setting up database..."
        docker-compose up -d postgres redis
        Start-Sleep 10
        
        Write-Step "Starting n8n..."
        docker-compose up -d
        
        Write-Host ""
        Write-Host "✅ Setup completed!" -ForegroundColor Green
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Blue
        Write-Host "📚 Next steps: Edit .env file and restart with 'restart' target" -ForegroundColor Yellow
    }
    
    "start" {
        Write-Target "Starting n8n services"
        docker-compose up -d
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Blue
    }
    
    "stop" {
        Write-Target "Stopping n8n services"
        docker-compose down
    }
    
    "restart" {
        Write-Target "Restarting n8n services"
        docker-compose restart
    }
    
    "dev" {
        Write-Target "Starting in development mode"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Blue
        Write-Host "🔧 PgAdmin is available at: http://localhost:8081" -ForegroundColor Blue
    }
    
    "prod" {
        Write-Target "Starting in production mode"
        docker-compose --profile production up -d
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Blue
        Write-Host "📊 Traefik dashboard: http://localhost:8080" -ForegroundColor Blue
    }
    
    "logs" {
        Write-Target "Showing service logs"
        docker-compose logs -f --tail=100
    }
    
    "status" {
        Write-Target "Checking service status"
        docker-compose ps
        Write-Host ""
        & ".\scripts\health-check.ps1"
    }
    
    "backup" {
        Write-Target "Creating backup"
        & ".\scripts\backup.ps1"
    }
    
    "restore" {
        Write-Target "Restoring from backup"
        $backupName = Read-Host "Enter backup name"
        if ($backupName) {
            & ".\scripts\restore.ps1" $backupName
        } else {
            Write-Host "❌ Backup name required" -ForegroundColor Red
        }
    }
    
    "update" {
        Write-Target "Updating services"
        docker-compose pull
        docker-compose up -d
    }
    
    "clean" {
        Write-Target "Cleaning up Docker resources"
        docker system prune -f
        docker volume prune -f
    }
    
    "reset" {
        Write-Target "Resetting all data"
        Write-Host "⚠️ WARNING: This will delete ALL data!" -ForegroundColor Red
        $confirm = Read-Host "Type 'CONFIRM' to proceed"
        if ($confirm -eq "CONFIRM") {
            docker-compose down -v
            docker volume rm n8n_n8n_data n8n_postgres_data n8n_redis_data -f 2>$null
            Write-Host "✅ All data reset" -ForegroundColor Green
        } else {
            Write-Host "❌ Reset cancelled" -ForegroundColor Yellow
        }
    }
    
    "test" {
        Write-Target "Running health checks"
        & ".\scripts\health-check.ps1" -Detailed
    }
    
    "scale" {
        Write-Target "Scaling worker processes"
        $workers = Read-Host "Enter number of workers"
        if ($workers -match '^\d+$') {
            docker-compose up -d --scale n8n-worker=$workers
        } else {
            Write-Host "❌ Please enter a valid number" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "❌ Unknown target: $Target" -ForegroundColor Red
        Show-Help
    }
}
