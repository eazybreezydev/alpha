// API Keys Configuration
// This file contains API keys for external services
// Note: Using existing API keys from the app

class ApiKeys {
  // Google Places API Key for location search and geocoding
  // This key is already being used in the onboarding screen
  static const String kGoogleApiKey = 'AIzaSyBmZfcpnFKGRr2uzcL3ayXxUN-_fX6fy7s';
  
  // OpenWeatherMap API Key for weather data
  // Get your key from: https://openweathermap.org/api
  static const String kOpenWeatherMapApiKey = 'ada0f2af67b3dd1d9824bb6e33750983';
}

// For backwards compatibility, expose the Google API key directly
const String kGoogleApiKey = ApiKeys.kGoogleApiKey;
