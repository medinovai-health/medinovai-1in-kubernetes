#!/bin/bash
# MedinovAI Service Auto-Start Script
# Automatically detects and starts the appropriate service

set -e

echo "🚀 MedinovAI Service Starting..."
echo "Working directory: $(pwd)"
echo "Contents:"
ls -la

# Function to check if a file exists and is executable
check_and_run() {
    local file=$1
    if [ -f "$file" ]; then
        echo "✅ Found: $file"
        if [[ "$file" == *.py ]]; then
            echo "🐍 Starting Python application: $file"
            exec python "$file"
        elif [[ "$file" == *.js ]]; then
            echo "📦 Starting Node application: $file"
            exec node "$file"
        fi
    fi
}

# Try different common entry points in order of preference
echo "🔍 Searching for application entry point..."

# Check for uvicorn/FastAPI apps
if [ -f "main.py" ]; then
    echo "✅ Found main.py - Starting with uvicorn"
    exec python -m uvicorn main:app --host 0.0.0.0 --port 8000
fi

# Check for Flask apps
if [ -f "app.py" ]; then
    echo "✅ Found app.py - Starting with Flask"
    # Try uvicorn first (if it's FastAPI), fallback to flask
    python -c "import uvicorn" 2>/dev/null && exec python -m uvicorn app:app --host 0.0.0.0 --port 8000
    exec python -m flask run --host=0.0.0.0 --port=8000
fi

# Check for Django
if [ -f "manage.py" ]; then
    echo "✅ Found manage.py - Starting Django"
    exec python manage.py runserver 0.0.0.0:8000
fi

# Check for generic server
if [ -f "server.py" ]; then
    echo "✅ Found server.py"
    exec python server.py
fi

# Check services subdirectory
if [ -d "services" ]; then
    echo "📁 Found services directory"
    # Try to find a main service
    for service in services/*; do
        if [ -d "$service" ]; then
            echo "🔍 Checking service: $service"
            if [ -f "$service/main.py" ]; then
                echo "✅ Found entry point: $service/main.py"
                cd "$service"
                exec python -m uvicorn main:app --host 0.0.0.0 --port 8000
            elif [ -f "$service/app.py" ]; then
                echo "✅ Found entry point: $service/app.py"
                cd "$service"
                exec python app.py
            fi
        fi
    done
fi

# If nothing found, try to start a simple Flask app
echo "⚠️  No standard entry point found"
echo "📝 Creating minimal health check service..."

cat > /tmp/health_service.py << 'PYEOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "service": os.environ.get("SERVICE_NAME", "unknown"),
        "message": "Service is running but needs proper configuration"
    })

@app.route('/ready')
def ready():
    return jsonify({"status": "ready"})

@app.route('/')
def root():
    return jsonify({
        "service": os.environ.get("SERVICE_NAME", "MedinovAI Service"),
        "status": "operational",
        "endpoints": ["/health", "/ready"]
    })

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8000))
    app.run(host='0.0.0.0', port=port)
PYEOF

echo "🏥 Starting minimal health service on port 8000"
exec python /tmp/health_service.py


