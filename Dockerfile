FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir fastapi uvicorn pydantic pyyaml

# Copy configuration and docs
COPY config/ ./config/ 2>/dev/null || true
COPY docs/ ./docs/ 2>/dev/null || true
COPY main.py ./ 2>/dev/null || true

ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV SERVICE_NAME=medinovai-infrastructure

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
