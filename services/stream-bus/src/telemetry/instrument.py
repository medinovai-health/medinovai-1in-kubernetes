"""
OpenTelemetry SDK Instrumentation — Real-time Stream Bus (medinovai-real-time-stream-bus)
Auto-instruments HTTP, DB, and custom spans.
"""
import logging
import os
from typing import Any, Callable

mos_logger = logging.getLogger("medinovai-real-time-stream-bus.otel")

E_SERVICE_NAME = "real-time-stream-bus"
E_SERVICE_VERSION = os.getenv("SERVICE_VERSION", "1.0.0")
E_OTEL_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317")


def mos_initTelemetry() -> None:
    """Initialize OpenTelemetry SDK with auto-instrumentation."""
    try:
        from opentelemetry import trace
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
        from opentelemetry.instrumentation.requests import RequestsInstrumentor  # type: ignore
        from opentelemetry.instrumentation.logging import LoggingInstrumentor  # type: ignore

        mos_resource = Resource.create({
            SERVICE_NAME: E_SERVICE_NAME,
            SERVICE_VERSION: E_SERVICE_VERSION,
            "service.tier": "2",
            "deployment.environment": os.getenv("DEPLOY_ENV", "development"),
        })
        mos_provider = TracerProvider(resource=mos_resource)
        mos_exporter = OTLPSpanExporter(endpoint=E_OTEL_ENDPOINT)
        mos_provider.add_span_processor(BatchSpanProcessor(mos_exporter))
        trace.set_tracer_provider(mos_provider)

        # Auto-instrument
        RequestsInstrumentor().instrument()
        LoggingInstrumentor().instrument(set_logging_format=True)

        mos_logger.info("OTel initialized: %s → %s", E_SERVICE_NAME, E_OTEL_ENDPOINT)
    except ImportError as e:
        mos_logger.warning("OTel SDK not installed: %s", e)


def mos_createSpan(mos_name: str):
    """Decorator: wrap function in a custom OTel span."""
    def decorator(func: Callable) -> Callable:
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                from opentelemetry import trace
                tracer = trace.get_tracer(E_SERVICE_NAME)
                with tracer.start_as_current_span(mos_name) as span:
                    try:
                        result = await func(*args, **kwargs)
                        span.set_status(trace.StatusCode.OK)
                        return result
                    except Exception as e:
                        span.set_status(trace.StatusCode.ERROR, str(e))
                        span.record_exception(e)
                        raise
            except ImportError:
                return await func(*args, **kwargs)
        return wrapper
    return decorator
