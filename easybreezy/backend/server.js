const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { router: authRoutes } = require('./routes/auth');
const deviceRoutes = require('./routes/devices');
const userRoutes = require('./routes/users');

const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

// Middleware
app.use(limiter);
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:8080',
  credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV 
  });
});

// API info endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Easy Breezy API',
    version: '1.0.0',
    description: 'OAuth2 and device control API for Easy Breezy smart home app',
    endpoints: {
      auth: {
        'GET /auth/:provider/start': 'Start OAuth flow (providers: smartthings, googlehome)',
        'GET /auth/:provider/callback': 'OAuth callback',
        'GET /auth/:provider/status': 'Check connection status',
        'DELETE /auth/:provider/disconnect': 'Disconnect provider'
      },
      devices: {
        'GET /api/devices': 'Get user devices',
        'GET /api/devices/:id/status': 'Get device status',
        'POST /api/devices/:id/turn-on': 'Turn on AC',
        'POST /api/devices/:id/turn-off': 'Turn off AC',
        'POST /api/devices/:id/temperature': 'Set AC temperature'
      },
      users: {
        'GET /api/users/:id': 'Get user profile',
        'PUT /api/users/:id/preferences': 'Update preferences',
        'GET /api/users/:id/devices': 'Get devices summary'
      }
    },
    usage: {
      baseUrl: `http://localhost:${PORT}`,
      authFlow: 'Start at /auth/:provider/start?userId=123',
      deviceControl: 'Requires OAuth token from connected provider'
    }
  });
});

// Routes
app.use('/auth', authRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/users', userRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Easy Breezy Backend running on port ${PORT}`);
  console.log(`📱 Frontend URL: ${process.env.FRONTEND_URL}`);
  console.log(`🔒 Environment: ${process.env.NODE_ENV}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
