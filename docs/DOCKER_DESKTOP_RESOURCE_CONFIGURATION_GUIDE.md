# 🔧 Docker Desktop Resource Configuration Guide

**System**: Mac Studio M3 Ultra  
**Total Resources**: 32 CPUs, 512GB RAM  
**Current Docker Allocation**: 8 CPUs, 123GB RAM (15% utilization)  
**Target Allocation**: 24 CPUs, 400GB RAM (75% utilization)

---

## 📋 MANUAL CONFIGURATION REQUIRED

Docker Desktop on macOS does not support programmatic resource configuration changes. You must change settings through the GUI.

---

## 🎯 STEP-BY-STEP INSTRUCTIONS

### Step 1: Open Docker Desktop Settings
1. Click the Docker icon in your macOS menu bar (top right)
2. Select **"Settings..."** or **"Preferences..."**
3. Navigate to **"Resources"** section
4. Click on **"Advanced"** tab

### Step 2: Update Resource Limits

#### Current Settings:
```
CPUs: 8
Memory: 123GB (126,156 MB)
Swap: 1GB
Disk image size: [Current value]
```

#### Recommended New Settings:
```
CPUs: 24  (leave 8 for macOS + Ollama + other apps)
Memory: 400GB (409,600 MB)  (leave 112GB for macOS + Ollama)
Swap: 8GB (8,192 MB)  (increased for stability)
Disk image size: Keep current or increase to 500GB if needed
```

### Step 3: Apply Changes
1. Click **"Apply & Restart"** button
2. Wait for Docker to restart (2-5 minutes)
3. Verify new settings in terminal

---

## 🔍 VERIFICATION COMMANDS

After Docker Desktop restarts, run these commands to verify:

```bash
# Check new CPU allocation
docker info | grep CPUs
# Expected: CPUs: 24

# Check new memory allocation  
docker info | grep "Total Memory"
# Expected: Total Memory: 391GiB or ~400GB

# Full Docker info
docker info
```

---

## 📊 RESOURCE ALLOCATION RATIONALE

### Why 24 CPUs (not all 32)?
- **Docker**: 24 CPUs (75%)
- **macOS System**: 4 CPUs (12.5%)
- **Ollama (Native)**: 4 CPUs (12.5%)
- **Total**: 32 CPUs (100%)

**Justification**: Leaves enough resources for macOS and Ollama running natively

### Why 400GB RAM (not all 512GB)?
- **Docker**: 400GB (78%)
- **macOS System**: 32GB (6%)
- **Ollama Models**: 80GB (16%) - Large models in memory
- **Total**: 512GB (100%)

**Justification**: Ollama with 67+ models needs significant RAM

---

## ⚠️ IMPORTANT NOTES

### Before Making Changes:
1. ✅ **Stop any critical containers** if needed
2. ✅ **Save your work** in any running containers
3. ✅ **Backup Docker volumes** if they contain critical data
4. ✅ **Close unnecessary applications** to free up RAM during restart

### After Making Changes:
1. Monitor system performance for 10-15 minutes
2. Check Activity Monitor to ensure macOS has enough resources
3. Test Ollama performance (run a few model queries)
4. Verify container startup times haven't degraded

### If System Becomes Unstable:
**Conservative Fallback Settings**:
```
CPUs: 16  (50% of available)
Memory: 300GB (320GB ~58% of available)
Swap: 4GB
```

Then gradually increase if stable.

---

## 🎯 EXPECTED IMPROVEMENTS

### After Reconfiguration:

**Container Performance**:
- ✅ 3x more CPU cores available
- ✅ 3.2x more memory available
- ✅ Can run 14+ MedinovAI services simultaneously
- ✅ Reduced resource contention
- ✅ Better Kubernetes pod scheduling

**System Capacity**:
- **Before**: ~7-10 medium containers comfortably
- **After**: ~30-40 medium containers comfortably
- **Kubernetes Pods**: Can support 50-100 pods easily

**Deployment Readiness**:
- Can run full MedinovAI platform locally
- Multiple environments (dev/stage) simultaneously
- Heavy AI workloads supported

---

## 🔄 WHEN TO ADJUST FURTHER

### Increase Docker Resources If:
- You're not running Ollama natively anymore
- You need to run more containers
- Containers are being OOM killed
- CPU throttling observed

### Decrease Docker Resources If:
- macOS becomes sluggish
- Ollama models are slow to load
- System swapping to disk frequently
- Activity Monitor shows macOS under 20GB RAM

---

## 📈 MONITORING RECOMMENDATIONS

### After Reconfiguration, Monitor:

**Every 5 Minutes (First Hour)**:
```bash
docker stats --no-stream
top -l 1 | head -20
```

**Daily (First Week)**:
```bash
# Check Docker resource usage
docker system df

# Check system memory pressure
vm_stat | head -10

# Check swap usage
sysctl vm.swapusage
```

---

## 🚨 ROLLBACK PROCEDURE

If you need to rollback to original settings:

1. Open Docker Desktop Settings → Resources → Advanced
2. Set:
   - CPUs: 8
   - Memory: 123GB (126,156 MB)
   - Swap: 1GB (1,024 MB)
3. Click "Apply & Restart"
4. Wait for Docker to restart

---

## ✅ COMPLETION CHECKLIST

Before proceeding to next step, verify:

- [ ] Docker Desktop settings changed
- [ ] Docker Desktop restarted successfully
- [ ] `docker info` shows CPUs: 24
- [ ] `docker info` shows Memory: ~400GB
- [ ] Existing containers still running (if applicable)
- [ ] System responsive (Activity Monitor check)
- [ ] No excessive swap usage
- [ ] Ollama still responding on localhost:11434

---

## 🤖 MULTI-MODEL VALIDATION NEEDED

After completing the reconfiguration, we will validate with models:
1. Is 24 CPUs / 400GB RAM optimal for this use case?
2. Should we allocate differently?
3. Any risks or concerns?

---

**Status**: ⏳ AWAITING MANUAL CONFIGURATION  
**Action Required**: User must manually change Docker Desktop settings  
**Estimated Time**: 5-10 minutes (including Docker restart)  

---

**After you've made the changes and Docker has restarted, let me know and I'll verify the configuration and proceed to the next step!**

