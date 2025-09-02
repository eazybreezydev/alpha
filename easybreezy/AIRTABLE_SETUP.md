# Airtable Integration Setup Guide

## Overview
Your Easy Breezy app now includes Airtable integration for dynamic Local Ads management. This allows you to manage ads through your Airtable interface and have them automatically appear in your app.

## Required Airtable Setup

### 1. Get Your Airtable Credentials
You'll need to update the following constants in `/lib/services/airtable_service.dart`:

```dart
static const String _baseId = 'YOUR_BASE_ID'; // Replace with your actual Base ID
static const String _personalAccessToken = 'YOUR_PERSONAL_ACCESS_TOKEN'; // Replace with your Personal Access Token
```

### 2. Finding Your Base ID
1. Go to https://airtable.com/api
2. Select your "Local Ads" base
3. The Base ID will be shown at the top (starts with "app...")

### 3. Creating Your Personal Access Token
1. Go to https://airtable.com/create/tokens
2. Click "Create new token"
3. Give it a name like "Easy Breezy App"
4. Add these scopes:
   - `data.records:read` (to read ad records)
   - `data.records:write` (optional, for tracking interactions)
5. Add your "Local Ads" base to the token
6. Generate the token and copy it

> **Note**: Personal Access Tokens are the modern way to authenticate with Airtable. API keys are being deprecated, so we're using tokens for future compatibility.

### 4. Verify Your Table Structure
Make sure your Airtable "Local Ads" table has these exact field names:
- **Headline** (Single line text)
- **Description** (Long text)
- **Status** (Single select: Active, Inactive)
- **URL** (URL field - optional)
- **Attachments** (Attachment field - for images)
- **Province/State** (Single line text)
- **City/Town** (Single line text)

## Features

### Location-Based Ad Targeting
- App automatically detects user's location
- Shows ads for their city first
- Falls back to province/state ads if no city-specific ads
- Shows all active ads if no location-specific ads found

### Auto-Rotation
- Ads rotate every 30 seconds automatically
- Users can manually navigate with previous/next buttons
- Dot indicators show current ad position

### Image Support
- Displays first image from Attachments field
- Graceful fallback if image fails to load
- 16:9 aspect ratio for consistent layout

### Click Tracking
- Tracks when users click on ads (optional)
- Opens URLs in external browser
- Error handling for invalid URLs

## Testing Your Setup

1. **Update credentials** in `airtable_service.dart`
2. **Add test data** to your Airtable:
   ```
   Headline: "Test Local Business"
   Description: "This is a test ad to verify integration"
   Status: "Active"
   URL: "https://example.com"
   Province/State: "Ontario"
   City/Town: "Toronto"
   ```
3. **Run the app** and check the Home screen
4. **Location permission** will be requested for targeted ads

## Security Notes

⚠️ **Important**: Never commit your actual Personal Access Token to version control!

Consider using environment variables or a config file that's excluded from git:

```dart
// Create a file: lib/config/airtable_config.dart
class AirtableConfig {
  static const String baseId = String.fromEnvironment('AIRTABLE_BASE_ID', defaultValue: 'YOUR_BASE_ID');
  static const String personalAccessToken = String.fromEnvironment('AIRTABLE_PERSONAL_ACCESS_TOKEN', defaultValue: 'YOUR_PERSONAL_ACCESS_TOKEN');
}
```

## Troubleshooting

### No Ads Showing
1. Check that Status field is set to "Active"
2. Verify your Base ID and Personal Access Token are correct
3. Check console logs for error messages
4. Ensure location permissions are granted

### Images Not Loading
1. Verify images are properly uploaded to Attachments field
2. Check image URLs are publicly accessible
3. Try with different image formats (PNG, JPG)

### Location Issues
1. Make sure location permissions are granted
2. Test on physical device (simulator may have location issues)
3. Check that Province/State and City/Town match exactly

## Next Steps

Once basic integration is working, you can:
1. Add interaction tracking fields to measure ad performance
2. Implement A/B testing with different ad variations  
3. Add more targeting fields (age, interests, etc.)
4. Create different ad types for different app sections
