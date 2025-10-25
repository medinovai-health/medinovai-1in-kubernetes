# medinovai-real-time-stream-bus

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![API Version](https://img.shields.io/badge/api-v1-green)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

# medinovai-real-time-stream-bus
medinovai-real-time-stream-bus service

---

## Versioning

This service follows [Semantic Versioning](https://semver.org/) and implements comprehensive API and schema versioning.

**Current Versions:**
- **Service:** 1.0.0
- **API:** v1
- **Schema:** 1.0.0

**Version Endpoint:** `GET /api/version`

For detailed versioning information, see:
- [Versioning Implementation Guide](docs/VERSIONING_IMPLEMENTATION.md)
- [Changelog](CHANGELOG.md)
- [MedinovAI Versioning System](https://github.com/myonsite-healthcare/architecture-catalog/blob/main/docs/MEDINOVAI_VERSIONING_SYSTEM.md)

### Version Headers

All API requests must include the `X-Client-Version` header:

```bash
curl -H "X-Client-Version: 1.0.0" https://medinovai-real-time-stream-bus.medinovai.com/api/v1/data
```

---
