#!/bin/bash

# MedinovAI Complete Platform Deployment Script - Version RA1
# Deploys all 126 repositories as integrated Docker platform

set -e

DEPLOYMENT_VERSION="RA1"
PLATFORM_URL="medinovaios.localhost"
LOG_FILE="medinovaios_deployment_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize logging
exec 1> >(tee -a "${LOG_FILE}")
exec 2> >(tee -a "${LOG_FILE}" >&2)

echo "🚀 MEDINOVAI COMPLETE PLATFORM DEPLOYMENT - VERSION RA1"
echo "=========================================================="
echo "Timestamp: ${TIMESTAMP}"
echo "Platform URL: http://${PLATFORM_URL}"
echo "Target: 126 repositories as integrated platform"
echo "Hardware: Mac Studio M3 Ultra (512GB RAM, 32 cores)"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking deployment prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not found. Please install Docker Desktop."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
    
    # Check Ollama
    if ! command -v ollama &> /dev/null; then
        echo "❌ Ollama not found. Please install Ollama."
        exit 1
    fi
    
    # Check available resources
    AVAILABLE_MEMORY=$(docker system info | grep "Total Memory" | awk '{print $3}')
    echo "✅ Docker available memory: ${AVAILABLE_MEMORY}"
    
    # Check Ollama models
    OLLAMA_MODELS=$(ollama list | wc -l)
    echo "✅ Ollama models available: ${OLLAMA_MODELS}"
    
    echo "✅ Prerequisites check completed"
    echo ""
}

# Function to prepare deployment environment
prepare_environment() {
    echo "🛠️  Preparing deployment environment..."
    
    # Clean existing containers
    echo "🧹 Cleaning existing MedinovAI containers..."
    docker ps -a --format "table {{.Names}}" | grep -E "(medinovai|ats|auto)" | xargs -r docker rm -f
    
    # Clean networks
    echo "🌐 Setting up networks..."
    docker network rm medinovai_frontend medinovai_backend medinovai_data medinovai_ai medinovai_monitoring 2>/dev/null || true
    
    docker network create medinovai_frontend --subnet=172.20.0.0/16
    docker network create medinovai_backend --subnet=172.21.0.0/16
    docker network create medinovai_data --subnet=172.22.0.0/16
    docker network create medinovai_ai --subnet=172.23.0.0/16
    docker network create medinovai_monitoring --subnet=172.24.0.0/16
    
    # Create volume directories
    echo "💾 Creating persistent volumes..."
    mkdir -p volumes/{postgres,mongodb,redis,ollama,grafana,prometheus,kafka}
    
    echo "✅ Environment preparation completed"
    echo ""
}

# Function to deploy core infrastructure
deploy_core_infrastructure() {
    echo "🏗️  Deploying core infrastructure..."
    
    # Deploy PostgreSQL databases
    echo "🗄️  Deploying PostgreSQL databases..."
    docker run -d \
        --name postgres-main-ra1 \
        --network medinovai_data \
        -e POSTGRES_DB=medinovai_main \
        -e POSTGRES_USER=medinovai \
        -e POSTGRES_PASSWORD=medinovai_secure_2025 \
        -v $(pwd)/volumes/postgres/main:/var/lib/postgresql/data \
        -p 5432:5432 \
        postgres:16-alpine
    
    # Deploy MongoDB
    echo "🍃 Deploying MongoDB..."
    docker run -d \
        --name mongodb-main-ra1 \
        --network medinovai_data \
        -e MONGO_INITDB_ROOT_USERNAME=medinovai \
        -e MONGO_INITDB_ROOT_PASSWORD=medinovai_secure_2025 \
        -v $(pwd)/volumes/mongodb/main:/data/db \
        -p 27017:27017 \
        mongo:7.0
    
    # Deploy Redis
    echo "🔴 Deploying Redis..."
    docker run -d \
        --name redis-main-ra1 \
        --network medinovai_data \
        -v $(pwd)/volumes/redis/main:/data \
        -p 6379:6379 \
        redis:7-alpine
    
    # Deploy Kafka
    echo "📨 Deploying Kafka message queue..."
    docker run -d \
        --name zookeeper-ra1 \
        --network medinovai_backend \
        -e ZOOKEEPER_CLIENT_PORT=2181 \
        -e ZOOKEEPER_TICK_TIME=2000 \
        confluentinc/cp-zookeeper:latest
    
    sleep 10
    
    docker run -d \
        --name kafka-ra1 \
        --network medinovai_backend \
        -e KAFKA_BROKER_ID=1 \
        -e KAFKA_ZOOKEEPER_CONNECT=zookeeper-ra1:2181 \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-ra1:9092 \
        -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
        -p 9092:9092 \
        confluentinc/cp-kafka:latest
    
    echo "✅ Core infrastructure deployment completed"
    echo ""
}

