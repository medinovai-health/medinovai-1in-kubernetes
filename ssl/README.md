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
