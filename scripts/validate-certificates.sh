#!/bin/bash
# Certificate Validation & Expiration Monitoring
# Enhancement from llama3.1 and qwen2.5 models

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$PROJECT_ROOT/ssl"

echo "🔍 Certificate Validation & Expiration Check"
echo "================================================================"
echo ""

WARNINGS=0
ERRORS=0

# Function to check certificate expiration
check_cert_expiration() {
    local cert_path=$1
    local db_name=$2
    
    if [ ! -f "$cert_path" ]; then
        echo "❌ Certificate not found: $cert_path"
        ((ERRORS++))
        return 1
    fi
    
    # Get expiration date
    exp_date=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d= -f2)
    
    # Convert to epoch for comparison (macOS compatible)
    exp_epoch=$(date -j -f "%b %d %T %Y %Z" "$exp_date" +%s 2>/dev/null || date -d "$exp_date" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( ($exp_epoch - $now_epoch) / 86400 ))
    
    echo "📜 $db_name Certificate:"
    echo "   Path: $cert_path"
    echo "   Expires: $exp_date"
    echo "   Days remaining: $days_left"
    
    if [ $days_left -lt 0 ]; then
        echo "   ❌ EXPIRED!"
        ((ERRORS++))
    elif [ $days_left -lt 7 ]; then
        echo "   🚨 CRITICAL: Expires in less than 7 days!"
        ((WARNINGS++))
    elif [ $days_left -lt 30 ]; then
        echo "   ⚠️  WARNING: Expires in less than 30 days!"
        ((WARNINGS++))
    else
        echo "   ✅ Valid"
    fi
    echo ""
}

# Function to validate certificate integrity
validate_cert_integrity() {
    local cert_path=$1
    local key_path=$2
    local db_name=$3
    
    echo "🔐 Validating $db_name certificate integrity..."
    
    # Validate certificate format
    if ! openssl x509 -in "$cert_path" -text -noout > /dev/null 2>&1; then
        echo "   ❌ Invalid certificate format"
        ((ERRORS++))
        return 1
    fi
    
    # Validate key format (if exists)
    if [ -f "$key_path" ]; then
        if ! openssl rsa -in "$key_path" -check -noout > /dev/null 2>&1; then
            echo "   ❌ Invalid private key format"
            ((ERRORS++))
            return 1
        fi
        
        # Check if cert and key match
        cert_modulus=$(openssl x509 -noout -modulus -in "$cert_path" | openssl md5)
        key_modulus=$(openssl rsa -noout -modulus -in "$key_path" | openssl md5)
        
        if [ "$cert_modulus" != "$key_modulus" ]; then
            echo "   ❌ Certificate and key do not match!"
            ((ERRORS++))
            return 1
        fi
        
        echo "   ✅ Certificate and key match"
    fi
    
    # Check certificate issuer and subject
    issuer=$(openssl x509 -in "$cert_path" -noout -issuer)
    subject=$(openssl x509 -in "$cert_path" -noout -subject)
    
    echo "   Issuer: $issuer"
    echo "   Subject: $subject"
    echo ""
}

# Check PostgreSQL certificates
if [ -d "$SSL_DIR/postgres" ]; then
    echo "🐘 PostgreSQL Certificates"
    echo "----------------------------------------"
    check_cert_expiration "$SSL_DIR/postgres/server.crt" "PostgreSQL"
    validate_cert_integrity "$SSL_DIR/postgres/server.crt" "$SSL_DIR/postgres/server.key" "PostgreSQL"
fi

# Check MongoDB certificates
if [ -d "$SSL_DIR/mongodb" ]; then
    echo "🍃 MongoDB Certificates"
    echo "----------------------------------------"
    if [ -f "$SSL_DIR/mongodb/mongodb.pem" ]; then
        check_cert_expiration "$SSL_DIR/mongodb/mongodb.pem" "MongoDB"
    elif [ -f "$SSL_DIR/mongodb/server.crt" ]; then
        check_cert_expiration "$SSL_DIR/mongodb/server.crt" "MongoDB"
        validate_cert_integrity "$SSL_DIR/mongodb/server.crt" "$SSL_DIR/mongodb/server.key" "MongoDB"
    fi
fi

# Check Redis certificates
if [ -d "$SSL_DIR/redis" ]; then
    echo "🔴 Redis Certificates"
    echo "----------------------------------------"
    check_cert_expiration "$SSL_DIR/redis/server.crt" "Redis"
    validate_cert_integrity "$SSL_DIR/redis/server.crt" "$SSL_DIR/redis/server.key" "Redis"
fi

# Summary
echo "================================================================"
echo "📊 VALIDATION SUMMARY"
echo "================================================================"
echo ""
echo "Warnings: $WARNINGS"
echo "Errors: $ERRORS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "⚠️  Validation passed with $WARNINGS warning(s)"
    exit 0
else
    echo "✅ All certificates validated successfully!"
    exit 0
fi

