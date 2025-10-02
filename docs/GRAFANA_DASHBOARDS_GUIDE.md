# 📊 GRAFANA DASHBOARDS - Complete Guide

**Date**: October 2, 2025  
**Infrastructure**: MedinovAI TLS-Enabled Stack  
**Grafana Version**: Latest  
**Status**: ✅ OPERATIONAL

---

## 🎯 QUICK ACCESS

### Grafana Login
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `admin` (or check `.env` file for `GRAFANA_PASSWORD`)
- **First Login**: You may be prompted to change the password

### Direct Dashboard Access
Once logged in, navigate to:
- **Home** → **Dashboards** → **Infrastructure** folder

---

## 📊 AVAILABLE DASHBOARDS

We have provisioned **6 comprehensive dashboards** for monitoring your infrastructure:

### 1. 🚀 MedinovAI Infrastructure Overview
**Purpose**: Master dashboard showing all services at a glance

**What You'll See**:
- ✅ Service health status for all containers
- 📊 Container CPU usage trends
- 💾 Container memory usage
- 🖥️ System CPU gauge (overall)
- 💾 System memory gauge
- 💿 System disk usage gauge
- ✅ Count of services online
- 🌐 Network I/O (receive/transmit)
- 💿 Disk I/O (read/write)

**Refresh Rate**: 30 seconds  
**Time Range**: Last 1 hour (configurable)  
**UID**: `medinovai-overview`

---

### 2. 🖥️ Node Exporter Full Dashboard
**Source**: Grafana.com ID 1860 (Most popular system monitoring dashboard)

**What You'll See**:
- Complete system resource monitoring
- CPU, Memory, Disk, Network metrics
- Detailed performance graphs
- System uptime and load averages

**Best For**: Deep dive into host system performance

---

### 3. 🐘 PostgreSQL Database Monitoring
**Source**: Grafana.com ID 9628

**What You'll See**:
- Database connections and transactions
- Query performance
- Cache hit ratios
- Table and index statistics
- Replication lag (if configured)

**Monitored Databases**:
- `medinovai-postgres-tls` (port 5432)
- `medinovai-timescaledb-tls` (port 5433)

---

### 4. 🍃 MongoDB Monitoring
**Source**: Grafana.com ID 2583

**What You'll See**:
- MongoDB operations per second
- Connection pool usage
- Memory usage
- Document operations
- Collection statistics

**Monitored Database**:
- `medinovai-mongodb-tls` (port 27017)

---

### 5. 🔴 Redis Monitoring
**Source**: Grafana.com ID 11835

**What You'll See**:
- Cache hit/miss ratios
- Commands per second
- Memory usage and eviction stats
- Connected clients
- Key space statistics

**Monitored Cache**:
- `medinovai-redis-tls` (port 6379)

---

### 6. 🐳 Docker Container Monitoring
**Source**: Grafana.com ID 193

**What You'll See**:
- Per-container resource usage
- Container states and health
- Resource limits vs actual usage
- Network and disk I/O per container

**Monitored Containers**: All 16 infrastructure containers

---

## 🔌 DATA SOURCES

### Configured Data Sources

#### 1. Prometheus (Default)
- **URL**: http://prometheus:9090
- **Type**: Time-series metrics
- **Status**: ✅ Connected
- **Scrape Interval**: 15 seconds
- **Retention**: 30 days

**Metrics Available**:
- Container metrics (via cAdvisor)
- System metrics (via Node Exporter - if installed)
- Application metrics (custom exporters)

#### 2. Loki
- **URL**: http://loki:3100
- **Type**: Log aggregation
- **Status**: ✅ Connected
- **Retention**: 7 days

**Logs Available**:
- All Docker container logs
- System logs (via Promtail)

---

## 📁 FILE STRUCTURE

```
medinovai-infrastructure/
└── grafana-provisioning/
    ├── datasources/
    │   └── datasources.yml (✅ 2 data sources)
    └── dashboards/
        ├── dashboard-provider.yml (✅ Provisioning config)
        ├── medinovai-infrastructure-overview.json (✅ Custom)
        ├── node-exporter-dashboard.json (✅ 683KB)
        ├── postgresql-dashboard.json (✅ 70KB)
        ├── mongodb-dashboard.json (✅ 42KB)
        ├── redis-dashboard.json (✅ 32KB)
        └── docker-dashboard.json (✅ 17KB)
```

