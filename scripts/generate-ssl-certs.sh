#!/bin/bash
# SSL/TLS Certificate Generation for MedinovAI Infrastructure
# Generates self-signed certificates for all services
# For production: Replace with proper CA-signed certificates

set -e

echo "🔐 Generating SSL/TLS Certificates for MedinovAI Infrastructure..."

# Create SSL directory structure
mkdir -p ssl/{ca,postgres,mongodb,redis,nginx}

# Generate CA certificate (Certificate Authority)
echo "📜 Generating Certificate Authority (CA)..."
openssl req -new -x509 -days 3650 -nodes \
  -out ssl/ca/ca.crt \
  -keyout ssl/ca/ca.key \
  -subj "/C=US/ST=California/L=San Francisco/O=MedinovAI/OU=Infrastructure/CN=MedinovAI-CA"

echo "✅ CA certificate generated"

# Generate PostgreSQL certificates
echo "📜 Generating PostgreSQL SSL certificates..."
openssl req -new -nodes \
  -out ssl/postgres/server.csr \
  -keyout ssl/postgres/server.key \
  -subj "/C=US/ST=California/L=San Francisco/O=MedinovAI/OU=Database/CN=medinovai-postgres"

openssl x509 -req -in ssl/postgres/server.csr \
  -days 3650 \
  -CA ssl/ca/ca.crt -CAkey ssl/ca/ca.key -CAcreateserial \
  -out ssl/postgres/server.crt

# Set correct permissions for PostgreSQL
chmod 600 ssl/postgres/server.key
chmod 644 ssl/postgres/server.crt

echo "✅ PostgreSQL certificates generated"

# Generate MongoDB certificates
echo "📜 Generating MongoDB TLS certificates..."
openssl req -new -nodes \
  -out ssl/mongodb/server.csr \
  -keyout ssl/mongodb/server.key \
  -subj "/C=US/ST=California/L=San Francisco/O=MedinovAI/OU=Database/CN=medinovai-mongodb"

openssl x509 -req -in ssl/mongodb/server.csr \
  -days 3650 \
  -CA ssl/ca/ca.crt -CAkey ssl/ca/ca.key -CAcreateserial \
  -out ssl/mongodb/server.crt

# MongoDB needs PEM format (combined cert + key)
cat ssl/mongodb/server.crt ssl/mongodb/server.key > ssl/mongodb/server.pem
chmod 600 ssl/mongodb/server.pem

echo "✅ MongoDB certificates generated"

# Generate Redis certificates
echo "📜 Generating Redis TLS certificates..."
openssl req -new -nodes \
  -out ssl/redis/server.csr \
  -keyout ssl/redis/server.key \
  -subj "/C=US/ST=California/L=San Francisco/O=MedinovAI/OU=Cache/CN=medinovai-redis"

openssl x509 -req -in ssl/redis/server.csr \
  -days 3650 \
  -CA ssl/ca/ca.crt -CAkey ssl/ca/ca.key -CAcreateserial \
  -out ssl/redis/server.crt

chmod 600 ssl/redis/server.key
chmod 644 ssl/redis/server.crt

echo "✅ Redis certificates generated"

# Generate Nginx certificates
echo "📜 Generating Nginx HTTPS certificates..."
openssl req -new -nodes \
  -out ssl/nginx/server.csr \
  -keyout ssl/nginx/server.key \
  -subj "/C=US/ST=California/L=San Francisco/O=MedinovAI/OU=Gateway/CN=localhost"

openssl x509 -req -in ssl/nginx/server.csr \
  -days 3650 \
  -CA ssl/ca/ca.crt -CAkey ssl/ca/ca.key -CAcreateserial \
  -out ssl/nginx/server.crt

chmod 600 ssl/nginx/server.key
chmod 644 ssl/nginx/server.crt

echo "✅ Nginx certificates generated"

# Copy CA certificate to each service directory
cp ssl/ca/ca.crt ssl/postgres/
cp ssl/ca/ca.crt ssl/mongodb/
cp ssl/ca/ca.crt ssl/redis/
cp ssl/ca/ca.crt ssl/nginx/

