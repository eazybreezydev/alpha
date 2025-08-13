const express = require('express');
const crypto = require('crypto');
const axios = require('axios');
const router = express.Router();

// In-memory storage for OAuth states and tokens (use database in production)
const oauthStates = new Map();
const userTokens = new Map();

// OAuth2 configurations
const OAUTH_CONFIGS = {
  smartthings: {
    authUrl: 'https://account.smartthings.com/oauth/authorize',
    tokenUrl: 'https://auth-global.api.smartthings.com/oauth/token',
    clientId: process.env.SMARTTHINGS_CLIENT_ID,
    clientSecret: process.env.SMARTTHINGS_CLIENT_SECRET,
    scope: 'r:devices:* w:devices:*',
    redirectUri: `${process.env.BASE_URL}/auth/smartthings/callback`
  },
  googlehome: {
    authUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenUrl: 'https://oauth2.googleapis.com/token',
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    scope: 'https://www.googleapis.com/auth/homegraph',
    redirectUri: `${process.env.BASE_URL}/auth/googlehome/callback`
  }
};

/**
 * Start OAuth2 flow for specified provider
 * GET /auth/:provider/start?userId=123
 */
router.get('/:provider/start', (req, res) => {
  const { provider } = req.params;
  const { userId } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const config = OAUTH_CONFIGS[provider];
  if (!config) {
    return res.status(400).json({ error: 'Invalid provider. Supported: smartthings, googlehome' });
  }

  if (!config.clientId || !config.clientSecret) {
    return res.status(500).json({ error: `${provider} OAuth credentials not configured` });
  }

  // Generate unique state parameter for security
  const state = crypto.randomBytes(32).toString('hex');
  oauthStates.set(state, { provider, userId, timestamp: Date.now() });

  // Clean up old states (older than 10 minutes)
  for (const [key, value] of oauthStates.entries()) {
    if (Date.now() - value.timestamp > 10 * 60 * 1000) {
      oauthStates.delete(key);
    }
  }

  // Build authorization URL
  const authUrl = new URL(config.authUrl);
  authUrl.searchParams.set('client_id', config.clientId);
  authUrl.searchParams.set('redirect_uri', config.redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', config.scope);
  authUrl.searchParams.set('state', state);

  console.log(`Starting OAuth flow for ${provider} with user ${userId}`);
  res.json({
    success: true,
    authUrl: authUrl.toString(),
    state,
    provider
  });
});

/**
 * OAuth2 callback to exchange code for tokens
 * GET /auth/:provider/callback?code=xxx&state=xxx
 */
router.get('/:provider/callback', async (req, res) => {
  const { provider } = req.params;
  const { code, state, error } = req.query;

  // Check for OAuth errors
  if (error) {
    console.error(`OAuth error for ${provider}:`, error);
    return res.status(400).json({ error: `OAuth error: ${error}` });
  }

  if (!code || !state) {
    return res.status(400).json({ error: 'Missing authorization code or state parameter' });
  }

  // Validate state parameter
  const stateData = oauthStates.get(state);
  if (!stateData || stateData.provider !== provider) {
    return res.status(400).json({ error: 'Invalid or expired state parameter' });
  }

  const config = OAUTH_CONFIGS[provider];
  const { userId } = stateData;

  try {
    // Exchange authorization code for access token
    const tokenResponse = await axios.post(config.tokenUrl, {
      grant_type: 'authorization_code',
      client_id: config.clientId,
      client_secret: config.clientSecret,
      code,
      redirect_uri: config.redirectUri
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    const tokens = tokenResponse.data;
    
    // Store tokens for the user
    const userKey = `${userId}-${provider}`;
    userTokens.set(userKey, {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt: Date.now() + (tokens.expires_in * 1000),
      provider,
      userId,
      createdAt: Date.now()
    });

    // Clean up state
    oauthStates.delete(state);

    console.log(`Successfully stored ${provider} tokens for user ${userId}`);

    // Return success page or redirect to app
    res.send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2>✅ Successfully Connected!</h2>
          <p>Your ${provider === 'smartthings' ? 'SmartThings' : 'Google Home'} account has been connected.</p>
          <p>You can now close this window and return to the Easy Breezy app.</p>
          <script>
            // Auto-close window after 3 seconds
            setTimeout(() => {
              window.close();
            }, 3000);
          </script>
        </body>
      </html>
    `);

  } catch (error) {
    console.error(`Token exchange failed for ${provider}:`, error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Failed to exchange authorization code for tokens',
      details: error.response?.data?.error_description || error.message
    });
  }
});

/**
 * Check if user has connected a specific provider
 * GET /auth/:provider/status?userId=123
 */
router.get('/:provider/status', (req, res) => {
  const { provider } = req.params;
  const { userId } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const userKey = `${userId}-${provider}`;
  const tokens = userTokens.get(userKey);

  if (!tokens) {
    return res.json({ connected: false, provider });
  }

  // Check if token is expired
  const isExpired = Date.now() > tokens.expiresAt;
  
  res.json({
    connected: !isExpired,
    provider,
    connectedAt: tokens.createdAt,
    expiresAt: tokens.expiresAt,
    needsRefresh: isExpired
  });
});

/**
 * Disconnect a provider for a user
 * DELETE /auth/:provider/disconnect?userId=123
 */
router.delete('/:provider/disconnect', (req, res) => {
  const { provider } = req.params;
  const { userId } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  const userKey = `${userId}-${provider}`;
  const wasConnected = userTokens.has(userKey);
  
  userTokens.delete(userKey);

  console.log(`Disconnected ${provider} for user ${userId}`);
  
  res.json({
    success: true,
    message: `${provider} disconnected successfully`,
    wasConnected
  });
});

/**
 * Get user's access token (internal use)
 */
function getUserToken(userId, provider) {
  const userKey = `${userId}-${provider}`;
  const tokens = userTokens.get(userKey);
  
  if (!tokens) {
    return null;
  }

  // Check if token is expired
  if (Date.now() > tokens.expiresAt) {
    // TODO: Implement token refresh logic
    console.warn(`Token expired for user ${userId} provider ${provider}`);
    return null;
  }

  return tokens.accessToken;
}

module.exports = { router, getUserToken };
