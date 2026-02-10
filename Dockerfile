FROM python:3.11-slim as builder

WORKDIR /usr/src/app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

FROM python:3.11-slim

RUN useradd --create-home appuser

WORKDIR /home/appuser/app

COPY --from=builder /usr/src/app .

RUN chown -R appuser:appuser /home/appuser/app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8000/health || exit 1

LABEL maintainer="devops@medinovai.com"
LABEL version="1.0.0"
LABEL description="MedinovAI Canary Rollout Orchestrator"

CMD ["gunicorn", "--bind", ":8000", "--workers", "3", "app.main:app"]
