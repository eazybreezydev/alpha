# EasyBreezy 🌬️

**Smart Window Management for Energy-Efficient Homes**

EasyBreezy is a private Flutter mobile application that helps homeowners reduce air conditioning costs by intelligently recommending when to open or close windows based on real-time weather conditions, air quality, and personal preferences.

> **Note**: This is a private application developed for personal use and demonstration purposes.

## 📱 Features

- **Smart Window Recommendations**: Get personalized suggestions on when to open or close windows
- **Real-time Weather Data**: Access current temperature, wind speed, direction, and weather conditions
- **Air Quality Monitoring**: Track AQI (Air Quality Index) and pollen levels
- **Location-based Services**: Automatic location detection with manual address override
- **Home Configuration**: Customize settings based on your home's orientation and window locations
- **Cross-Ventilation Intelligence**: Optimizes airflow by recommending which specific windows to open
- **Energy Savings**: Reduce AC usage and lower energy bills while enjoying fresh air
- **Smart Notifications**: Get alerts for optimal window opening/closing times
- **Beautiful UI**: Modern design with day-themed background and intuitive navigation
- **Temperature Units**: Support for both Celsius and Fahrenheit
- **Smart Tips**: Rotating energy-saving tips and recommendations

## 🛠️ Tech Stack

- **Framework**: Flutter (>=2.19.0 <3.0.0)
- **Language**: Dart
- **State Management**: Provider
- **APIs**: 
  - Weather data integration
  - Google Places API for location services
- **Local Storage**: SharedPreferences
- **Notifications**: Flutter Local Notifications
- **Location Services**: Geolocator, Geocoding
- **HTTP Requests**: HTTP package
- **UI Components**: Flutter Neumorphic, Compass widget

## 📁 App Structure

```
easybreezy/
├── lib/
│   ├── api/
│   │   └── weather_service.dart         # Weather API integration
│   ├── models/
│   │   ├── home_config.dart             # Home orientation and window configuration
│   │   └── weather_data.dart            # Weather data model
│   ├── providers/
│   │   ├── home_provider.dart           # Home configuration state management
│   │   └── weather_provider.dart        # Weather data and theme management
│   ├── screens/
│   │   ├── home_screen.dart             # Main screen entry point
│   │   ├── main_shell.dart              # Navigation shell with floating menu
│   │   ├── onboarding_screen.dart       # Initial setup screens
│   │   ├── settings_screen.dart         # User preferences and configuration
│   │   ├── smart_view_screen.dart       # Advanced analytics view
│   │   └── pro_info_screen.dart         # Pro features information
│   ├── widgets/
│   │   ├── home_dashboard.dart          # Main dashboard UI with weather display
│   │   ├── floating_menu_bar.dart       # Bottom navigation bar
│   │   ├── smart_tips_card.dart         # Rotating tips display
│   │   ├── local_ads_banner.dart        # Local service advertisements
│   │   ├── recommendation_card.dart     # Window recommendation display
│   │   ├── weather_display.dart         # Weather information UI
│   │   └── wind_orientation_widget.dart # Wind direction compass
│   ├── utils/
│   │   ├── notification_service.dart    # Local push notifications
│   │   └── recommendation_engine.dart   # Window opening algorithm
│   └── main.dart                        # Application entry point
├── assets/
│   ├── images/
│   │   ├── backgrounds/
│   │   │   └── dayv2.png               # Main background image
│   │   ├── house_windowsopened.png     # House with open windows
│   │   ├── house_windowsclosed.png     # House with closed windows
│   │   ├── housev2.png                 # Alternative house image
│   │   └── window-installers-placehold.jpg # Ad placeholder
│   └── fonts/
│       ├── Poppins-Regular.ttf         # Main app font
│       ├── Poppins-Bold.ttf            # Bold font variant
│       └── Poppins-Medium.ttf          # Medium font variant
└── pubspec.yaml                        # Dependencies and assets
```

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK (>=2.19.0 <3.0.0)
- Dart SDK
- Android Studio / Xcode for mobile development
- Google API key for location services

