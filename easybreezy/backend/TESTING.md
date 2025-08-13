# OAuth2 Flow Testing Guide for Easy Breezy

## Overview
This guide demonstrates how to test the OAuth2 login flow for Google Home and SmartThings integration in the Easy Breezy app.

## Prerequisites
1. Backend server running on `http://localhost:3000`
2. Flutter app compiled and running
3. OAuth credentials configured in `.env` file

## Testing OAuth Flow

### 1. Start Backend Server
```bash
cd backend
npm start
```
Expected output:
```
🚀 Easy Breezy Backend running on port 3000
📱 Frontend URL: http://localhost:8080
🔒 Environment: development
🌐 Health check: http://localhost:3000/health
```

### 2. Test Backend Endpoints

#### Health Check
```bash
curl http://localhost:3000/health
```
Expected response:
```json
{"status":"OK","timestamp":"2025-08-11T01:29:21.951Z","environment":"development"}
```

#### API Documentation
```bash
curl http://localhost:3000/api
```
This returns the full API documentation with all available endpoints.

#### Start OAuth Flow (Test)
```bash
curl "http://localhost:3000/auth/smartthings/start?userId=test123"
```
Expected response:
```json
{
  "success": true,
  "authUrl": "https://account.smartthings.com/oauth/authorize?client_id=your_smartthings_client_id_here&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauth%2Fsmartthings%2Fcallback&response_type=code&scope=r%3Adevices%3A*+w%3Adevices%3A*&state=88fa974d98e12b2ac21ce7f90ff7f95921812e2f7fae8d3ff02a95cd955cf05d",
  "state": "88fa974d98e12b2ac21ce7f90ff7f95921812e2f7fae8d3ff02a95cd955cf05d",
  "provider": "smartthings"
}
```

### 3. Flutter App Integration

#### Connect AC Flow
1. Open Easy Breezy app
2. Navigate to Pro Info screen (bottom navigation)
3. Tap "Connect My AC" button
4. Select a provider (SmartThings or Google Home)
5. App will redirect to OAuth provider's login page
6. Complete authentication and grant permissions
7. Return to app and check connection status

#### AC Control Flow
1. Ensure provider is connected
2. Navigate to Home dashboard
3. Look for recommendation card with weather conditions
4. When temperature is hot (>26°C/79°F): "Turn on AC" button appears (red)
5. When conditions are good for open windows: "Turn off AC" button appears (green)
6. Tap button to control AC
7. App shows loading indicator and success/error message

## Expected User Flow

### First Time Setup
1. User taps "Connect My AC" in app settings
2. User selects provider: SmartThings or Google Home
3. User goes through OAuth2 login flow to grant permissions
4. App stores connection status and loads available devices

### Daily Usage
1. User opens Easy Breezy app
2. Home dashboard shows current weather and recommendations
3. When AC control is recommended:
   - User sees "Turn on AC" (red) or "Turn off AC" (green) button
   - User taps button
   - App triggers backend API to control AC
   - UI updates instantly with confirmation message

## Backend API Endpoints

### Authentication
- `GET /auth/:provider/start?userId=123` - Start OAuth flow
- `GET /auth/:provider/callback` - OAuth callback (handled by browser)
- `GET /auth/:provider/status?userId=123` - Check connection status
- `DELETE /auth/:provider/disconnect?userId=123` - Disconnect provider

### Device Control
- `GET /api/devices?userId=123&provider=smartthings` - Get user devices
- `POST /api/devices/:deviceId/turn-on` - Turn on AC
- `POST /api/devices/:deviceId/turn-off` - Turn off AC
- `POST /api/devices/:deviceId/temperature` - Set AC temperature

### User Management
- `GET /api/users/:userId` - Get user profile
- `PUT /api/users/:userId/preferences` - Update preferences

## OAuth Provider Setup (Required for Testing)

### SmartThings
1. Visit https://developer.smartthings.com/
2. Create a new app
3. Configure OAuth redirect URI: `http://localhost:3000/auth/smartthings/callback`
4. Note down Client ID and Client Secret
5. Update `.env` file

### Google Home
1. Visit https://console.developers.google.com/
2. Create a new project
3. Enable Google Home Graph API
4. Create OAuth 2.0 credentials
5. Configure redirect URI: `http://localhost:3000/auth/googlehome/callback`
6. Update `.env` file

## Environment Variables

Update `backend/.env` with your OAuth credentials:

```env
# SmartThings OAuth2 Configuration
SMARTTHINGS_CLIENT_ID=your_actual_client_id
SMARTTHINGS_CLIENT_SECRET=your_actual_client_secret

# Google OAuth2 Configuration  
GOOGLE_CLIENT_ID=your_actual_client_id
GOOGLE_CLIENT_SECRET=your_actual_client_secret
```

## Testing Without Real OAuth Credentials

For demo purposes, you can:
1. Use the mock endpoints to see the OAuth flow structure
2. Test the Flutter UI components and provider state management
3. Verify API endpoint responses with placeholder credentials

## Troubleshooting

### Common Issues
1. **Backend not starting**: Check if Node.js is installed (`node --version`)
2. **OAuth errors**: Verify client credentials in `.env` file
3. **CORS errors**: Ensure `FRONTEND_URL` matches your Flutter app's origin
4. **Device not found**: Check if provider is properly connected and devices are available

### Debug Mode
Enable debug logging by setting `NODE_ENV=development` in your `.env` file.

## Security Notes

⚠️ **Important for Production**:
- Use HTTPS for all OAuth redirects
- Store tokens securely in a database (not in-memory)
- Implement token refresh logic
- Add proper error handling and logging
- Use environment-specific redirect URIs
- Add rate limiting and authentication middleware

## Success Criteria

✅ OAuth flow completes successfully
✅ Tokens are stored and retrieved correctly  
✅ Device control API responds appropriately
✅ Flutter app shows proper UI feedback
✅ Error handling works for failed operations
