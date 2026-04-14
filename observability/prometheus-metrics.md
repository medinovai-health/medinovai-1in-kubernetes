# Prometheus Metrics Configuration
# Sprint 8: Observability & Monitoring
# Service: medinovai-1in-kubernetes

# Standard metrics to expose:
# - http_requests_total (counter) - Total HTTP requests by method, path, status
# - http_request_duration_seconds (histogram) - Request latency distribution
# - http_requests_in_progress (gauge) - Currently processing requests
# - app_info (info) - Application metadata (version, environment)
# - db_query_duration_seconds (histogram) - Database query latency
# - db_connections_active (gauge) - Active database connections
# - cache_hits_total (counter) - Cache hit/miss ratio
# - external_api_duration_seconds (histogram) - External API call latency
# - error_total (counter) - Application errors by type

# Health check endpoints:
# GET /health/live   - Liveness probe (is the process running?)
# GET /health/ready  - Readiness probe (can it accept traffic?)
# GET /metrics       - Prometheus scrape endpoint

# Alert rules (recommended):
# - High error rate: rate(error_total[5m]) > 0.05
# - High latency: histogram_quantile(0.99, http_request_duration_seconds) > 2
# - Service down: up == 0 for 1m
