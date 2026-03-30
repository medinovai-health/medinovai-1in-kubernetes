FROM python:3.14-slim
WORKDIR /app
COPY . .
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN if [ -f pyproject.toml ]; then pip install --no-cache-dir .; fi
ENV PYTHONUNBUFFERED=1 PORT=8080
EXPOSE 8080
CMD ["python", "scripts/auto_resolve_conflicts.py"]
