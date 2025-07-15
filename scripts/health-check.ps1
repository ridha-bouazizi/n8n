# n8n Health Check Script
# This script checks the health of all n8n services

param(
    [switch]$Detailed,
    [switch]$Json
)

function Test-ServiceHealth {
    param($ServiceName, $Url, $ExpectedStatus = 200)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10 -UseBasicParsing
        return @{
            Service = $ServiceName
            Status = "Healthy"
            StatusCode = $response.StatusCode
            ResponseTime = $response.Headers.'X-Response-Time'
        }
    } catch {
        return @{
            Service = $ServiceName
            Status = "Unhealthy"
            Error = $_.Exception.Message
            StatusCode = $null
        }
    }
}

function Get-DockerServiceStatus {
    try {
        $services = docker-compose ps --format json | ConvertFrom-Json
        return $services | ForEach-Object {
            @{
                Service = $_.Service
                State = $_.State
                Health = $_.Health
                Ports = $_.Ports
            }
        }
    } catch {
        Write-Warning "Could not get Docker service status: $($_.Exception.Message)"
        return @()
    }
}

function Get-SystemResources {
    try {
        $dockerStats = docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | ConvertFrom-Csv -Delimiter "`t" -Header "Container", "CPU", "Memory"
        return $dockerStats | Where-Object { $_.Container -match "n8n" }
    } catch {
        Write-Warning "Could not get system resources: $($_.Exception.Message)"
        return @()
    }
}

# Main health check
Write-Host "🏥 n8n Health Check" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

$healthResults = @()

# Check Docker services
Write-Host "`n🐳 Docker Services:" -ForegroundColor Blue
$dockerServices = Get-DockerServiceStatus
$dockerServices | ForEach-Object {
    $status = if ($_.Health -eq "healthy" -or ($_.State -eq "running" -and $_.Health -eq "")) { "✅" } else { "❌" }
    Write-Host "  $status $($_.Service): $($_.State) $($_.Health)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

# Check web endpoints
Write-Host "`n🌐 Web Endpoints:" -ForegroundColor Blue
$webChecks = @(
    @{ Name = "n8n Main"; Url = "http://localhost:5678/healthz" },
    @{ Name = "n8n API"; Url = "http://localhost:5678/rest/active-workflows" }
)

foreach ($check in $webChecks) {
    $result = Test-ServiceHealth $check.Name $check.Url
    $healthResults += $result
    
    $status = if ($result.Status -eq "Healthy") { "✅" } else { "❌" }
    if ($result.Status -eq "Healthy") {
        Write-Host "  $status $($check.Name): HTTP $($result.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "  $status $($check.Name): $($result.Error)" -ForegroundColor Red
    }
}

# Check database connectivity
Write-Host "`n🗄️ Database:" -ForegroundColor Blue
try {
    $dbTest = docker-compose exec -T postgres pg_isready -h localhost -U n8n -d n8n 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PostgreSQL: Connected" -ForegroundColor Green
    } else {
        Write-Host "  ❌ PostgreSQL: Connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Redis connectivity
Write-Host "`n📦 Cache:" -ForegroundColor Blue
try {
    $redisTest = docker-compose exec -T redis redis-cli ping 2>$null
    if ($redisTest -eq "PONG") {
        Write-Host "  ✅ Redis: Connected" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Redis: Connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Redis: $($_.Exception.Message)" -ForegroundColor Red
}

# Show detailed information if requested
if ($Detailed) {
    Write-Host "`n📊 Resource Usage:" -ForegroundColor Blue
    $resources = Get-SystemResources
    $resources | ForEach-Object {
        Write-Host "  $($_.Container): CPU $($_.CPU), Memory $($_.Memory)" -ForegroundColor Gray
    }
    
    Write-Host "`n📁 Volume Usage:" -ForegroundColor Blue
    try {
        $volumes = docker system df -v | Select-String "n8n" | ForEach-Object { $_.Line.Trim() }
        $volumes | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Could not retrieve volume information" -ForegroundColor Yellow
    }
    
    Write-Host "`n🔗 Service URLs:" -ForegroundColor Blue
    Write-Host "  n8n Interface: http://localhost:5678" -ForegroundColor Gray
    Write-Host "  n8n API: http://localhost:5678/rest/" -ForegroundColor Gray
    Write-Host "  Health Check: http://localhost:5678/healthz" -ForegroundColor Gray
}

# Output JSON if requested
if ($Json) {
    $output = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OverallStatus = if ($healthResults | Where-Object { $_.Status -eq "Unhealthy" }) { "Unhealthy" } else { "Healthy" }
        Services = $dockerServices
        WebEndpoints = $healthResults
    }
    
    if ($Detailed) {
        $output.Resources = $resources
    }
    
    $output | ConvertTo-Json -Depth 3
}

Write-Host "`n✨ Health check completed!" -ForegroundColor Green
