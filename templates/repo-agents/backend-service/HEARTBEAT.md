# Heartbeat — Backend Service

## Check Frequency: Every 5 minutes

### Health Checks
1. **API Responsiveness**: HTTP 200 from /health within 2s
2. **Database Connectivity**: Can query primary DB within 500ms
3. **Cache Connectivity**: Redis ping succeeds within 100ms
4. **Error Rate**: < 1% over 5 min window
5. **Latency P99**: < 200ms
6. **Memory Usage**: < 80% of limit
7. **CPU Usage**: < 70% sustained over 5 min
