#!/bin/bash

# n8n Backup Script for Linux/macOS
# Usage: ./backup.sh [backup-name]

set -e

BACKUP_NAME="${1:-backup-$(date +%Y-%m-%d-%H%M)}"
BACKUP_DIR="./backups"

echo "🔄 Starting n8n backup process..."

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "📁 Created backup directory: $BACKUP_DIR"
fi

BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Create backup directory
echo "📦 Creating backup directory: $BACKUP_PATH"
mkdir -p "$BACKUP_PATH"

# Function to handle errors
cleanup_on_error() {
    echo "❌ Backup failed: $1"
    rm -rf "$BACKUP_PATH" 2>/dev/null || true
    exit 1
}

# Trap errors
trap 'cleanup_on_error "Unexpected error occurred"' ERR

# Backup PostgreSQL database
echo "🗄️ Backing up PostgreSQL database..."
if ! docker-compose exec -T postgres pg_dump -U n8n -d n8n > "$BACKUP_PATH/database.sql"; then
    cleanup_on_error "Failed to backup PostgreSQL database"
fi

# Backup n8n data volume
echo "📁 Backing up n8n data volume..."
if ! docker run --rm -v n8n_n8n_data:/data -v "$(pwd)/backups":/backup alpine tar czf "/backup/$BACKUP_NAME/n8n_data.tar.gz" -C /data .; then
    cleanup_on_error "Failed to backup n8n data volume"
fi

# Backup configuration files
echo "⚙️ Backing up configuration files..."
cp .env "$BACKUP_PATH/" 2>/dev/null || true
cp docker-compose.yml "$BACKUP_PATH/" 2>/dev/null || true
cp docker-compose.dev.yml "$BACKUP_PATH/" 2>/dev/null || true

# Get n8n version
N8N_VERSION=$(docker-compose exec -T n8n n8n --version 2>/dev/null | head -n1 || echo "Unknown")

# Create backup info file
cat > "$BACKUP_PATH/backup-info.txt" << EOF
Backup Information
==================
Date: $(date)
n8n Version: $N8N_VERSION
Backup Contents:
- PostgreSQL database (database.sql)
- n8n data volume (n8n_data.tar.gz)
- Configuration files (.env, docker-compose.yml)

Restore Instructions:
1. Stop n8n: docker-compose down
2. Run restore script: ./scripts/restore.sh $BACKUP_NAME
EOF

# Create compressed archive
echo "🗜️ Creating compressed archive..."
cd "$BACKUP_DIR"
tar czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd ..

echo "✅ Backup completed successfully!"
echo "📦 Backup file: $BACKUP_DIR/$BACKUP_NAME.tar.gz"

# Show backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)
echo "📏 Backup size: $BACKUP_SIZE"

# Cleanup old backups (keep last 10)
echo "🧹 Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t *.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
cd ..

echo "✨ Backup process completed!"