**Total Dashboards**: 6  
**Total Size**: ~840KB

---

## 🚀 USING THE DASHBOARDS

### Navigation Flow

1. **Start Here**: Open http://localhost:3000
2. **Login**: Use admin credentials
3. **Go to**: Home → Dashboards → Infrastructure folder
4. **Begin**: Click "🚀 MedinovAI Infrastructure Overview"
5. **Drill Down**: Click on specific services to see detailed dashboards

### Time Range Selection

All dashboards support flexible time ranges:
- **Quick Ranges**: Last 5m, 15m, 30m, 1h, 6h, 24h, 7d, 30d
- **Custom Range**: Pick any start/end date
- **Relative Ranges**: "now-1h to now"

### Auto-Refresh

Dashboards auto-refresh at:
- **Overview Dashboard**: Every 30 seconds
- **Detailed Dashboards**: Every 1 minute (configurable)

### Variable Support

Some dashboards include variables for:
- Container selection
- Time interval grouping
- Service filtering

---

## 🔧 CUSTOMIZATION

### Making Changes

**Note**: Provisioned dashboards are READ-ONLY in the UI. To modify:

1. **Edit JSON file** in `grafana-provisioning/dashboards/`
2. **Restart Grafana**:
   ```bash
   docker restart medinovai-grafana-tls
   ```
3. **Verify changes** at http://localhost:3000

### Creating New Dashboards

**Option A: Via UI (temporary)**
1. Create dashboard in Grafana UI
2. Test and refine
3. Export JSON: Dashboard Settings → JSON Model → Copy JSON
4. Save to `grafana-provisioning/dashboards/your-dashboard.json`
5. Restart Grafana

**Option B: Via File (permanent)**
1. Create JSON file in `grafana-provisioning/dashboards/`
2. Follow Grafana dashboard JSON schema
3. Restart Grafana to load

---

## 📊 WHAT METRICS ARE AVAILABLE

### Currently Available Metrics

Based on your running infrastructure:

✅ **Container Metrics** (via cAdvisor built into Docker)
- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_network_receive_bytes_total`
- `container_network_transmit_bytes_total`
- `container_fs_reads_bytes_total`
- `container_fs_writes_bytes_total`

✅ **Service Health**
- `up` (service availability)

❓ **Application-Specific Metrics** (may need exporters)
- PostgreSQL metrics (requires postgres_exporter)
- MongoDB metrics (requires mongodb_exporter)
- Redis metrics (requires redis_exporter)
- Kafka metrics (requires kafka_exporter)

### Adding More Metrics (Optional)

To get full database/service metrics, install exporters:

#### PostgreSQL Exporter
```bash
docker run -d --name postgres-exporter \
  --network medinovai-network \
  -e DATA_SOURCE_NAME="postgresql://medinovai:password@postgres:5432/medinovai?sslmode=disable" \
  -p 9187:9187 \
  prometheuscommunity/postgres-exporter
```

#### MongoDB Exporter
```bash
docker run -d --name mongodb-exporter \
  --network medinovai-network \
  -p 9216:9216 \
  percona/mongodb_exporter:0.40 \
  --mongodb.uri=mongodb://admin:password@mongodb:27017
```

#### Redis Exporter
```bash
docker run -d --name redis-exporter \
  --network medinovai-network \
  -e REDIS_ADDR=redis:6379 \
  -e REDIS_PASSWORD=redis_secure_password \
  -p 9121:9121 \
  oliver006/redis_exporter
```

Then update `prometheus-config/prometheus.yml` to scrape these exporters.

---

## 🔍 TROUBLESHOOTING

### Dashboard Shows "No Data"

**Possible Causes**:
1. Data source not configured correctly
2. Prometheus not scraping metrics
3. Time range too narrow or too far back
4. Service not exposing metrics

**Solutions**:
```bash
# Check Prometheus targets
open http://localhost:9090/targets

