# tracing.py — medinovai-1in-kubernetes
# Build: 20260413.3000.001 | © 2026 DescartesBio / MedinovAI Health.
import os
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

def setup_tracing(app):
    """
    Configures Jaeger distributed tracing for the FastAPI application.
    """
    resource = Resource(attributes={
        SERVICE_NAME: "1in-kubernetes"
    })
    
    provider = TracerProvider(resource=resource)
    trace.set_tracer_provider(provider)
    
    # Configure Jaeger Exporter
    jaeger_host = os.getenv("JAEGER_AGENT_HOST", "jaeger.tailnet.medinovai")
    jaeger_port = int(os.getenv("JAEGER_AGENT_PORT", 6831))
    
    jaeger_exporter = JaegerExporter(
        agent_host_name=jaeger_host,
        agent_port=jaeger_port,
    )
    
    provider.add_span_processor(BatchSpanProcessor(jaeger_exporter))
    
    # Auto-instrument FastAPI, HTTPX, and SQLAlchemy
    FastAPIInstrumentor.instrument_app(app)
    HTTPXClientInstrumentor().instrument()
    SQLAlchemyInstrumentor().instrument()
    
    return provider
