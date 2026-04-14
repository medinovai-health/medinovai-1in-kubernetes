# Performance Optimization & Caching — medinovai-1in-kubernetes

> (c) 2026 MedinovAI — Empowering human will for cure.
> Sprint 13: Performance Optimization & Caching

## Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| API P50 | < 50ms | TBD | Pending |
| API P95 | < 200ms | TBD | Pending |
| API P99 | < 500ms | TBD | Pending |
| Throughput | > 1000 RPS | TBD | Pending |
| Cache Hit Rate | > 85% | TBD | Pending |
| DB Query Time | < 50ms | TBD | Pending |
| Memory Usage | < 512MB | TBD | Pending |
| Cold Start | < 3s | TBD | Pending |

## Caching Strategy

### Layer 1: Application Cache (In-Memory)
- **TTL**: 60s for hot data, 300s for warm data
- **Eviction**: LRU with max 10,000 entries
- **Scope**: Per-instance, request-scoped memoization

### Layer 2: Distributed Cache (Redis)
- **TTL**: 300s default, configurable per key pattern
- **Serialization**: MessagePack for compact storage
- **Patterns**: Cache-aside, write-through for critical paths

### Layer 3: CDN Cache (CloudFront)
- **TTL**: 3600s for static assets, 60s for API responses
- **Invalidation**: Tag-based purge on deployment
- **Compression**: Brotli for text, WebP for images

## Query Optimization

```sql
-- Index recommendations for medinovai-1in-kubernetes
-- Covering indexes for frequent query patterns
CREATE INDEX idx_created_at ON main_table (created_at DESC);
CREATE INDEX idx_status_created ON main_table (status, created_at DESC);
CREATE INDEX idx_user_status ON main_table (user_id, status);
```

## Connection Pooling

```yaml
database:
  pool_size: 20
  max_overflow: 10
  pool_timeout: 30
  pool_recycle: 1800
  pool_pre_ping: true

redis:
  pool_size: 50
  max_connections: 100
  socket_timeout: 5
  socket_connect_timeout: 5
  retry_on_timeout: true
```

## Load Testing Configuration

```yaml
k6_config:
  scenarios:
    smoke:
      executor: constant-vus
      vus: 5
      duration: 30s
    load:
      executor: ramping-vus
      stages:
        - duration: 2m
          target: 50
        - duration: 5m
          target: 100
        - duration: 2m
          target: 0
    stress:
      executor: ramping-vus
      stages:
        - duration: 2m
          target: 100
        - duration: 5m
          target: 500
        - duration: 2m
          target: 0
    spike:
      executor: ramping-vus
      stages:
        - duration: 10s
          target: 1000
        - duration: 1m
          target: 1000
        - duration: 10s
          target: 0
```

## Monitoring & Alerting

| Alert | Threshold | Action |
|-------|-----------|--------|
| P95 > 500ms | 5 min sustained | Scale up + investigate |
| Cache miss > 30% | 10 min sustained | Warm cache + check TTL |
| Memory > 80% | Immediate | GC + scale up |
| Error rate > 1% | 2 min sustained | Circuit breaker + alert |
| DB pool exhausted | Immediate | Scale pool + alert |
