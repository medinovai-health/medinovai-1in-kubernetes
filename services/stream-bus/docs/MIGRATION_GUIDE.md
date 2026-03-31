# Migration Guide

**Service:** medinovai-real-time-stream-bus  
**Target Version:** 1.0.0  
**Date:** 2025-10-24

---

## Overview

This guide helps you migrate to the versioned API for medinovai-real-time-stream-bus.

## Breaking Changes

### Version 1.0.0 (Initial Versioned Release)

**Changes:**
1. All routes now use `/api/v1/` prefix
2. All requests (except `/api/version`) require `X-Client-Version` header
3. Responses include version headers

**Migration Steps:**

1. **Update API URLs**
   ```diff
   - https://medinovai-real-time-stream-bus.medinovai.com/data
   + https://medinovai-real-time-stream-bus.medinovai.com/api/v1/data
   ```

2. **Add Version Headers**
   ```javascript
   // Before
   fetch('https://medinovai-real-time-stream-bus.medinovai.com/data')
   
   // After
   fetch('https://medinovai-real-time-stream-bus.medinovai.com/api/v1/data', {
     headers: {
       'X-Client-Version': '1.0.0'
     }
   })
   ```

3. **Handle Version Errors**
   ```javascript
   const response = await fetch(url, { headers });
   
   if (response.status === 409) {
     // Version incompatibility
     const error = await response.json();
     console.error('Version incompatibility:', error.message);
     // Upgrade client or handle gracefully
   }
   
   if (response.status === 400) {
     // Missing version header
     const error = await response.json();
     console.error('Missing version header:', error.message);
   }
   ```

## Compatibility

### Backward Compatibility

**Version 1.0.0 is NOT backward compatible** with pre-versioned API because:
- Routes changed from `/` to `/api/v1/`
- Version headers are now required

**Migration Timeline:**
- **Phase 1 (Week 1):** Deploy v1 API alongside legacy API
- **Phase 2 (Week 2-4):** Migrate clients to v1 API
- **Phase 3 (Week 5):** Deprecate legacy API
- **Phase 4 (Week 8):** Remove legacy API

### Forward Compatibility

**Version 1.0.0 is forward compatible** with future 1.x.x versions:
- Minor version updates (1.1.0, 1.2.0) will be backward compatible
- Patch version updates (1.0.1, 1.0.2) will be backward compatible
- Major version updates (2.0.0) will require migration

## Testing

### Test Your Integration

1. **Update client version**
   ```bash
   npm install @medinovai/medinovai-real-time-stream-bus-client@^1.0.0
   ```

2. **Run integration tests**
   ```bash
   npm test
   ```

3. **Verify version headers**
   ```bash
   curl -v -H "X-Client-Version: 1.0.0" \
     https://medinovai-real-time-stream-bus.medinovai.com/api/v1/data
   ```

## Rollback Plan

If you encounter issues:

1. **Revert to legacy API** (if still available)
2. **Contact support** at platform@medinovai.com
3. **Check status page** at https://status.medinovai.com

## Support

**Documentation:**
- [Versioning Implementation](VERSIONING_IMPLEMENTATION.md)
- [API Reference](https://docs.medinovai.com/medinovai-real-time-stream-bus)
- [MedinovAI Versioning System](https://docs.medinovai.com/versioning)

**Contact:**
- Email: platform@medinovai.com
- Slack: #platform-support
- GitHub Issues: https://github.com/myonsite-healthcare/medinovai-real-time-stream-bus/issues

---

**Last Updated:** 2025-10-24  
**Version:** 1.0.0