### Getting Started

1. **Clone the repository**
   ```bash
   # Note: This is a private repository
   git clone https://github.com/yourusername/easybreezy-app.git
   cd easybreezy-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Open `lib/screens/settings_screen.dart`
   - Replace the placeholder Google API key:
   ```dart
   static const String kGoogleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

> **Important**: This application requires valid API keys for weather data and location services. Contact the repository owner for setup assistance.

## 📱 Usage

### First Launch
When you first launch EasyBreezy, you'll go through an onboarding process:
1. **Welcome Screen**: Introduction to the app's features
2. **Home Orientation**: Select which direction your home faces (North, South, East, West)
3. **Window Configuration**: Choose which directions have windows in your home

### Main Dashboard
The home screen displays:
- **Location & Time**: Current location with live timestamp
- **Smart Recommendations**: Personalized window opening/closing suggestions
- **House Visualization**: Dynamic house image showing optimal window state
- **Wind Direction**: Compass showing current wind direction
- **Local Services**: Information about window installation services
- **Smart Tips**: Rotating energy-saving tips and advice

### Settings & Configuration
Access comprehensive settings to:
- **Update Home Orientation**: Change your home's facing direction
- **Configure Windows**: Modify which directions have windows
- **Set Comfort Range**: Adjust preferred temperature range
- **Location Settings**: Update address with autocomplete
- **Temperature Units**: Switch between Celsius and Fahrenheit
- **Notifications**: Enable/disable smart alerts

### Smart Features
- **Weather Integration**: Real-time weather data for your location
- **AQI Monitoring**: Air quality tracking for health considerations
- **Pollen Alerts**: Recommendations during high pollen periods
- **Wind Analysis**: Optimal window combinations for cross-ventilation
- **Energy Tips**: Personalized advice for reducing energy consumption

## 🎨 UI/UX Features

- **Modern Design**: Clean interface with soft black text on white cards
- **Day-themed Background**: Beautiful dayv2.png background across all screens
- **Responsive Layout**: Optimized for various screen sizes and orientations
- **Animated Elements**: Wind direction indicators and smooth transitions
- **Floating Navigation**: Bottom floating menu bar for easy access
- **High Contrast**: Accessibility-focused color scheme for readability

## 🔧 Configuration & Permissions

### Android Permissions (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Permissions (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>EasyBreezy needs location access to provide weather-based window recommendations for your area.</string>
```

## 🔮 Future Enhancements

- [ ] Weather forecast integration (7-day outlook)
- [ ] Smart home integration (IoT window controls)
- [ ] Machine learning for personalized recommendations
- [ ] Social features (community energy saving challenges)
- [ ] Advanced analytics and energy savings tracking
- [ ] Multiple home support
- [ ] Integration with smart thermostats
- [ ] Historical data and trends
- [ ] Seasonal optimization algorithms

## 🤝 Development & Collaboration

This is a private project developed for personal use and portfolio demonstration.

### Development Guidelines
- This application is not intended for public distribution
- Code is maintained for personal learning and development purposes
- API keys and sensitive configurations are not included in the repository

### Project Status
- ✅ Core functionality implemented
- ✅ UI/UX design completed
- ✅ Weather integration working
- 🔄 Ongoing personal improvements and optimizations

For questions about the implementation or technical details, please contact the repository owner.

## 📄 License

This project is developed for private use and educational purposes. All rights reserved.

## 🙏 Acknowledgments

- Weather data integration capabilities
- Google Places API for location services
- Flutter community for UI inspiration and components
- Personal learning and development journey

## 📞 Contact

This is a private project developed for personal use and portfolio demonstration.

For technical inquiries or collaboration discussions, please contact the repository owner directly.

---

**Developed for personal use and learning** 

*EasyBreezy - Smart windows, smarter savings.*
