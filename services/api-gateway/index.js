const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { createProxyMiddleware } = require('http-proxy-middleware');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const winston = require('winston');
const promClient = require('prom-client');
require('dotenv').config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8080;

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);

// Logger configuration
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));
app.use(compression());
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api/', limiter);

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode
    };
    
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });
  
  next();
});

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'MedinovaIOS API Gateway',
      version: '1.0.0',
      description: 'API Gateway for MedinovaIOS Healthcare Platform'
    },
    servers: [
      {
        url: `http://localhost:${PORT}`,
        description: 'Development server'
      }
    ]
  },
  apis: ['./routes/*.js', './index.js']
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Health check endpoint
/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check endpoint
 *     responses:
 *       200:
 *         description: Service is healthy
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// Ready check endpoint
app.get('/ready', (req, res) => {
  // Add readiness checks here (database, external services, etc.)
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString()
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Service proxy configurations
const serviceRoutes = {
  '/api/auth': {
    target: 'http://user-management:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/auth': '/auth' }
  },
  '/api/users': {
    target: 'http://user-management:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/users': '/users' }
  },
  '/api/medications': {
    target: 'http://medication-management:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/medications': '/medications' }
  },
  '/api/prescriptions': {
    target: 'http://medication-management:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/prescriptions': '/prescriptions' }
  },
  '/api/clinical': {
    target: 'http://clinical-decision-support:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/clinical': '/clinical' }
  },
  '/api/ehr': {
    target: 'http://ehr-integration:8080',
    changeOrigin: true,
    pathRewrite: { '^/api/ehr': '/ehr' }
  }
};

// Apply proxy middleware for each service
Object.entries(serviceRoutes).forEach(([path, config]) => {
  app.use(path, createProxyMiddleware({
    ...config,
    onError: (err, req, res) => {
      logger.error('Proxy error:', err);
      res.status(500).json({ error: 'Service temporarily unavailable' });
    },
    onProxyReq: (proxyReq, req, res) => {
      logger.info(`Proxying ${req.method} ${req.path} to ${config.target}`);
    }
  }));
});

// API root endpoint
/**
 * @swagger
 * /api:
 *   get:
 *     summary: API information
 *     responses:
 *       200:
 *         description: API information
 */
app.get('/api', (req, res) => {
  res.json({
    name: 'MedinovaIOS API Gateway',
    version: '1.0.0',
    description: 'Healthcare Platform API Gateway',
    endpoints: Object.keys(serviceRoutes),
    documentation: '/api-docs'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found',
    path: req.originalUrl
  });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  logger.info(`API Gateway running on port ${PORT}`);
  logger.info(`Health check: http://localhost:${PORT}/health`);
  logger.info(`API documentation: http://localhost:${PORT}/api-docs`);
  logger.info(`Metrics: http://localhost:${PORT}/metrics`);
});

module.exports = app; 