# Check if containers are exposing metrics
docker stats

# Verify Prometheus is scraping
curl http://localhost:9090/api/v1/targets
```

### Dashboard Not Appearing

**Check**:
1. Dashboard JSON file exists in `grafana-provisioning/dashboards/`
2. Dashboard provider config is correct
3. Grafana has been restarted after adding dashboard
4. No JSON syntax errors in dashboard file

**Verify**:
```bash
# Check dashboard files
ls -lh grafana-provisioning/dashboards/

# Check Grafana logs
docker logs medinovai-grafana-tls --tail 100 | grep dashboard

# Restart Grafana
docker restart medinovai-grafana-tls
```

### Authentication Issues

**Default Credentials**:
- Username: `admin`
- Password: `admin` (first time) or check `.env` for `GRAFANA_PASSWORD`

**Reset Password**:
```bash
# Access Grafana container
docker exec -it medinovai-grafana-tls grafana-cli admin reset-admin-password newpassword
```

### Panels Show "Failed to Load"

**Causes**:
- Query syntax error
- Metric doesn't exist
- Data source misconfigured

**Fix**:
1. Open panel
2. Click "Edit"
3. Check query syntax
4. Test query in Prometheus first (http://localhost:9090)

---

## 📈 BEST PRACTICES

### 1. Start with Overview Dashboard
Always begin with "🚀 MedinovAI Infrastructure Overview" to get the big picture

### 2. Use Time Range Wisely
- Real-time monitoring: Last 15m with 30s refresh
- Troubleshooting: Last 6h to see patterns
- Reporting: Last 7d or 30d for trends

### 3. Set Up Alerts
Configure alerting for critical metrics:
- Service down (`up == 0`)
- High CPU (> 80% for 5 minutes)
- High memory (> 90% for 5 minutes)
- Disk full (> 90%)

### 4. Regular Review
- Daily: Check overview dashboard
- Weekly: Review detailed service dashboards
- Monthly: Analyze trends for capacity planning

---

## 🔗 USEFUL LINKS

- **Grafana Docs**: https://grafana.com/docs/grafana/latest/
- **Prometheus Docs**: https://prometheus.io/docs/
- **Dashboard Library**: https://grafana.com/grafana/dashboards/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/

---

## 📞 QUICK REFERENCE

| Service | URL | Purpose |
|---------|-----|---------|
| **Grafana** | http://localhost:3000 | Dashboards & Visualization |
| **Prometheus** | http://localhost:9090 | Metrics & Queries |
| **Loki** | http://localhost:3100 | Log Aggregation |

### Credentials

| Service | Username | Password |
|---------|----------|----------|
| **Grafana** | admin | admin (or check .env) |
| **Prometheus** | - | No auth |

---

## ✅ VERIFICATION CHECKLIST

After setup, verify:
- [ ] Can access Grafana at http://localhost:3000
- [ ] Can login with admin credentials
- [ ] See 6 dashboards in Infrastructure folder
- [ ] Overview dashboard shows service health
- [ ] At least some panels show data
- [ ] Prometheus data source is connected (green)
- [ ] Loki data source is connected (green)
- [ ] Auto-refresh is working (watch for updates)

---

## 📝 NOTES

### Dashboard Persistence
- ✅ Dashboards are provisioned from files (infrastructure as code)
- ✅ Survives container restarts
- ✅ Version controlled in Git
- ⚠️ Changes in UI are temporary (modify JSON files instead)

### Performance
- 6 dashboards use minimal resources
- Auto-refresh can be disabled to save resources
- Prometheus retention is 30 days (configurable)

### Security
- 🔒 Change default admin password immediately
- 🔒 Enable HTTPS for production use
- 🔒 Consider LDAP/SSO integration for team access
- 🔒 Dashboard access controlled via Grafana roles

---

**Status**: ✅ DASHBOARDS OPERATIONAL  
**Last Updated**: October 2, 2025  
**Maintained By**: MedinovAI Infrastructure Team

**For issues or questions**: Check troubleshooting section above or Grafana logs.

