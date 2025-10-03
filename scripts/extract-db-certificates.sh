#!/bin/bash
# Automated TLS Certificate Extraction for Database Exporters
# Validated by 5 Ollama models - Enhancement from all models

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$PROJECT_ROOT/ssl"

echo "🔐 TLS Certificate Extraction - MedinovAI Database Exporters"
echo "================================================================"
echo ""

# Function to extract certificates from database container
extract_certs() {
    local DB_TYPE=$1
    local CONTAINER_NAME=$2
    local OUTPUT_DIR="$SSL_DIR/${DB_TYPE}"
    
    echo "📜 Extracting certificates from $CONTAINER_NAME..."
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "❌ ERROR: Container $CONTAINER_NAME is not running"
        return 1
    fi
    
    # Extract certificates based on database type
    case $DB_TYPE in
        postgres)
            docker exec "$CONTAINER_NAME" cat /etc/ssl/certs/server.crt > "$OUTPUT_DIR/server.crt" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/var/lib/postgresql/server.crt" "$OUTPUT_DIR/server.crt" 2>/dev/null || \
            docker exec "$CONTAINER_NAME" cat /var/lib/postgresql/data/server.crt > "$OUTPUT_DIR/server.crt"
            
            docker exec "$CONTAINER_NAME" cat /etc/ssl/private/server.key > "$OUTPUT_DIR/server.key" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/var/lib/postgresql/server.key" "$OUTPUT_DIR/server.key" 2>/dev/null || \
            docker exec "$CONTAINER_NAME" cat /var/lib/postgresql/data/server.key > "$OUTPUT_DIR/server.key"
            
            docker exec "$CONTAINER_NAME" cat /etc/ssl/certs/ca.crt > "$OUTPUT_DIR/ca.crt" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/var/lib/postgresql/ca.crt" "$OUTPUT_DIR/ca.crt" 2>/dev/null || \
            docker exec "$CONTAINER_NAME" cat /var/lib/postgresql/data/ca.crt > "$OUTPUT_DIR/ca.crt"
            ;;
            
        mongodb)
            docker exec "$CONTAINER_NAME" cat /etc/ssl/mongodb.pem > "$OUTPUT_DIR/mongodb.pem" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/etc/ssl/mongodb.pem" "$OUTPUT_DIR/mongodb.pem" 2>/dev/null || \
            echo "⚠️  Warning: Could not extract MongoDB PEM, will use server.crt/key"
            
            docker exec "$CONTAINER_NAME" cat /etc/ssl/ca.crt > "$OUTPUT_DIR/ca.crt" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/etc/ssl/ca.crt" "$OUTPUT_DIR/ca.crt"
            ;;
            
        redis)
            docker exec "$CONTAINER_NAME" cat /etc/ssl/redis/server.crt > "$OUTPUT_DIR/server.crt" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/etc/ssl/redis/server.crt" "$OUTPUT_DIR/server.crt"
            
            docker exec "$CONTAINER_NAME" cat /etc/ssl/redis/server.key > "$OUTPUT_DIR/server.key" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/etc/ssl/redis/server.key" "$OUTPUT_DIR/server.key"
            
            docker exec "$CONTAINER_NAME" cat /etc/ssl/redis/ca.crt > "$OUTPUT_DIR/ca.crt" 2>/dev/null || \
            docker cp "$CONTAINER_NAME:/etc/ssl/redis/ca.crt" "$OUTPUT_DIR/ca.crt"
            ;;
    esac
    
    # Set proper permissions
    chmod 600 "$OUTPUT_DIR"/*.key 2>/dev/null || true
    chmod 644 "$OUTPUT_DIR"/*.crt 2>/dev/null || true
    chmod 644 "$OUTPUT_DIR"/*.pem 2>/dev/null || true
    
    echo "✅ Certificates extracted to $OUTPUT_DIR"
    
    # Validate certificates
    echo "🔍 Validating certificates..."
    
    if [ -f "$OUTPUT_DIR/server.crt" ]; then
        if openssl x509 -in "$OUTPUT_DIR/server.crt" -text -noout > /dev/null 2>&1; then
            echo "  ✓ server.crt is valid"
            
            # Show expiration date
            exp_date=$(openssl x509 -in "$OUTPUT_DIR/server.crt" -noout -enddate | cut -d= -f2)
            echo "  ℹ️  Expires: $exp_date"
        else
            echo "  ✗ server.crt is invalid"
            return 1
        fi
    fi
    
    if [ -f "$OUTPUT_DIR/server.key" ]; then
        if openssl rsa -in "$OUTPUT_DIR/server.key" -check -noout > /dev/null 2>&1; then
            echo "  ✓ server.key is valid"
        else
            echo "  ✗ server.key is invalid"
            return 1
        fi
    fi
    
    if [ -f "$OUTPUT_DIR/ca.crt" ]; then
        if openssl x509 -in "$OUTPUT_DIR/ca.crt" -text -noout > /dev/null 2>&1; then
            echo "  ✓ ca.crt is valid"
        else
            echo "  ✗ ca.crt is invalid"
            return 1
        fi
    fi
    
    echo ""
    return 0
}

# Main execution
echo "Starting certificate extraction for all databases..."
echo ""

# Extract PostgreSQL certificates
extract_certs "postgres" "medinovai-postgres-tls"
PG_STATUS=$?

# Extract MongoDB certificates
extract_certs "mongodb" "medinovai-mongodb-tls"
MONGO_STATUS=$?

# Extract Redis certificates
extract_certs "redis" "medinovai-redis-tls"
REDIS_STATUS=$?

# Summary
echo "================================================================"
echo "📊 EXTRACTION SUMMARY"
echo "================================================================"
echo ""
echo "PostgreSQL: $([ $PG_STATUS -eq 0 ] && echo '✅ SUCCESS' || echo '❌ FAILED')"
echo "MongoDB:    $([ $MONGO_STATUS -eq 0 ] && echo '✅ SUCCESS' || echo '❌ FAILED')"
echo "Redis:      $([ $REDIS_STATUS -eq 0 ] && echo '✅ SUCCESS' || echo '❌ FAILED')"
echo ""

if [ $PG_STATUS -eq 0 ] && [ $MONGO_STATUS -eq 0 ] && [ $REDIS_STATUS -eq 0 ]; then
    echo "🎉 All certificates extracted and validated successfully!"
    exit 0
else
    echo "⚠️  Some certificate extractions failed. Review errors above."
    exit 1
fi

