# 🔍 Detailed Infrastructure Software Findings

**Date**: Thu Oct  2 10:32:38 EDT 2025
**Repositories Scanned**: 37 local repos

---

## 📦 `medinovai-infrastructure`


  - **requirements.txt**: Database/Infrastructure clients
```
prometheus-client>=0.17.0
psycopg2-binary>=2.9.0
grafana-api>=1.0.3
prometheus-api-client>=0.5.3
```
  - **Makefile**: Infrastructure installation commands

---

## 📦 `medinovai-data-services`


  - **requirements.txt**: Database/Infrastructure clients
```
psycopg2-binary>=2.9.9
# Redis
redis>=5.0.1
prometheus-client>=0.19.0
```

---

## 📦 `medinovai-security-services`


  - **requirements.txt**: Database/Infrastructure clients
```
psycopg2-binary>=2.9.9
# Redis
redis>=5.0.1
prometheus-client>=0.19.0
```

---

## 📦 `medinovai-clinical-services`


  - **requirements.txt**: Database/Infrastructure clients
```
psycopg2-binary==2.9.9
redis==5.0.1
```
  - **Kubernetes**: StatefulSet (likely database/stateful service)

---

## 📦 `medinovaios`


  - **Docker Compose**: Contains infrastructure services
```
  # PostgreSQL Database
  healthllm-postgres:
    image: postgres:15-alpine
    container_name: healthllm-postgres
      POSTGRES_DB: healthllm
      POSTGRES_USER: healthllm
      POSTGRES_PASSWORD: healthllm
      - healthllm-postgres-data:/var/lib/postgresql/data
  # Redis Cache
  healthllm-redis:
```
  - **requirements.txt**: Database/Infrastructure clients
```
prometheus-client>=0.19.0
```
  - **Kubernetes**: StatefulSet (likely database/stateful service)

---

## 📦 `PersonalAssistant`


  - **Docker Compose**: Contains infrastructure services
```
  # PostgreSQL database for PersonalAssistant
  postgres:
    image: postgres:15-alpine
    container_name: personal-assistant-postgres
      - POSTGRES_DB=personal_assistant
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - postgres_data:/var/lib/postgresql/data
      test: ["CMD-SHELL", "pg_isready -U postgres -d personal_assistant"]
  # Redis for caching and sessions
```
  - **Makefile**: Infrastructure installation commands

---

## 📦 `medinovai-registry`


  - **requirements.txt**: Database/Infrastructure clients
```
psycopg2-binary>=2.9.9
# Redis
redis>=5.0.1
prometheus-client>=0.19.0
```

---

## 📦 `medinovai-Developer`


  - **requirements.txt**: Database/Infrastructure clients
```
redis==5.0.1
psycopg2-binary==2.9.9
prometheus-client==0.19.0
```

---

## 📊 Summary

**Total Repositories with Infrastructure**: 8

