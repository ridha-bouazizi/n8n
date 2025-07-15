#!/bin/bash

# n8n Project Makefile equivalent for Linux/macOS
# Usage: ./make.sh [target]

set -e

TARGET="${1:-help}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

write_target() {
    echo -e "${GREEN}🎯 $1${NC}"
}

write_step() {
    echo -e "   ${BLUE}$1${NC}"
}

show_help() {
    cat << EOF
${CYAN}🚀 n8n Enhanced Setup - Available Targets
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
  ./make.sh install
  ./make.sh dev
  ./make.sh backup
  ./make.sh scale 3
${NC}
EOF
}

check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed or not in PATH${NC}"
        exit 1
    fi
}

case "$TARGET" in
    help)
        show_help
        ;;
    
    install)
        write_target "Setting up n8n enhanced environment"
        
        write_step "Checking prerequisites..."
        check_prerequisites
        
        write_step "Creating .env file from example..."
        if [ ! -f ".env" ]; then
            cp ".env.example" ".env"
            echo -e "   ${YELLOW}⚠️  Please edit .env file with your configuration${NC}"
        else
            echo -e "   ${GRAY}.env file already exists${NC}"
        fi
        
        write_step "Creating necessary directories..."
        for dir in shared workflows backups logs certs; do
            if [ ! -d "$dir" ]; then
                mkdir -p "$dir"
                echo -e "   ${GRAY}Created directory: $dir${NC}"
            fi
        done
        
        write_step "Pulling Docker images..."
        docker-compose pull
        
        write_step "Setting up database..."
        docker-compose up -d postgres redis
        sleep 10
        
        write_step "Starting n8n..."
        docker-compose up -d
        
        echo ""
        echo -e "${GREEN}✅ Setup completed!${NC}"
        echo -e "${BLUE}🌐 n8n is available at: http://localhost:5678${NC}"
        echo -e "${YELLOW}📚 Next steps: Edit .env file and restart with 'restart' target${NC}"
        ;;
    
    start)
        write_target "Starting n8n services"
        docker-compose up -d
        echo -e "${BLUE}🌐 n8n is available at: http://localhost:5678${NC}"
        ;;
    
    stop)
        write_target "Stopping n8n services"
        docker-compose down
        ;;
    
    restart)
        write_target "Restarting n8n services"
        docker-compose restart
        ;;
    
    dev)
        write_target "Starting in development mode"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
        echo -e "${BLUE}🌐 n8n is available at: http://localhost:5678${NC}"
        echo -e "${BLUE}🔧 PgAdmin is available at: http://localhost:8081${NC}"
        ;;
    
    prod)
        write_target "Starting in production mode"
        docker-compose --profile production up -d
        echo -e "${BLUE}🌐 n8n is available at: http://localhost:5678${NC}"
        echo -e "${BLUE}📊 Traefik dashboard: http://localhost:8080${NC}"
        ;;
    
    logs)
        write_target "Showing service logs"
        docker-compose logs -f --tail=100
        ;;
    
    status)
        write_target "Checking service status"
        docker-compose ps
        echo ""
        ./scripts/health-check.sh
        ;;
    
    backup)
        write_target "Creating backup"
        ./scripts/backup.sh
        ;;
    
    restore)
        write_target "Restoring from backup"
        read -p "Enter backup name: " backup_name
        if [ -n "$backup_name" ]; then
            ./scripts/restore.sh "$backup_name"
        else
            echo -e "${RED}❌ Backup name required${NC}"
        fi
        ;;
    
    update)
        write_target "Updating services"
        docker-compose pull
        docker-compose up -d
        ;;
    
    clean)
        write_target "Cleaning up Docker resources"
        docker system prune -f
        docker volume prune -f
        ;;
    
    reset)
        write_target "Resetting all data"
        echo -e "${RED}⚠️ WARNING: This will delete ALL data!${NC}"
        read -p "Type 'CONFIRM' to proceed: " confirm
        if [ "$confirm" = "CONFIRM" ]; then
            docker-compose down -v
            docker volume rm n8n_n8n_data n8n_postgres_data n8n_redis_data -f 2>/dev/null || true
            echo -e "${GREEN}✅ All data reset${NC}"
        else
            echo -e "${YELLOW}❌ Reset cancelled${NC}"
        fi
        ;;
    
    test)
        write_target "Running health checks"
        ./scripts/health-check.sh --detailed
        ;;
    
    scale)
        write_target "Scaling worker processes"
        read -p "Enter number of workers: " workers
        if [[ "$workers" =~ ^[0-9]+$ ]]; then
            docker-compose up -d --scale n8n-worker="$workers"
        else
            echo -e "${RED}❌ Please enter a valid number${NC}"
        fi
        ;;
    
    *)
        echo -e "${RED}❌ Unknown target: $TARGET${NC}"
        show_help
        ;;
esac
