# MedinovAI Istio Service Mesh Setup Guide

## Overview

Istio has been successfully installed on your Mac Studio to provide centralized port management and service mesh capabilities for your MedinovAI infrastructure. This setup provides:

- **Centralized Port Management**: All services use standardized ports defined in a central registry
- **Service Mesh**: Traffic management, security, and observability across all services
- **Ingress Gateway**: Single entry point for all external traffic
- **Load Balancing**: Automatic load balancing and failover
- **Security**: mTLS encryption between services

## Installation Summary

✅ **Istio Version**: 1.27.1  
✅ **Control Plane**: Running (istiod)  
✅ **Ingress Gateway**: Running on 192.168.139.2  
✅ **Port Management**: Configured with centralized registry  
✅ **Gateways**: 4 gateways configured for different service domains  

## Centralized Port Allocation

### Main Application Ports
- **HTTP**: 80 (redirects to HTTPS)
- **HTTPS**: 443 (main entry point)

### Service-Specific Ports
| Service | Port | Protocol | Path |
|---------|------|----------|------|
| API Gateway | 8080 | HTTP | /api/ |
| Frontend | 3000 | HTTP | / |
| HealthLLM | 8000 | HTTP | /healthllm/ |
| Grafana | 80 | HTTP | /grafana/ |
| Prometheus | 9090 | HTTP | /prometheus/ |
| AlertManager | 9093 | HTTP | /alertmanager/ |
| Test Orchestrator | 8080 | HTTP | /orchestrator/ |
| E2E Test Runner | 8080 | HTTP | /e2e/ |
| Security Gateway | 8080 | HTTP | / |

### Data Service Ports
| Service | Port | Protocol |
|---------|------|----------|
| PostgreSQL | 5432 | TCP |
| Redis | 6379 | TCP |
| Kafka | 9092 | TCP |
| Zookeeper | 2181 | TCP |

## Service Domains

Your services are now accessible through these centralized domains:

- **Main Services**: `*.medinovai.local` and `medinovai.local`
- **Monitoring**: `monitoring.medinovai.local`
- **Testing**: `testing.medinovai.local`
- **Security**: `security.medinovai.local`

## Management Commands

Use the provided port management script:

```bash
# Check Istio status
./scripts/istio-port-manager.sh check

# View port registry
./scripts/istio-port-manager.sh ports

# View service endpoints
./scripts/istio-port-manager.sh endpoints

# View gateways and virtual services
./scripts/istio-port-manager.sh gateways

# Check ingress gateway status
./scripts/istio-port-manager.sh ingress

# Test connectivity
./scripts/istio-port-manager.sh test
```

## Accessing Your Services

### External Access
Your services are accessible via the Istio Ingress Gateway at:
- **External IP**: 192.168.139.2
- **HTTP Port**: 80 (redirects to HTTPS)
- **HTTPS Port**: 443

### Local Development
For local development, add these entries to your `/etc/hosts` file:

```
192.168.139.2 medinovai.local
192.168.139.2 api.medinovai.local
192.168.139.2 monitoring.medinovai.local
192.168.139.2 testing.medinovai.local
192.168.139.2 security.medinovai.local
```

## Configuration Files

- **Gateway Configuration**: `istio-gateway-config.yaml`
- **Port Management**: `istio-port-management.yaml`
- **Management Script**: `scripts/istio-port-manager.sh`

## Adding New Services

To add a new service to the centralized port management:

1. Update the port registry in `istio-port-management.yaml`
2. Add gateway and virtual service configuration in `istio-gateway-config.yaml`
3. Apply the changes:
   ```bash
   kubectl apply -f istio-port-management.yaml
   kubectl apply -f istio-gateway-config.yaml
   ```

## Troubleshooting

### Check Istio Status
```bash
kubectl get pods -n istio-system
kubectl get svc -n istio-system
istioctl version
```

### View Logs
```bash
kubectl logs -n istio-system -l app=istiod
kubectl logs -n istio-system -l app=istio-ingressgateway
```

### Test Connectivity
```bash
# Test from within cluster
kubectl exec -it <pod-name> -n <namespace> -- curl http://istio-ingressgateway.istio-system.svc.cluster.local

# Test external connectivity
curl -H "Host: medinovai.local" http://192.168.139.2
```

## Security Features

- **mTLS**: Automatic mutual TLS between services
- **Authorization Policies**: Fine-grained access control
- **Traffic Encryption**: All inter-service communication encrypted
- **Certificate Management**: Automatic certificate provisioning

## Monitoring and Observability

Istio provides built-in monitoring capabilities:
- **Metrics**: Prometheus-compatible metrics
- **Tracing**: Distributed tracing with Jaeger
- **Logging**: Structured logging for all requests
- **Dashboards**: Grafana dashboards for service mesh metrics

## Next Steps

1. **Enable mTLS**: Configure strict mTLS for enhanced security
2. **Set up Monitoring**: Configure Prometheus and Grafana for Istio metrics
3. **Add Authentication**: Implement authentication policies
4. **Configure Rate Limiting**: Set up rate limiting for API protection
5. **Set up Tracing**: Configure distributed tracing for debugging

## Support

For issues or questions:
1. Check the Istio documentation: https://istio.io/latest/docs/
2. Use the management script: `./scripts/istio-port-manager.sh help`
3. Check cluster logs: `kubectl logs -n istio-system`

---

**Installation completed successfully!** 🎉

Your MedinovAI infrastructure now has centralized port management and service mesh capabilities through Istio.