# Generate DH parameters for Nginx (optional but recommended)
echo "📜 Generating Diffie-Hellman parameters (this may take a while)..."
openssl dhparam -out ssl/nginx/dhparam.pem 2048
echo "✅ DH parameters generated"

# Create verification script
cat > ssl/verify-certs.sh <<'VERIFY_EOF'
#!/bin/bash
echo "🔍 Verifying SSL/TLS Certificates..."

echo ""
echo "CA Certificate:"
openssl x509 -in ssl/ca/ca.crt -noout -subject -dates

echo ""
echo "PostgreSQL Certificate:"
openssl x509 -in ssl/postgres/server.crt -noout -subject -dates
openssl verify -CAfile ssl/ca/ca.crt ssl/postgres/server.crt

echo ""
echo "MongoDB Certificate:"
openssl x509 -in ssl/mongodb/server.crt -noout -subject -dates
openssl verify -CAfile ssl/ca/ca.crt ssl/mongodb/server.crt

echo ""
echo "Redis Certificate:"
openssl x509 -in ssl/redis/server.crt -noout -subject -dates
openssl verify -CAfile ssl/ca/ca.crt ssl/redis/server.crt

echo ""
echo "Nginx Certificate:"
openssl x509 -in ssl/nginx/server.crt -noout -subject -dates
openssl verify -CAfile ssl/ca/ca.crt ssl/nginx/server.crt

echo ""
echo "✅ All certificates verified successfully!"
VERIFY_EOF

chmod +x ssl/verify-certs.sh

echo ""
echo "🎉 SSL/TLS Certificate Generation Complete!"
echo ""
echo "📁 Certificates location: ./ssl/"
echo "   - CA: ssl/ca/ca.crt"
echo "   - PostgreSQL: ssl/postgres/server.{crt,key}"
echo "   - MongoDB: ssl/mongodb/server.pem"
echo "   - Redis: ssl/redis/server.{crt,key}"
echo "   - Nginx: ssl/nginx/server.{crt,key}"
echo ""
echo "🔍 Verify certificates: ./ssl/verify-certs.sh"
echo ""
echo "⚠️  Note: These are self-signed certificates for development."
echo "   For production, use certificates from a trusted CA."
echo ""

# Summary file
cat > ssl/README.md <<'README_EOF'
# SSL/TLS Certificates

**Generated**: $(date)  
**Type**: Self-signed (for development)  
**Validity**: 10 years  

## Certificate Files

### Certificate Authority (CA)
- `ca/ca.crt` - CA certificate
- `ca/ca.key` - CA private key (keep secure!)

### PostgreSQL
- `postgres/server.crt` - Server certificate
- `postgres/server.key` - Server private key
- `postgres/ca.crt` - CA certificate

### MongoDB
- `mongodb/server.pem` - Combined certificate + key
- `mongodb/server.crt` - Server certificate
- `mongodb/server.key` - Server private key
- `mongodb/ca.crt` - CA certificate

### Redis
- `redis/server.crt` - Server certificate
- `redis/server.key` - Server private key
- `redis/ca.crt` - CA certificate

### Nginx
- `nginx/server.crt` - Server certificate
- `nginx/server.key` - Server private key
- `nginx/dhparam.pem` - DH parameters
- `nginx/ca.crt` - CA certificate

## Verification

Run: `./verify-certs.sh`

## Security Notes

1. **Keep private keys secure** - Never commit to version control
2. **Production use** - Replace with CA-signed certificates
3. **Permissions** - Private keys have 600 permissions
4. **Renewal** - Certificates expire in 10 years (2035)

## For Production

1. Obtain certificates from trusted CA (Let's Encrypt, DigiCert, etc.)
2. Replace self-signed certificates
3. Update docker-compose volumes
4. Restart services

## Client Configuration

To trust these certificates, clients need the CA certificate:
```bash
# Copy CA certificate to system trust store
# macOS:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ssl/ca/ca.crt

# Linux:
sudo cp ssl/ca/ca.crt /usr/local/share/ca-certificates/medinovai-ca.crt
sudo update-ca-certificates
```
README_EOF

echo "📄 README created: ssl/README.md"

