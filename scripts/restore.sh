#!/bin/bash

# n8n Restore Script for Linux/macOS
# Usage: ./restore.sh <backup-name-or-path>

set -e

if [ $# -eq 0 ]; then
    echo "❌ Please specify backup name or path"
    echo "Usage: ./restore.sh <backup-name-or-path>"
    exit 1
fi

BACKUP_PATH="$1"

echo "🔄 Starting n8n restore process..."

# Determine backup file path
if [ -f "$BACKUP_PATH" ]; then
    FULL_BACKUP_PATH="$BACKUP_PATH"
elif [ -f "./backups/$BACKUP_PATH" ]; then
    FULL_BACKUP_PATH="./backups/$BACKUP_PATH"
elif [ -f "./backups/$BACKUP_PATH.tar.gz" ]; then
    FULL_BACKUP_PATH="./backups/$BACKUP_PATH.tar.gz"
else
    echo "❌ Backup file not found: $BACKUP_PATH"
    exit 1
fi

echo "📦 Using backup file: $FULL_BACKUP_PATH"

# Function to handle errors
cleanup_on_error() {
    echo "❌ Restore failed: $1"
    echo "🔧 You may need to manually start services: docker-compose up -d"
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    exit 1
}

# Trap errors
trap 'cleanup_on_error "Unexpected error occurred"' ERR

# Stop services
echo "🛑 Stopping n8n services..."
docker-compose down

# Create temporary restore directory
TEMP_DIR="./temp-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TEMP_DIR"

# Extract backup
echo "📁 Extracting backup..."
if [[ "$FULL_BACKUP_PATH" == *.tar.gz ]]; then
    tar xzf "$FULL_BACKUP_PATH" -C "$TEMP_DIR" --strip-components=1
else
    # Assume it's a directory
    cp -r "$FULL_BACKUP_PATH"/* "$TEMP_DIR/"
fi

# Start only database for restore
echo "🗄️ Starting database service..."
docker-compose up -d postgres redis
sleep 10

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -h localhost -U n8n -d postgres > /dev/null 2>&1; then
        break
    fi
    if [ $i -eq 30 ]; then
        cleanup_on_error "PostgreSQL failed to start"
    fi
    sleep 2
done

# Restore database
if [ -f "$TEMP_DIR/database.sql" ]; then
    echo "🔄 Restoring PostgreSQL database..."
    
    # Drop and recreate database
    docker-compose exec -T postgres psql -U n8n -d postgres -c "DROP DATABASE IF EXISTS n8n;" || true
    docker-compose exec -T postgres psql -U n8n -d postgres -c "CREATE DATABASE n8n OWNER n8n;"
    
    # Restore database
    docker-compose exec -T postgres psql -U n8n -d n8n < "$TEMP_DIR/database.sql"
else
    echo "⚠️ No database backup found in archive"
fi

# Restore n8n data volume
if [ -f "$TEMP_DIR/n8n_data.tar.gz" ]; then
    echo "📁 Restoring n8n data volume..."
    
    # Remove existing volume and recreate
    docker volume rm n8n_n8n_data -f 2>/dev/null || true
    docker volume create n8n_n8n_data
    
    # Restore data
    docker run --rm -v n8n_n8n_data:/data -v "$(pwd)/${TEMP_DIR}":/backup alpine tar xzf /backup/n8n_data.tar.gz -C /data
else
    echo "⚠️ No n8n data backup found in archive"
fi

# Restore configuration files (with backup)
if [ -f "$TEMP_DIR/.env" ]; then
    echo "⚙️ Restoring configuration files..."
    
    # Backup current config
    if [ -f ".env" ]; then
        cp ".env" ".env.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    cp "$TEMP_DIR/.env" "."
    
    if [ -f "$TEMP_DIR/docker-compose.yml" ]; then
        cp "$TEMP_DIR/docker-compose.yml" "."
    fi
fi

# Start all services
echo "🚀 Starting all services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    sleep 5
    WAITED=$((WAITED + 5))
    
    # Check if n8n is responding
    if curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
        echo "✅ Restore completed successfully!"
        echo "🌐 n8n is available at: http://localhost:5678"
        break
    fi
    
    if [ $WAITED -eq $MAX_WAIT ]; then
        echo "⚠️ Restore completed but services may still be starting..."
        echo "🔍 Check service status with: docker-compose ps"
        break
    fi
done

# Cleanup temporary directory
rm -rf "$TEMP_DIR"

echo "✨ Restore process completed!"
