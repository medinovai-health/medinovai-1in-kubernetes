const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Service URLs
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-management:5001';
const MEDICATION_SERVICE_URL = process.env.MEDICATION_SERVICE_URL || 'http://medication-management:5002';
const CLINICAL_SERVICE_URL = process.env.CLINICAL_SERVICE_URL || 'http://clinical-decision-support:5003';
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://ai-model-service:5005';

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString()
  });
});

// User Management Routes
app.use('/api/users', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${USER_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: req.headers,
      params: req.query
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: error.response?.data?.error || 'User service error'
    });
  }
});

// Medication Management Routes
app.use('/api/medications', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${MEDICATION_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: req.headers,
      params: req.query
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: error.response?.data?.error || 'Medication service error'
    });
  }
});

// Clinical Decision Support Routes
app.use('/api/clinical', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${CLINICAL_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: req.headers,
      params: req.query
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: error.response?.data?.error || 'Clinical service error'
    });
  }
});

// AI Model Service Routes
app.use('/api/ai', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${AI_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: req.headers,
      params: req.query
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: error.response?.data?.error || 'AI service error'
    });
  }
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'MedinovaIOS Healthcare Platform API Gateway',
    version: '1.0.0',
    services: {
      users: '/api/users',
      medications: '/api/medications',
      clinical: '/api/clinical',
      ai: '/api/ai'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found'
  });
});

app.listen(PORT, () => {
  // console.log(`API Gateway running on port ${PORT}`);
  // console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
}); 