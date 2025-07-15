#!/bin/bash

# n8n Health Check Script for Linux/macOS
# This script checks the health of all n8n services

set -e

DETAILED=false
JSON_OUTPUT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            cat << 'EOF'
Usage: ./health-check.sh [OPTIONS]

Options:
  --detailed    Show detailed information including resource usage
  --json        Output results in JSON format
  -h, --help    Show this help message

Examples:
  ./health-check.sh
  ./health-check.sh --detailed
  ./health-check.sh --json
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

test_service_health() {
    local service_name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    local response
    local status_code
    local response_time
    
    if response=$(curl -s -w "%{http_code}|%{time_total}" --max-time 10 "$url" 2>/dev/null); then
        status_code=$(echo "$response" | tail -c 10 | cut -d'|' -f1)
        response_time=$(echo "$response" | tail -c 10 | cut -d'|' -f2)
        
        if [ "$status_code" = "$expected_status" ]; then
            echo "healthy|$status_code|$response_time"
        else
            echo "unhealthy|$status_code|Unexpected status code"
        fi
    else
        echo "unhealthy|0|Connection failed"
    fi
}

get_docker_service_status() {
    if command -v docker-compose > /dev/null 2>&1; then
        docker-compose ps --format json 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

get_system_resources() {
    if command -v docker > /dev/null 2>&1; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep n8n || true
    fi
}

# Main health check
if [ "$JSON_OUTPUT" = false ]; then
    echo "🏥 n8n Health Check"
    echo "==================="
fi

# Initialize arrays for JSON output
docker_services=()
web_checks=()
overall_status="healthy"

# Check Docker services
if [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "🐳 Docker Services:"
fi

docker_status=$(get_docker_service_status)
if [ "$docker_status" != "[]" ]; then
    while IFS= read -r service; do
        if [ -n "$service" ]; then
            service_name=$(echo "$service" | jq -r '.Service // .Name' 2>/dev/null || echo "unknown")
            state=$(echo "$service" | jq -r '.State // .Status' 2>/dev/null || echo "unknown")
            health=$(echo "$service" | jq -r '.Health // ""' 2>/dev/null || echo "")
            
            if [ "$JSON_OUTPUT" = false ]; then
                if [[ "$health" == "healthy" ]] || [[ "$state" == "running" && -z "$health" ]]; then
                    echo "  ✅ $service_name: $state $health"
                else
                    echo "  ❌ $service_name: $state $health"
                    overall_status="unhealthy"
                fi
            fi
            
            docker_services+=("{\"service\":\"$service_name\",\"state\":\"$state\",\"health\":\"$health\"}")
        fi
    done <<< "$(echo "$docker_status" | jq -c '.[]' 2>/dev/null || echo "")"
fi

# Check web endpoints
if [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "🌐 Web Endpoints:"
fi

web_endpoints=(
    "n8n Main|http://localhost:5678/healthz"
    "n8n API|http://localhost:5678/rest/active-workflows"
)

for endpoint in "${web_endpoints[@]}"; do
    IFS='|' read -r name url <<< "$endpoint"
    result=$(test_service_health "$name" "$url")
    
    IFS='|' read -r status status_code error <<< "$result"
    
    if [ "$JSON_OUTPUT" = false ]; then
        if [ "$status" = "healthy" ]; then
            echo "  ✅ $name: HTTP $status_code"
        else
            echo "  ❌ $name: $error"
            overall_status="unhealthy"
        fi
    fi
    
    web_checks+=("{\"service\":\"$name\",\"status\":\"$status\",\"status_code\":\"$status_code\",\"error\":\"$error\"}")
done

# Check database connectivity
if [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "🗄️ Database:"
fi

db_status="unknown"
if docker-compose exec -T postgres pg_isready -h localhost -U n8n -d n8n > /dev/null 2>&1; then
    db_status="healthy"
    if [ "$JSON_OUTPUT" = false ]; then
        echo "  ✅ PostgreSQL: Connected"
    fi
else
    db_status="unhealthy"
    overall_status="unhealthy"
    if [ "$JSON_OUTPUT" = false ]; then
        echo "  ❌ PostgreSQL: Connection failed"
    fi
fi

# Check Redis connectivity
if [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "📦 Cache:"
fi

redis_status="unknown"
redis_response=$(docker-compose exec -T redis redis-cli ping 2>/dev/null || echo "ERROR")
if [ "$redis_response" = "PONG" ]; then
    redis_status="healthy"
    if [ "$JSON_OUTPUT" = false ]; then
        echo "  ✅ Redis: Connected"
    fi
else
    redis_status="unhealthy"
    overall_status="unhealthy"
    if [ "$JSON_OUTPUT" = false ]; then
        echo "  ❌ Redis: Connection failed"
    fi
fi

# Show detailed information if requested
if [ "$DETAILED" = true ] && [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "📊 Resource Usage:"
    resources=$(get_system_resources)
    if [ -n "$resources" ]; then
        echo "$resources" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        echo "  No resource information available"
    fi
    
    echo ""
    echo "📁 Volume Usage:"
    volume_info=$(docker system df -v 2>/dev/null | grep n8n || echo "No n8n volumes found")
    echo "$volume_info" | while IFS= read -r line; do
        echo "  $line"
    done
    
    echo ""
    echo "🔗 Service URLs:"
    echo "  n8n Interface: http://localhost:5678"
    echo "  n8n API: http://localhost:5678/rest/"
    echo "  Health Check: http://localhost:5678/healthz"
fi

# Output JSON if requested
if [ "$JSON_OUTPUT" = true ]; then
    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "overall_status": "$overall_status",
  "services": [$(IFS=,; echo "${docker_services[*]}")],
  "web_endpoints": [$(IFS=,; echo "${web_checks[*]}")],
  "database": {
    "postgres": "$db_status",
    "redis": "$redis_status"
  }
}
EOF
else
    echo ""
    echo "✨ Health check completed!"
fi
