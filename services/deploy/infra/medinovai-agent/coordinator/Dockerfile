FROM python:3.12-slim

LABEL org.opencontainers.image.title="MedinovAI Coordinator"
LABEL org.opencontainers.image.vendor="MyOnsite Healthcare"

# Security: run as non-root
RUN groupadd -r medinovai && useradd -r -g medinovai medinovai

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

USER medinovai

EXPOSE 8435

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8435/v1/health')"

ENV HOST=0.0.0.0
ENV PORT=8435
ENV LOG_LEVEL=INFO

CMD ["python3", "main.py"]
