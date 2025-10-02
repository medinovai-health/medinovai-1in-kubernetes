# 🚀 GRAFANA DASHBOARDS - QUICK START

## ⚡ 30-Second Start

```bash
# 1. Open Grafana in your browser
open http://localhost:3000

# 2. Login
Username: admin
Password: admin
```

**That's it!** You now have **6 monitoring dashboards** ready to use.

---

## 📊 Your Dashboards

Once logged in, click **Dashboards** → **Infrastructure** folder to see:

1. **🚀 MedinovAI Infrastructure Overview** ⭐ START HERE
   - See all 16 services at a glance
   - System health indicators
   - Resource usage graphs

2. **🖥️ Node Exporter Full**
   - Complete system monitoring
   - CPU, Memory, Disk, Network

3. **🐘 PostgreSQL Database**
   - Database connections & queries
   - Cache performance

4. **🍃 MongoDB Monitoring**
   - Document operations
   - Memory usage

5. **🔴 Redis Dashboard**
   - Cache hit/miss ratios
   - Commands per second

6. **🐳 Docker Container Monitoring**
   - Per-container resources
   - Health status

---

## 🎯 What You're Monitoring

Your dashboards cover **16 infrastructure services**:

✅ PostgreSQL + TimescaleDB  
✅ MongoDB  
✅ Redis  
✅ Kafka + Zookeeper  
✅ RabbitMQ  
✅ Prometheus + Grafana + Loki  
✅ Keycloak + Vault + MinIO  
✅ Nginx  

---

## 📚 Full Documentation

- **Complete Guide**: `docs/GRAFANA_DASHBOARDS_GUIDE.md`
- **Deployment Summary**: `docs/GRAFANA_DASHBOARD_DEPLOYMENT_SUMMARY.md`

---

## 🔧 Quick Commands

```bash
# Restart Grafana
docker restart medinovai-grafana-tls

# Check Grafana logs
docker logs medinovai-grafana-tls --tail 50

# Check dashboard files
ls -lh grafana-provisioning/dashboards/

# Access Prometheus (data source)
open http://localhost:9090
```

---

**🎉 Happy Monitoring!**

