# n8n Management Script for Windows PowerShell
# Usage: .\manage.ps1 [command] [options]

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "update", "backup", "restore", "reset", "scale", "help")]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Option = "",
    
    [switch]$Dev,
    [switch]$Production,
    [switch]$Follow
)

function Show-Help {
    Write-Host @"
🚀 n8n Management Script
========================

Usage: .\manage.ps1 [command] [options]

Commands:
  start       Start n8n services
  stop        Stop n8n services
  restart     Restart n8n services
  status      Show service status
  logs        Show service logs
  update      Update to latest versions
  backup      Create backup
  restore     Restore from backup
  reset       Reset all data (⚠️ DESTRUCTIVE!)
  scale       Scale worker processes
  help        Show this help

Options:
  -Dev        Use development configuration
  -Production Use production configuration
  -Follow     Follow logs (for logs command)

Examples:
  .\manage.ps1 start -Dev
  .\manage.ps1 logs n8n -Follow
  .\manage.ps1 scale 3
  .\manage.ps1 backup
  .\manage.ps1 restore backup-2025-01-15

"@ -ForegroundColor Cyan
}

function Get-ComposeCommand {
    $cmd = "docker-compose"
    
    if ($Dev) {
        $cmd += " -f docker-compose.yml -f docker-compose.dev.yml"
    } elseif ($Production) {
        $cmd += " --profile production"
    }
    
    return $cmd
}

function Start-Services {
    Write-Host "🚀 Starting n8n services..." -ForegroundColor Green
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd up -d"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services started successfully!" -ForegroundColor Green
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Blue
        
        if ($Dev) {
            Write-Host "🔧 PgAdmin is available at: http://localhost:8081" -ForegroundColor Blue
        }
    }
}

function Stop-Services {
    Write-Host "🛑 Stopping n8n services..." -ForegroundColor Yellow
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd down"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services stopped successfully!" -ForegroundColor Green
    }
}

function Restart-Services {
    Write-Host "🔄 Restarting n8n services..." -ForegroundColor Blue
    Stop-Services
    Start-Sleep 2
    Start-Services
}

function Show-Status {
    Write-Host "📊 Service Status:" -ForegroundColor Blue
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd ps"
    
    Write-Host "`n💾 Volume Usage:" -ForegroundColor Blue
    docker system df -v | Select-String "n8n"
    
    Write-Host "`n🔗 Quick Links:" -ForegroundColor Blue
    Write-Host "   n8n:      http://localhost:5678" -ForegroundColor Gray
    if ($Dev) {
        Write-Host "   PgAdmin:  http://localhost:8081" -ForegroundColor Gray
    }
}

function Show-Logs {
    $service = if ($Option) { $Option } else { "" }
    $followFlag = if ($Follow) { "-f" } else { "--tail=100" }
    
    Write-Host "📜 Showing logs for: $($service -or 'all services')" -ForegroundColor Blue
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd logs $followFlag $service"
}

function Update-Services {
    Write-Host "⬆️ Updating n8n services..." -ForegroundColor Blue
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd pull"
    Invoke-Expression "$composeCmd up -d"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services updated successfully!" -ForegroundColor Green
    }
}

function Backup-Data {
    Write-Host "💾 Creating backup..." -ForegroundColor Blue
    & ".\scripts\backup.ps1"
}

function Restore-Data {
    if (-not $Option) {
        Write-Host "❌ Please specify backup name or path" -ForegroundColor Red
        Write-Host "Usage: .\manage.ps1 restore <backup-name>" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📥 Restoring from backup: $Option" -ForegroundColor Blue
    & ".\scripts\restore.ps1" $Option
}

function Reset-Data {
    Write-Host "⚠️ WARNING: This will delete ALL data!" -ForegroundColor Red
    $confirm = Read-Host "Type 'yes' to confirm"
    
    if ($confirm -eq "yes") {
        Write-Host "🗑️ Resetting all data..." -ForegroundColor Red
        
        $composeCmd = Get-ComposeCommand
        Invoke-Expression "$composeCmd down -v"
        
        # Remove all volumes
        docker volume rm n8n_n8n_data n8n_postgres_data n8n_redis_data -f 2>$null
        
        Write-Host "✅ All data reset. Run 'start' to initialize fresh setup." -ForegroundColor Green
    } else {
        Write-Host "❌ Reset cancelled." -ForegroundColor Yellow
    }
}

function Set-WorkerScale {
    if (-not $Option -or $Option -notmatch '^\d+$') {
        Write-Host "❌ Please specify number of workers (e.g., 3)" -ForegroundColor Red
        Write-Host "Usage: .\manage.ps1 scale <number>" -ForegroundColor Yellow
        return
    }
    
    Write-Host "⚖️ Scaling workers to $Option instances..." -ForegroundColor Blue
    
    $composeCmd = Get-ComposeCommand
    Invoke-Expression "$composeCmd up -d --scale n8n-worker=$Option"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Workers scaled successfully!" -ForegroundColor Green
    }
}

# Main command execution
switch ($Command) {
    "start"   { Start-Services }
    "stop"    { Stop-Services }
    "restart" { Restart-Services }
    "status"  { Show-Status }
    "logs"    { Show-Logs }
    "update"  { Update-Services }
    "backup"  { Backup-Data }
    "restore" { Restore-Data }
    "reset"   { Reset-Data }
    "scale"   { Set-WorkerScale }
    "help"    { Show-Help }
    default   { Show-Help }
}
