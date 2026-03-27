/**
 * medinovai-real-time-stream-bus — Plain JavaScript SDK
 * Publish and subscribe to events via the REST proxy.
 */

const DEFAULT_BASE_URL = process.env.STREAM_BUS_URL || "http://localhost:3140";

function defaultBaseUrl() {
  return DEFAULT_BASE_URL;
}

function enrichEvent(event, tenantId, correlationId) {
  const enriched = { ...event };
  if (!enriched.timestamp) enriched.timestamp = new Date().toISOString();
  if (!enriched.tenant_id && tenantId) enriched.tenant_id = tenantId;
  if (!enriched.correlation_id && correlationId) enriched.correlation_id = correlationId;
  return enriched;
}

function randomId() {
  return typeof crypto !== "undefined" && crypto.randomUUID
    ? crypto.randomUUID()
    : `gen-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

/**
 * Publish event to Kafka topic via REST proxy.
 */
async function publish(topic, event, options = {}) {
  const baseUrl = (options.baseUrl || defaultBaseUrl()).replace(/\/$/, "");
  const correlationId = options.correlationId || randomId();
  const enriched = enrichEvent(event, options.tenantId, correlationId);

  const res = await fetch(`${baseUrl}/publish/${topic}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ event: enriched }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`StreamBus publish failed: ${res.status} ${text}`);
  }

  return res.json();
}

/**
 * Subscribe to events from topic (long-poll consumer).
 */
async function subscribe(topic, group, handler, options = {}) {
  const baseUrl = (options.baseUrl || defaultBaseUrl()).replace(/\/$/, "");
  const timeoutMs = options.timeoutMs ?? 5000;
  const pollIntervalMs = options.pollIntervalMs ?? 1000;
  const stopSignal = options.stopSignal;

  while (!stopSignal?.aborted) {
    try {
      const url = `${baseUrl}/subscribe/${topic}/${group}?timeout_ms=${timeoutMs}`;
      const res = await fetch(url, { signal: stopSignal });

      if (!res.ok) {
        await new Promise((r) => setTimeout(r, pollIntervalMs));
        continue;
      }

      const data = await res.json();
      for (const msg of data.messages || []) {
        try {
          handler(msg.payload);
        } catch (_) {}
      }
    } catch (err) {
      if (stopSignal?.aborted) break;
    }

    await new Promise((r) => setTimeout(r, pollIntervalMs));
  }
}

/**
 * StreamBus client with connection management.
 */
class StreamBusClient {
  constructor(config = {}) {
    this._baseUrl = config.baseUrl || defaultBaseUrl();
    this._tenantId = config.tenantId;
    this._correlationId = config.correlationId;
  }

  get baseUrl() {
    return this._baseUrl;
  }

  get tenantId() {
    return this._tenantId;
  }

  withTenant(tenantId) {
    return new StreamBusClient({
      baseUrl: this._baseUrl,
      tenantId,
      correlationId: this._correlationId,
    });
  }

  withCorrelation(correlationId) {
    return new StreamBusClient({
      baseUrl: this._baseUrl,
      tenantId: this._tenantId,
      correlationId,
    });
  }

  async publish(topic, event) {
    return publish(topic, event, {
      baseUrl: this._baseUrl,
      tenantId: this._tenantId,
      correlationId: this._correlationId || randomId(),
    });
  }

  async publishEvents(events, topic) {
    const baseUrl = this._baseUrl.replace(/\/$/, "");
    const correlationId = this._correlationId || randomId();
    const enriched = events.map((e) => enrichEvent(e, this._tenantId, correlationId));
    const body = { events: enriched };
    if (topic) body.topic = topic;

    const res = await fetch(`${baseUrl}/events`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`StreamBus publishEvents failed: ${res.status} ${text}`);
    }

    return res.json();
  }

  subscribe(topic, group, handler, options = {}) {
    return subscribe(topic, group, handler, {
      baseUrl: this._baseUrl,
      timeoutMs: options.timeoutMs,
      pollIntervalMs: options.pollIntervalMs,
      stopSignal: options.stopSignal,
    });
  }

  async listTopics() {
    const url = this._baseUrl.replace(/\/$/, "") + "/topics";
    const res = await fetch(url);
    if (!res.ok) throw new Error(`StreamBus listTopics failed: ${res.status}`);
    const data = await res.json();
    return data.topics || [];
  }
}

module.exports = {
  publish,
  subscribe,
  StreamBusClient,
};
