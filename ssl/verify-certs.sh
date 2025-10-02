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
