#!/bin/bash

# n8n Management Script for Linux/macOS
# Usage: ./manage.sh [command] [options]

set -e

COMMAND="${1:-help}"
OPTION="$2"
DEV_MODE=false
PROD_MODE=false
FOLLOW_LOGS=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_MODE=true
            shift
            ;;
        --production)
            PROD_MODE=true
            shift
            ;;
        --follow)
            FOLLOW_LOGS=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

show_help() {
    cat << 'EOF'
🚀 n8n Management Script
========================

Usage: ./manage.sh [command] [options]

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
  --dev       Use development configuration
  --production Use production configuration
  --follow    Follow logs (for logs command)

Examples:
  ./manage.sh start --dev
  ./manage.sh logs n8n --follow
  ./manage.sh scale 3
  ./manage.sh backup
  ./manage.sh restore backup-2025-01-15

EOF
}

get_compose_command() {
    local cmd="docker-compose"
    
    if [ "$DEV_MODE" = true ]; then
        cmd="$cmd -f docker-compose.yml -f docker-compose.dev.yml"
    elif [ "$PROD_MODE" = true ]; then
        cmd="$cmd --profile production"
    fi
    
    echo "$cmd"
}

start_services() {
    echo "🚀 Starting n8n services..."
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ Services started successfully!"
        echo "🌐 n8n is available at: http://localhost:5678"
        
        if [ "$DEV_MODE" = true ]; then
            echo "🔧 PgAdmin is available at: http://localhost:8081"
        fi
    fi
}

stop_services() {
    echo "🛑 Stopping n8n services..."
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd down
    
    if [ $? -eq 0 ]; then
        echo "✅ Services stopped successfully!"
    fi
}

restart_services() {
    echo "🔄 Restarting n8n services..."
    stop_services
    sleep 2
    start_services
}

show_status() {
    echo "📊 Service Status:"
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd ps
    
    echo ""
    echo "💾 Volume Usage:"
    docker system df -v | grep n8n || true
    
    echo ""
    echo "🔗 Quick Links:"
    echo "   n8n:      http://localhost:5678"
    if [ "$DEV_MODE" = true ]; then
        echo "   PgAdmin:  http://localhost:8081"
    fi
}

show_logs() {
    local service="$OPTION"
    local follow_flag=""
    
    if [ "$FOLLOW_LOGS" = true ]; then
        follow_flag="-f"
    else
        follow_flag="--tail=100"
    fi
    
    echo "📜 Showing logs for: ${service:-all services}"
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd logs $follow_flag $service
}

update_services() {
    echo "⬆️ Updating n8n services..."
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd pull
    $compose_cmd up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ Services updated successfully!"
    fi
}

backup_data() {
    echo "💾 Creating backup..."
    ./scripts/backup.sh
}

restore_data() {
    if [ -z "$OPTION" ]; then
        echo "❌ Please specify backup name or path"
        echo "Usage: ./manage.sh restore <backup-name>"
        return 1
    fi
    
    echo "📥 Restoring from backup: $OPTION"
    ./scripts/restore.sh "$OPTION"
}

reset_data() {
    echo "⚠️ WARNING: This will delete ALL data!"
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "🗑️ Resetting all data..."
        
        local compose_cmd
        compose_cmd=$(get_compose_command)
        $compose_cmd down -v
        
        # Remove all volumes
        docker volume rm n8n_n8n_data n8n_postgres_data n8n_redis_data -f 2>/dev/null || true
        
        echo "✅ All data reset. Run 'start' to initialize fresh setup."
    else
        echo "❌ Reset cancelled."
    fi
}

scale_workers() {
    if [[ ! "$OPTION" =~ ^[0-9]+$ ]]; then
        echo "❌ Please specify number of workers (e.g., 3)"
        echo "Usage: ./manage.sh scale <number>"
        return 1
    fi
    
    echo "⚖️ Scaling workers to $OPTION instances..."
    
    local compose_cmd
    compose_cmd=$(get_compose_command)
    $compose_cmd up -d --scale n8n-worker="$OPTION"
    
    if [ $? -eq 0 ]; then
        echo "✅ Workers scaled successfully!"
    fi
}

# Main command execution
case "$COMMAND" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_services
        ;;
    backup)
        backup_data
        ;;
    restore)
        restore_data
        ;;
    reset)
        reset_data
        ;;
    scale)
        scale_workers
        ;;
    help|*)
        show_help
        ;;
esac
