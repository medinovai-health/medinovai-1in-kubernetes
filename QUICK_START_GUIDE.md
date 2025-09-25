# 🚀 MedinovAI Quick Start Guide

## Immediate Access

### 🌐 Primary Web Application
**URL:** http://web.localhost  
**Description:** Modern healthcare dashboard with AI assistant

### 🤖 AI Healthcare Assistant
**URL:** http://web.localhost (AI section)  
**Features:** Ask healthcare questions, get AI-powered medical insights

### 📚 API Documentation
**URL:** http://api.localhost/docs  
**Description:** Interactive API documentation with testing interface

## 🔧 Management Interfaces

### 📊 Monitoring Dashboard
**URL:** http://grafana.localhost  
**Login:** admin / admin  
**Features:** System metrics, custom dashboards, alerts

### 📈 Metrics Collection
**URL:** http://prometheus.localhost  
**Features:** Raw metrics, query interface, targets status

### 🔀 Traffic Management
**URL:** http://localhost:8080  
**Features:** Traefik dashboard, route management, service discovery

## 🗄️ Database Access

### PostgreSQL
**Host:** postgres.localhost  
**Port:** 5432  
**Database:** medinovai  
**Username:** medinovai  
**Password:** medinovai123

### Redis
**Host:** redis.localhost  
**Port:** 6379  
**Features:** Caching, session storage, real-time data

## 🤖 AI Models Available

### Quick Test Commands
```bash
# Test API Gateway
curl http://api.localhost/health

# Test HealthLLM
curl http://healthllm.localhost/health

# Test AI Query (via web interface)
# Go to http://web.localhost and use the AI assistant
```

### Available Models
- **meditron:7b** - Healthcare-optimized
- **qwen2.5:72b** - Large language model
- **deepseek-coder:33b** - Code-oriented
- **llama3.1:70b** - General purpose
- **1,200+ more models** available via Ollama

## 🚨 Quick Troubleshooting

### Check All Services
```bash
docker ps
```

### View Service Logs
```bash
docker logs medinovai-api-gateway
docker logs medinovai-healthllm
docker logs medinovai-frontend
```

### Restart Services
```bash
docker restart medinovai-api-gateway
docker restart medinovai-healthllm
docker restart medinovai-frontend
```

## 🎯 First Steps

1. **Open the web application:** http://web.localhost
2. **Test the AI assistant** with a healthcare question
3. **Check monitoring:** http://grafana.localhost (admin/admin)
4. **Explore the API:** http://api.localhost/docs
5. **Review the full report:** medinovai-deployment-report.md

## 📞 Support

- **Full Documentation:** medinovai-deployment-report.md
- **Service Status:** Check the web dashboard at http://web.localhost
- **Logs:** Use `docker logs <service-name>` for debugging

---

**🎉 Your MedinovAI healthcare platform is ready to use!**








