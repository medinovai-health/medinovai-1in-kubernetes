#!/usr/bin/env python3
"""
MedinovAI Flask Service Template
Healthcare-compliant microservice template with AI integration
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
import os
import sys
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MedinovAIService:
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.app = Flask(__name__)
        CORS(self.app)
        self.setup_routes()
        
    def setup_routes(self):
        """Setup standard MedinovAI service routes"""
        
        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Health check endpoint"""
            return jsonify({
                'status': 'healthy',
                'service': self.service_name,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'version': '1.0.0'
            })
        
        @self.app.route('/info', methods=['GET'])
        def service_info():
            """Service information endpoint"""
            return jsonify({
                'service': self.service_name,
                'version': '1.0.0',
                'description': f'MedinovAI {self.service_name} service',
                'healthcare_compliant': True,
                'ai_integrated': True,
                'endpoints': [
                    '/health',
                    '/info',
                    '/metrics'
                ]
            })
        
        @self.app.route('/metrics', methods=['GET'])
        def metrics():
            """Prometheus metrics endpoint"""
            return jsonify({
                'service_requests_total': 0,
                'service_errors_total': 0,
                'service_duration_seconds': 0.0
            })
    
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the service"""
        logger.info(f"Starting {self.service_name} service on {host}:{port}")
        self.app.run(host=host, port=port, debug=debug)

# Example usage
if __name__ == '__main__':
    service = MedinovAIService('example-service')
    service.run()
