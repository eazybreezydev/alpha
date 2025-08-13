const express = require('express');
const axios = require('axios');
const { getUserToken } = require('./auth');
const router = express.Router();

// Device control endpoints for AC units

/**
 * Get user's connected devices
 * GET /devices?userId=123&provider=smartthings
 */
router.get('/', async (req, res) => {
  const { userId, provider = 'smartthings' } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const accessToken = getUserToken(userId, provider);
  if (!accessToken) {
    return res.status(401).json({ 
      error: 'User not connected to provider or token expired',
      provider,
      needsAuth: true
    });
  }

  try {
    let devices = [];
    
    if (provider === 'smartthings') {
      // Get SmartThings devices
      const response = await axios.get('https://api.smartthings.com/v1/devices', {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Accept': 'application/json'
        }
      });

      // Filter for AC/thermostat devices
      devices = response.data.items
        .filter(device => 
          device.components?.main?.capabilities?.some(cap => 
            ['airConditionerMode', 'thermostatMode', 'airConditionerFanMode'].includes(cap)
          )
        )
        .map(device => ({
          id: device.deviceId,
          name: device.label || device.name,
          type: 'air_conditioner',
          provider: 'smartthings',
          capabilities: device.components?.main?.capabilities || [],
          status: 'unknown'
        }));
    }

    res.json({
      success: true,
      devices,
      provider,
      count: devices.length
    });

  } catch (error) {
    console.error(`Failed to get devices for ${provider}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to retrieve devices',
      provider,
      details: error.response?.data || error.message
    });
  }
});

/**
 * Get specific device status
 * GET /devices/:deviceId/status?userId=123&provider=smartthings
 */
router.get('/:deviceId/status', async (req, res) => {
  const { deviceId } = req.params;
  const { userId, provider = 'smartthings' } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const accessToken = getUserToken(userId, provider);
  if (!accessToken) {
    return res.status(401).json({ 
      error: 'User not connected to provider or token expired',
      provider,
      needsAuth: true
    });
  }

  try {
    let deviceStatus = {};

    if (provider === 'smartthings') {
      const response = await axios.get(`https://api.smartthings.com/v1/devices/${deviceId}/status`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Accept': 'application/json'
        }
      });

      const status = response.data.components?.main || {};
      deviceStatus = {
        deviceId,
        provider,
        airConditionerMode: status.airConditionerMode?.value || 'unknown',
        thermostatMode: status.thermostatMode?.value || 'unknown',
        temperature: status.temperature?.value || null,
        fanMode: status.airConditionerFanMode?.value || status.thermostatFanMode?.value || 'unknown',
        power: status.switch?.value || 'unknown',
        lastUpdated: new Date().toISOString()
      };
    }

    res.json({
      success: true,
      deviceStatus,
      provider
    });

  } catch (error) {
    console.error(`Failed to get device status for ${deviceId}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to get device status',
      deviceId,
      provider,
      details: error.response?.data || error.message
    });
  }
});

/**
 * Control AC device - Turn On
 * POST /devices/:deviceId/turn-on
 * Body: { userId, provider?, temperature?, fanMode? }
 */
router.post('/:deviceId/turn-on', async (req, res) => {
  const { deviceId } = req.params;
  const { userId, provider = 'smartthings', temperature = 22, fanMode = 'auto' } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const accessToken = getUserToken(userId, provider);
  if (!accessToken) {
    return res.status(401).json({ 
      error: 'User not connected to provider or token expired',
      provider,
      needsAuth: true
    });
  }

  try {
    let result = {};

    if (provider === 'smartthings') {
      // Turn on AC with cooling mode
      const commands = [
        {
          component: 'main',
          capability: 'switch',
          command: 'on'
        },
        {
          component: 'main',
          capability: 'airConditionerMode',
          command: 'setAirConditionerMode',
          arguments: ['cool']
        },
        {
          component: 'main',
          capability: 'thermostatCoolingSetpoint',
          command: 'setCoolingSetpoint',
          arguments: [temperature]
        }
      ];

      if (fanMode) {
        commands.push({
          component: 'main',
          capability: 'airConditionerFanMode',
          command: 'setAirConditionerFanMode',
          arguments: [fanMode]
        });
      }

      const response = await axios.post(
        `https://api.smartthings.com/v1/devices/${deviceId}/commands`,
        { commands },
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      result = {
        success: true,
        action: 'turn_on',
        deviceId,
        provider,
        settings: {
          mode: 'cool',
          temperature,
          fanMode,
          power: 'on'
        },
        timestamp: new Date().toISOString(),
        commandResponse: response.data
      };
    }

    console.log(`AC turned ON for device ${deviceId} by user ${userId}`);
    res.json(result);

  } catch (error) {
    console.error(`Failed to turn on AC ${deviceId}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to turn on AC',
      deviceId,
      provider,
      details: error.response?.data || error.message
    });
  }
});

/**
 * Control AC device - Turn Off
 * POST /devices/:deviceId/turn-off
 * Body: { userId, provider? }
 */
router.post('/:deviceId/turn-off', async (req, res) => {
  const { deviceId } = req.params;
  const { userId, provider = 'smartthings' } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const accessToken = getUserToken(userId, provider);
  if (!accessToken) {
    return res.status(401).json({ 
      error: 'User not connected to provider or token expired',
      provider,
      needsAuth: true
    });
  }

  try {
    let result = {};

    if (provider === 'smartthings') {
      // Turn off AC
      const commands = [
        {
          component: 'main',
          capability: 'switch',
          command: 'off'
        }
      ];

      const response = await axios.post(
        `https://api.smartthings.com/v1/devices/${deviceId}/commands`,
        { commands },
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      result = {
        success: true,
        action: 'turn_off',
        deviceId,
        provider,
        settings: {
          power: 'off'
        },
        timestamp: new Date().toISOString(),
        commandResponse: response.data
      };
    }

    console.log(`AC turned OFF for device ${deviceId} by user ${userId}`);
    res.json(result);

  } catch (error) {
    console.error(`Failed to turn off AC ${deviceId}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to turn off AC',
      deviceId,
      provider,
      details: error.response?.data || error.message
    });
  }
});

/**
 * Set AC temperature
 * POST /devices/:deviceId/temperature
 * Body: { userId, temperature, provider? }
 */
router.post('/:deviceId/temperature', async (req, res) => {
  const { deviceId } = req.params;
  const { userId, temperature, provider = 'smartthings' } = req.body;

  if (!userId || temperature === undefined) {
    return res.status(400).json({ error: 'userId and temperature are required' });
  }

  const accessToken = getUserToken(userId, provider);
  if (!accessToken) {
    return res.status(401).json({ 
      error: 'User not connected to provider or token expired',
      provider,
      needsAuth: true
    });
  }

  try {
    let result = {};

    if (provider === 'smartthings') {
      const commands = [
        {
          component: 'main',
          capability: 'thermostatCoolingSetpoint',
          command: 'setCoolingSetpoint',
          arguments: [temperature]
        }
      ];

      const response = await axios.post(
        `https://api.smartthings.com/v1/devices/${deviceId}/commands`,
        { commands },
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      result = {
        success: true,
        action: 'set_temperature',
        deviceId,
        provider,
        settings: {
          temperature
        },
        timestamp: new Date().toISOString(),
        commandResponse: response.data
      };
    }

    console.log(`AC temperature set to ${temperature}°C for device ${deviceId} by user ${userId}`);
    res.json(result);

  } catch (error) {
    console.error(`Failed to set temperature for AC ${deviceId}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to set AC temperature',
      deviceId,
      provider,
      details: error.response?.data || error.message
    });
  }
});

module.exports = router;
