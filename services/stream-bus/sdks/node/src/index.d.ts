export interface StreamBusConfig {
  baseUrl?: string;
  tenantId?: string;
  correlationId?: string;
}

export interface PublishResult {
  status: string;
  topic: string;
  key: string;
  event_type?: string;
  timestamp: string;
}

export type EventHandler = (payload: Record<string, unknown>) => void;

export function publish(
  topic: string,
  event: Record<string, unknown>,
  options?: { baseUrl?: string; tenantId?: string; correlationId?: string }
): Promise<PublishResult>;

export function subscribe(
  topic: string,
  group: string,
  handler: EventHandler,
  options?: {
    baseUrl?: string;
    timeoutMs?: number;
    pollIntervalMs?: number;
    stopSignal?: AbortSignal;
  }
): Promise<void>;

export class StreamBusClient {
  constructor(config?: StreamBusConfig);
  readonly baseUrl: string;
  readonly tenantId?: string;
  withTenant(tenantId: string): StreamBusClient;
  withCorrelation(correlationId: string): StreamBusClient;
  publish(topic: string, event: Record<string, unknown>): Promise<PublishResult>;
  publishEvents(
    events: Record<string, unknown>[],
    topic?: string
  ): Promise<{ status: string; results: unknown[] }>;
  subscribe(
    topic: string,
    group: string,
    handler: EventHandler,
    options?: { timeoutMs?: number; pollIntervalMs?: number; stopSignal?: AbortSignal }
  ): Promise<void>;
  listTopics(): Promise<string[]>;
}