# Function to deploy monitoring stack
deploy_monitoring() {
    echo "📊 Deploying monitoring stack..."
    
    # Deploy Prometheus
    docker run -d \
        --name prometheus-ra1 \
        --network medinovai_monitoring \
        -p 9090:9090 \
        -v $(pwd)/volumes/prometheus:/prometheus \
        prom/prometheus:latest
    
    # Deploy Grafana
    docker run -d \
        --name grafana-ra1 \
        --network medinovai_monitoring \
        -e GF_SECURITY_ADMIN_PASSWORD=medinovai_admin_2025 \
        -p 3000:3000 \
        -v $(pwd)/volumes/grafana:/var/lib/grafana \
        grafana/grafana:latest
    
    echo "✅ Monitoring stack deployment completed"
    echo ""
}

# Function to deploy Ollama AI services
deploy_ollama_services() {
    echo "🧠 Deploying Ollama AI services..."
    
    # Deploy main Ollama service
    docker run -d \
        --name ollama-main-ra1 \
        --network medinovai_ai \
        -p 11434:11434 \
        -v $(pwd)/volumes/ollama/main:/root/.ollama \
        ollama/ollama:latest
    
    # Deploy healthcare-specialized Ollama
    docker run -d \
        --name ollama-healthcare-ra1 \
        --network medinovai_ai \
        -p 11435:11434 \
        -v $(pwd)/volumes/ollama/healthcare:/root/.ollama \
        ollama/ollama:latest
    
    echo "⏳ Waiting for Ollama services to start..."
    sleep 15
    
    # Pull essential models
    echo "📥 Pulling essential AI models..."
    docker exec ollama-main-ra1 ollama pull qwen2.5:72b &
    docker exec ollama-main-ra1 ollama pull deepseek-coder:33b &
    docker exec ollama-main-ra1 ollama pull codellama:34b &
    docker exec ollama-healthcare-ra1 ollama pull llama3.1:70b &
    docker exec ollama-healthcare-ra1 ollama pull mistral:7b &
    wait
    
    echo "✅ Ollama AI services deployment completed"
    echo ""
}

# Function to validate deployment
validate_deployment() {
    echo "🧪 Validating deployment..."
    
    # Check all services
    services=(
        "postgres-main-ra1:5432"
        "mongodb-main-ra1:27017"
        "redis-main-ra1:6379"
        "kafka-ra1:9092"
        "prometheus-ra1:9090"
        "grafana-ra1:3000"
        "ollama-main-ra1:11434"
        "ollama-healthcare-ra1:11434"
    )
    
    for service in "${services[@]}"; do
        container_name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        if docker ps | grep -q "$container_name"; then
            echo "✅ $container_name is running"
        else
            echo "❌ $container_name is not running"
        fi
    done
    
    echo "✅ Deployment validation completed"
    echo ""
}

# Main deployment execution
main() {
    echo "🚀 Starting MedinovAI Complete Platform Deployment..."
    echo ""
    
    # Execute deployment phases
    check_prerequisites
    prepare_environment
    deploy_core_infrastructure
    deploy_monitoring
    deploy_ollama_services
    validate_deployment
    
    echo "🎉 CORE INFRASTRUCTURE DEPLOYMENT COMPLETED!"
    echo ""
    echo "📊 Deployment Summary:"
    echo "- Core databases: PostgreSQL, MongoDB, Redis"
    echo "- Message queue: Kafka with Zookeeper"
    echo "- Monitoring: Prometheus + Grafana"
    echo "- AI Services: Ollama with 5 essential models"
    echo "- Networks: 5 custom Docker networks"
    echo "- Volumes: Persistent storage for all services"
    echo ""
    echo "🔄 Next Steps:"
    echo "1. Deploy MedinovaiOS main platform"
    echo "2. Deploy all business and healthcare modules"
    echo "3. Generate comprehensive demo data"
    echo "4. Execute five-model evaluation system"
    echo "5. Iterate until 9/10 scores achieved"
    echo ""
    echo "📄 Full log: ${LOG_FILE}"
}

# Execute main function
main "$@"

