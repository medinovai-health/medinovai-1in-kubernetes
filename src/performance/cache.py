"""Performance optimization & caching for medinovai-1in-kubernetes."""
# (c) 2026 MedinovAI — Sprint 13: Performance Optimization & Caching
import functools
import hashlib
import json
import time
from typing import Any, Callable, Optional
from collections import OrderedDict
import threading

# ── In-Memory LRU Cache ─────────────────────────────────
class LRUCache:
    """Thread-safe LRU cache with TTL support."""
    
    def __init__(self, max_size: int = 10000, default_ttl: int = 300):
        self._cache: OrderedDict = OrderedDict()
        self._max_size = max_size
        self._default_ttl = default_ttl
        self._lock = threading.Lock()
        self._hits = 0
        self._misses = 0
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache, returns None if expired or missing."""
        with self._lock:
            if key in self._cache:
                value, expiry = self._cache[key]
                if time.time() < expiry:
                    self._cache.move_to_end(key)
                    self._hits += 1
                    return value
                else:
                    del self._cache[key]
            self._misses += 1
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in cache with TTL."""
        with self._lock:
            if key in self._cache:
                del self._cache[key]
            elif len(self._cache) >= self._max_size:
                self._cache.popitem(last=False)
            self._cache[key] = (value, time.time() + (ttl or self._default_ttl))
    
    def invalidate(self, key: str) -> None:
        """Remove a specific key from cache."""
        with self._lock:
            self._cache.pop(key, None)
    
    def clear(self) -> None:
        """Clear all cache entries."""
        with self._lock:
            self._cache.clear()
    
    @property
    def hit_rate(self) -> float:
        """Calculate cache hit rate."""
        total = self._hits + self._misses
        return self._hits / total if total > 0 else 0.0
    
    @property
    def stats(self) -> dict:
        """Return cache statistics."""
        return {
            "size": len(self._cache),
            "max_size": self._max_size,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": f"{self.hit_rate:.1%}",
        }


# ── Global Cache Instance ────────────────────────────────
_app_cache = LRUCache(max_size=10000, default_ttl=300)


# ── Cache Decorator ──────────────────────────────────────
def cached(ttl: int = 300, key_prefix: str = ""):
    """Decorator to cache function results."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{key_prefix or func.__name__}:{hashlib.md5(json.dumps((args, sorted(kwargs.items())), default=str).encode()).hexdigest()[:12]}"
            result = _app_cache.get(cache_key)
            if result is not None:
                return result
            result = func(*args, **kwargs)
            _app_cache.set(cache_key, result, ttl)
            return result
        wrapper.cache_invalidate = lambda: _app_cache.clear()
        return wrapper
    return decorator


# ── Query Optimizer ──────────────────────────────────────
class QueryOptimizer:
    """Track and optimize database query performance."""
    
    def __init__(self):
        self._slow_queries: list = []
        self._query_times: dict = {}
        self._lock = threading.Lock()
    
    def record(self, query: str, duration_ms: float) -> None:
        """Record query execution time."""
        with self._lock:
            if duration_ms > 50:
                self._slow_queries.append({
                    "query": query[:200],
                    "duration_ms": duration_ms,
                    "timestamp": time.time(),
                })
                if len(self._slow_queries) > 1000:
                    self._slow_queries = self._slow_queries[-500:]
            
            key = query[:100]
            if key not in self._query_times:
                self._query_times[key] = []
            self._query_times[key].append(duration_ms)
            if len(self._query_times[key]) > 100:
                self._query_times[key] = self._query_times[key][-50:]
    
    @property
    def slow_query_report(self) -> list:
        """Return recent slow queries."""
        with self._lock:
            return sorted(self._slow_queries, key=lambda q: q["duration_ms"], reverse=True)[:20]


# ── Connection Pool Monitor ──────────────────────────────
class ConnectionPoolMonitor:
    """Monitor database connection pool health."""
    
    def __init__(self, pool_size: int = 20, max_overflow: int = 10):
        self._pool_size = pool_size
        self._max_overflow = max_overflow
        self._active = 0
        self._waiting = 0
        self._lock = threading.Lock()
    
    def acquire(self) -> bool:
        """Attempt to acquire a connection."""
        with self._lock:
            if self._active < self._pool_size + self._max_overflow:
                self._active += 1
                return True
            self._waiting += 1
            return False
    
    def release(self) -> None:
        """Release a connection back to pool."""
        with self._lock:
            self._active = max(0, self._active - 1)
    
    @property
    def stats(self) -> dict:
        """Return pool statistics."""
        return {
            "active": self._active,
            "available": self._pool_size - self._active,
            "pool_size": self._pool_size,
            "max_overflow": self._max_overflow,
            "utilization": f"{self._active / self._pool_size:.0%}",
        }


# ── Response Compression ─────────────────────────────────
def should_compress(content_length: int, content_type: str) -> bool:
    """Determine if response should be compressed."""
    compressible_types = ["application/json", "text/html", "text/plain", "text/css", "application/javascript"]
    return content_length > 1024 and any(ct in content_type for ct in compressible_types)


# ── Performance Metrics ──────────────────────────────────
class PerformanceMetrics:
    """Collect and report performance metrics."""
    
    def __init__(self):
        self._request_times: list = []
        self._lock = threading.Lock()
    
    def record_request(self, path: str, method: str, duration_ms: float, status: int) -> None:
        """Record a request metric."""
        with self._lock:
            self._request_times.append({
                "path": path,
                "method": method,
                "duration_ms": duration_ms,
                "status": status,
                "timestamp": time.time(),
            })
            if len(self._request_times) > 10000:
                self._request_times = self._request_times[-5000:]
    
    def percentile(self, p: float) -> float:
        """Calculate response time percentile."""
        with self._lock:
            if not self._request_times:
                return 0.0
            times = sorted(r["duration_ms"] for r in self._request_times)
            idx = int(len(times) * p / 100)
            return times[min(idx, len(times) - 1)]
    
    @property
    def summary(self) -> dict:
        """Return performance summary."""
        return {
            "total_requests": len(self._request_times),
            "p50_ms": self.percentile(50),
            "p95_ms": self.percentile(95),
            "p99_ms": self.percentile(99),
            "cache_stats": _app_cache.stats,
        }
