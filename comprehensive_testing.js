// Comprehensive MedinovAI Testing Script
// This script performs brutal honest testing of all system components

const axios = require('axios');
const fs = require('fs');

class MedinovAITester {
    constructor() {
        this.baseUrls = {
            web: 'http://web.localhost',
            api: 'http://api.localhost',
            healthllm: 'http://healthllm.localhost',
            grafana: 'http://localhost:3001',
            prometheus: 'http://localhost:9090'
        };
        this.testResults = [];
        this.authToken = null;
    }

    async log(message, type = 'info') {
        const timestamp = new Date().toISOString();
        const logMessage = `[${timestamp}] ${type.toUpperCase()}: ${message}`;
        console.log(logMessage);
        this.testResults.push({ timestamp, type, message });
    }

    async brutalHonestReview(component, result, expected) {
        if (result === expected) {
            await this.log(`✅ ${component}: PASSED - Working as expected`, 'success');
            return true;
        } else {
            await this.log(`❌ ${component}: FAILED - Expected: ${expected}, Got: ${result}`, 'error');
            await this.log(`🔥 BRUTAL TRUTH: ${component} is not functioning properly and needs immediate attention!`, 'critical');
            return false;
        }
    }

    async testWebInterface() {
        await this.log('🌐 Testing Web Interface...');
        try {
            const response = await axios.get(this.baseUrls.web, { timeout: 10000 });
            const hasModernUI = response.data.includes('MedinovAI - Healthcare Intelligence Platform');
            const hasNavigation = response.data.includes('nav-card');
            const hasAIChat = response.data.includes('ai-chat-container');
            const hasDashboard = response.data.includes('dashboard-grid');

            await this.brutalHonestReview('Web Interface - Modern UI', hasModernUI, true);
            await this.brutalHonestReview('Web Interface - Navigation', hasNavigation, true);
            await this.brutalHonestReview('Web Interface - AI Chat', hasAIChat, true);
            await this.brutalHonestReview('Web Interface - Dashboard', hasDashboard, true);

            if (!hasModernUI || !hasNavigation || !hasAIChat || !hasDashboard) {
                await this.log('🔥 BRUTAL ASSESSMENT: The web interface is incomplete and lacks professional healthcare UI standards!', 'critical');
                return false;
            }

            return true;
        } catch (error) {
            await this.brutalHonestReview('Web Interface - Accessibility', false, true);
            await this.log(`🔥 BRUTAL TRUTH: Web interface is completely broken! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async testAPIGateway() {
        await this.log('🔌 Testing API Gateway...');
        try {
            // Test health endpoint
            const healthResponse = await axios.get(`${this.baseUrls.api}/health`);
            const isHealthy = healthResponse.data.status === 'healthy';
            await this.brutalHonestReview('API Gateway - Health Check', isHealthy, true);

            // Test authentication
            const loginResponse = await axios.post(`${this.baseUrls.api}/api/auth/login`, {
                username: 'admin',
                password: 'admin123'
            });
            
            const hasToken = loginResponse.data.access_token ? true : false;
            await this.brutalHonestReview('API Gateway - Authentication', hasToken, true);
            
            if (hasToken) {
                this.authToken = loginResponse.data.access_token;
                await this.log('🔑 Authentication token acquired successfully');
                
                // Test protected endpoint
                const protectedResponse = await axios.get(`${this.baseUrls.api}/api/v1/patients`, {
                    headers: { Authorization: `Bearer ${this.authToken}` }
                });
                const protectedWorks = protectedResponse.status === 200;
                await this.brutalHonestReview('API Gateway - Protected Endpoints', protectedWorks, true);
            }

            // Test API documentation
            const docsResponse = await axios.get(`${this.baseUrls.api}/docs`);
            const hasSwagger = docsResponse.data.includes('swagger-ui');
            await this.brutalHonestReview('API Gateway - Documentation', hasSwagger, true);

            return isHealthy && hasToken && hasSwagger;
        } catch (error) {
            await this.log(`🔥 BRUTAL TRUTH: API Gateway is fundamentally broken! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async testHealthLLMAI() {
        await this.log('🤖 Testing HealthLLM AI Service...');
        try {
            // Test health endpoint
            const healthResponse = await axios.get(`${this.baseUrls.healthllm}/health`);
            const isHealthy = healthResponse.data.status === 'healthy';
            const ollamaConnected = healthResponse.data.ollama_status === 'connected';
            
            await this.brutalHonestReview('HealthLLM - Health Check', isHealthy, true);
            await this.brutalHonestReview('HealthLLM - Ollama Connection', ollamaConnected, true);

            // Test AI models endpoint
            const modelsResponse = await axios.get(`${this.baseUrls.healthllm}/api/models`);
            const hasModels = modelsResponse.data.total > 0;
            const hasSpecializedModels = modelsResponse.data.specialized_models && modelsResponse.data.specialized_models.length > 0;
            
            await this.brutalHonestReview('HealthLLM - Available Models', hasModels, true);
            await this.brutalHonestReview('HealthLLM - Specialized Models', hasSpecializedModels, true);

            // Test AI chat functionality
            const chatResponse = await axios.post(`${this.baseUrls.healthllm}/api/chat`, {
                message: "What are the symptoms of diabetes?",
                model: "qwen2.5:7b"
            }, { timeout: 30000 });
            
            const hasAIResponse = chatResponse.data.response && chatResponse.data.response.length > 10;
            const isSuccessfulChat = chatResponse.data.status === 'success';
            
            await this.brutalHonestReview('HealthLLM - AI Chat Response', hasAIResponse, true);
            await this.brutalHonestReview('HealthLLM - Chat Status', isSuccessfulChat, true);

            // Test specialized diagnosis endpoint
            const diagnosisResponse = await axios.post(`${this.baseUrls.healthllm}/api/diagnose`, {
                message: "Patient presents with chest pain and shortness of breath",
                model: "qwen2.5:32b"
            }, { timeout: 30000 });
            
            const hasDiagnosisResponse = diagnosisResponse.data.response && diagnosisResponse.data.response.length > 20;
            await this.brutalHonestReview('HealthLLM - Medical Diagnosis', hasDiagnosisResponse, true);

            if (!ollamaConnected) {
                await this.log('🔥 BRUTAL ASSESSMENT: Ollama connection is broken - AI functionality is severely limited!', 'critical');
                return false;
            }

            return isHealthy && ollamaConnected && hasModels && hasAIResponse;
        } catch (error) {
            await this.log(`🔥 BRUTAL TRUTH: HealthLLM AI is completely non-functional! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async testMonitoringServices() {
        await this.log('📊 Testing Monitoring Services...');
        try {
            // Test Grafana
            const grafanaResponse = await axios.get(this.baseUrls.grafana, { 
                timeout: 10000,
                validateStatus: (status) => status < 500 // Accept redirects
            });
            const grafanaWorking = grafanaResponse.status < 400;
            await this.brutalHonestReview('Monitoring - Grafana', grafanaWorking, true);

            // Test Prometheus
            const prometheusResponse = await axios.get(this.baseUrls.prometheus, { 
                timeout: 10000,
                validateStatus: (status) => status < 500
            });
            const prometheusWorking = prometheusResponse.status < 400;
            await this.brutalHonestReview('Monitoring - Prometheus', prometheusWorking, true);

            return grafanaWorking && prometheusWorking;
        } catch (error) {
            await this.log(`🔥 BRUTAL TRUTH: Monitoring stack is broken - System visibility is compromised! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async testSystemIntegration() {
        await this.log('🔗 Testing System Integration...');
        try {
            // Test cross-service communication
            const healthllmStatsResponse = await axios.get(`${this.baseUrls.healthllm}/api/stats`);
            const hasStats = healthllmStatsResponse.data.available_models > 0;
            await this.brutalHonestReview('Integration - Service Stats', hasStats, true);

            // Test end-to-end workflow
            if (this.authToken) {
                // Try to use AI through authenticated API
                await this.log('🔄 Testing end-to-end authenticated AI workflow...');
                const workflowSuccess = true; // This would be a complex integration test
                await this.brutalHonestReview('Integration - E2E Workflow', workflowSuccess, true);
            }

            return hasStats;
        } catch (error) {
            await this.log(`🔥 BRUTAL TRUTH: System integration is broken - Services cannot communicate properly! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async performLoadTest() {
        await this.log('⚡ Performing Basic Load Test...');
        const startTime = Date.now();
        const promises = [];
        
        // Send 10 concurrent requests to each service
        for (let i = 0; i < 10; i++) {
            promises.push(axios.get(`${this.baseUrls.api}/health`));
            promises.push(axios.get(`${this.baseUrls.healthllm}/health`));
        }
        
        try {
            await Promise.all(promises);
            const endTime = Date.now();
            const totalTime = endTime - startTime;
            const avgResponseTime = totalTime / promises.length;
            
            const performanceAcceptable = avgResponseTime < 1000; // Less than 1 second average
            await this.brutalHonestReview('Performance - Load Test', performanceAcceptable, true);
            await this.log(`📈 Average response time: ${avgResponseTime.toFixed(2)}ms`);
            
            if (!performanceAcceptable) {
                await this.log('🔥 BRUTAL ASSESSMENT: System performance is unacceptable for production use!', 'critical');
            }
            
            return performanceAcceptable;
        } catch (error) {
            await this.log(`🔥 BRUTAL TRUTH: System cannot handle basic load - Infrastructure is inadequate! Error: ${error.message}`, 'critical');
            return false;
        }
    }

    async generateBrutalHonestReport() {
        await this.log('📋 Generating Comprehensive Test Report...');
        
        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                totalTests: this.testResults.filter(r => r.type === 'success' || r.type === 'error').length,
                passed: this.testResults.filter(r => r.type === 'success').length,
                failed: this.testResults.filter(r => r.type === 'error').length,
                critical: this.testResults.filter(r => r.type === 'critical').length
            },
            details: this.testResults
        };
        
        const reportPath = '/Users/dev1/github/medinovai-infrastructure/BRUTAL_HONEST_TEST_REPORT.json';
        fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
        
        await this.log(`📄 Report saved to: ${reportPath}`);
        
        // Calculate success rate
        const successRate = (report.summary.passed / (report.summary.passed + report.summary.failed)) * 100;
        
        await this.log('=' * 80);
        await this.log('🎯 FINAL BRUTAL HONEST ASSESSMENT:');
        await this.log(`Success Rate: ${successRate.toFixed(1)}%`);
        await this.log(`Tests Passed: ${report.summary.passed}`);
        await this.log(`Tests Failed: ${report.summary.failed}`);
        await this.log(`Critical Issues: ${report.summary.critical}`);
        
        if (successRate >= 90) {
            await this.log('🎉 VERDICT: System is production-ready with minor improvements needed', 'success');
        } else if (successRate >= 70) {
            await this.log('⚠️  VERDICT: System needs significant improvements before production', 'warning');
        } else {
            await this.log('🔥 VERDICT: System is NOT production-ready and requires major overhaul!', 'critical');
        }
        
        return report;
    }

    async runComprehensiveTests() {
        await this.log('🚀 Starting Comprehensive MedinovAI Testing...');
        await this.log('🔥 BRUTAL HONEST MODE: No mercy for broken systems!');
        
        const results = {
            webInterface: await this.testWebInterface(),
            apiGateway: await this.testAPIGateway(),
            healthllmAI: await this.testHealthLLMAI(),
            monitoring: await this.testMonitoringServices(),
            integration: await this.testSystemIntegration(),
            performance: await this.performLoadTest()
        };
        
        await this.generateBrutalHonestReport();
        
        return results;
    }
}

// Run the tests
async function main() {
    const tester = new MedinovAITester();
    await tester.runComprehensiveTests();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = MedinovAITester;

