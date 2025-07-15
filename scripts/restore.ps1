# n8n Restore Script for Windows PowerShell
# Usage: .\restore.ps1 <backup-name-or-path>

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath
)

Write-Host "🔄 Starting n8n restore process..." -ForegroundColor Green

# Determine backup file path
if (Test-Path $BackupPath) {
    $FullBackupPath = $BackupPath
} elseif (Test-Path ".\backups\$BackupPath") {
    $FullBackupPath = ".\backups\$BackupPath"
} elseif (Test-Path ".\backups\$BackupPath.zip") {
    $FullBackupPath = ".\backups\$BackupPath.zip"
} else {
    Write-Host "❌ Backup file not found: $BackupPath" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Using backup file: $FullBackupPath" -ForegroundColor Blue

try {
    # Stop services
    Write-Host "🛑 Stopping n8n services..." -ForegroundColor Yellow
    docker-compose down

    # Create temporary restore directory
    $TempDir = ".\temp-restore-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    # Extract backup
    Write-Host "📁 Extracting backup..." -ForegroundColor Blue
    if ($FullBackupPath.EndsWith('.zip')) {
        Expand-Archive -Path $FullBackupPath -DestinationPath $TempDir -Force
    } else {
        # Assume it's a directory
        Copy-Item -Path "$FullBackupPath\*" -Destination $TempDir -Recurse
    }

    # Start only database for restore
    Write-Host "🗄️ Starting database service..." -ForegroundColor Blue
    docker-compose up -d postgres redis
    Start-Sleep 10

    # Restore database
    if (Test-Path "$TempDir\database.sql") {
        Write-Host "🔄 Restoring PostgreSQL database..." -ForegroundColor Blue
        
        # Drop and recreate database
        docker-compose exec -T postgres psql -U n8n -d postgres -c "DROP DATABASE IF EXISTS n8n;"
        docker-compose exec -T postgres psql -U n8n -d postgres -c "CREATE DATABASE n8n OWNER n8n;"
        
        # Restore database
        Get-Content "$TempDir\database.sql" | docker-compose exec -T postgres psql -U n8n -d n8n
    } else {
        Write-Host "⚠️ No database backup found in archive" -ForegroundColor Yellow
    }

    # Restore n8n data volume
    if (Test-Path "$TempDir\n8n_data.tar.gz") {
        Write-Host "📁 Restoring n8n data volume..." -ForegroundColor Blue
        
        # Remove existing volume and recreate
        docker volume rm n8n_n8n_data -f 2>$null
        docker volume create n8n_n8n_data
        
        # Restore data
        docker run --rm -v n8n_n8n_data:/data -v ${PWD}/${TempDir}:/backup alpine tar xzf /backup/n8n_data.tar.gz -C /data
    } else {
        Write-Host "⚠️ No n8n data backup found in archive" -ForegroundColor Yellow
    }

    # Restore configuration files (with backup)
    if (Test-Path "$TempDir\.env") {
        Write-Host "⚙️ Restoring configuration files..." -ForegroundColor Blue
        
        # Backup current config
        if (Test-Path ".env") {
            Copy-Item ".env" ".env.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
        
        Copy-Item "$TempDir\.env" "." -Force
        
        if (Test-Path "$TempDir\docker-compose.yml") {
            Copy-Item "$TempDir\docker-compose.yml" "." -Force
        }
    }

    # Start all services
    Write-Host "🚀 Starting all services..." -ForegroundColor Blue
    docker-compose up -d

    # Wait for services to be healthy
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Blue
    $maxWait = 60
    $waited = 0
    do {
        Start-Sleep 5
        $waited += 5
        $healthStatus = docker-compose ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "n8n" } | Select-Object -ExpandProperty Health
    } while ($healthStatus -ne "healthy" -and $waited -lt $maxWait)

    if ($healthStatus -eq "healthy") {
        Write-Host "✅ Restore completed successfully!" -ForegroundColor Green
        Write-Host "🌐 n8n is available at: http://localhost:5678" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Restore completed but services may still be starting..." -ForegroundColor Yellow
        Write-Host "🔍 Check service status with: docker-compose ps" -ForegroundColor Blue
    }

} catch {
    Write-Host "❌ Restore failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 You may need to manually start services: docker-compose up -d" -ForegroundColor Yellow
    exit 1
} finally {
    # Cleanup temporary directory
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
}

Write-Host "✨ Restore process completed!" -ForegroundColor Green
