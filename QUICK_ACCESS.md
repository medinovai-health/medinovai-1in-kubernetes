# 🚀 MedinovAI Quick Access Guide

## Monitoring (Operational)

### Grafana Dashboard
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
- URL: http://localhost:3000
- Username: `admin`
- Password: `medinovai123`

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
- URL: http://localhost:9090

### Loki Logs
- Service: `loki.monitoring.svc.cluster.local:3100`
- Access via Grafana datasource

## Services (4 Running)

### API Gateway
```bash
kubectl port-forward -n medinovai svc/api-gateway 8080:80
```
- URL: http://localhost:8080

### Authentication
```bash
kubectl port-forward -n medinovai svc/medinovai-authentication 8081:8080
```
- URL: http://localhost:8081

## Cluster Commands

### View All Pods
```bash
kubectl get pods -n medinovai
kubectl get pods -n monitoring
```

### View All Services
```bash
kubectl get svc -n medinovai
kubectl get svc -n monitoring
```

### Cluster Health
```bash
kubectl cluster-info
kubectl get nodes
kubectl top nodes
```

## Logs

### Service Logs
```bash
kubectl logs -f deployment/api-gateway -n medinovai
kubectl logs -f deployment/medinovai-authentication -n medinovai
```

### Monitoring Logs
```bash
kubectl logs -f deployment/prometheus-grafana -n monitoring
```

## Status

✅ **Infrastructure**: Operational  
✅ **Monitoring**: Operational (16 pods)  
✅ **Core Services**: Operational (8 pods)  
⚠️ **Additional Services**: Blocked (need container images)

---

*Last Updated: October 1, 2025*
