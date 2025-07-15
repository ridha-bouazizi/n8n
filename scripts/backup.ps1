# n8n Backup Script for Windows PowerShell
# Usage: .\backup.ps1 [backup-name]

param(
    [string]$BackupName = "backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
)

Write-Host "🔄 Starting n8n backup process..." -ForegroundColor Green

# Create backup directory if it doesn't exist
$BackupDir = ".\backups"
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force
    Write-Host "📁 Created backup directory: $BackupDir" -ForegroundColor Yellow
}

$BackupPath = "$BackupDir\$BackupName"

try {
    Write-Host "📦 Creating backup directory: $BackupPath" -ForegroundColor Blue
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

    # Backup PostgreSQL database
    Write-Host "🗄️ Backing up PostgreSQL database..." -ForegroundColor Blue
    $env:PGPASSWORD = $(docker-compose exec -T postgres printenv POSTGRES_PASSWORD 2>$null)
    docker-compose exec -T postgres pg_dump -U n8n -d n8n | Out-File -FilePath "$BackupPath\database.sql" -Encoding UTF8

    # Backup n8n data volume
    Write-Host "📁 Backing up n8n data volume..." -ForegroundColor Blue
    docker run --rm -v n8n_n8n_data:/data -v ${PWD}/backups:/backup alpine tar czf /backup/$BackupName/n8n_data.tar.gz -C /data .

    # Backup configuration files
    Write-Host "⚙️ Backing up configuration files..." -ForegroundColor Blue
    Copy-Item ".env" "$BackupPath\" -ErrorAction SilentlyContinue
    Copy-Item "docker-compose.yml" "$BackupPath\" -ErrorAction SilentlyContinue
    Copy-Item "docker-compose.dev.yml" "$BackupPath\" -ErrorAction SilentlyContinue

    # Create backup info file
    @"
Backup Information
==================
Date: $(Get-Date)
n8n Version: $(docker-compose exec -T n8n n8n --version 2>$null)
Backup Contents:
- PostgreSQL database (database.sql)
- n8n data volume (n8n_data.tar.gz)
- Configuration files (.env, docker-compose.yml)

Restore Instructions:
1. Stop n8n: docker-compose down
2. Run restore script: .\scripts\restore.ps1 $BackupName
"@ | Out-File -FilePath "$BackupPath\backup-info.txt" -Encoding UTF8

    # Create compressed archive
    Write-Host "🗜️ Creating compressed archive..." -ForegroundColor Blue
    Compress-Archive -Path "$BackupPath\*" -DestinationPath "$BackupDir\$BackupName.zip" -Force
    
    # Remove temporary directory
    Remove-Item -Path $BackupPath -Recurse -Force

    Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
    Write-Host "📦 Backup file: $BackupDir\$BackupName.zip" -ForegroundColor Green
    
    # Show backup size
    $BackupSize = [math]::Round((Get-Item "$BackupDir\$BackupName.zip").Length / 1MB, 2)
    Write-Host "📏 Backup size: $BackupSize MB" -ForegroundColor Gray

} catch {
    Write-Host "❌ Backup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Cleanup old backups (keep last 10)
Write-Host "🧹 Cleaning up old backups..." -ForegroundColor Blue
Get-ChildItem "$BackupDir\*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -Force
Write-Host "✨ Backup process completed!" -ForegroundColor Green
