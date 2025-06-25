# EasyBreezy: Window Opening Recommendations App

EasyBreezy helps homeowners reduce air conditioning use by notifying them when it's ideal to open windows based on real-time weather data and wind direction.

## Features

- **Smart Window Recommendations**: Get personalized suggestions for when to open or close windows based on your home's orientation
- **Real-time Weather Data**: Access current temperature, humidity, wind speed and direction
- **Home Configuration**: Customize settings based on your home's orientation and window locations
- **Cross-Ventilation Intelligence**: Optimizes airflow by recommending which specific windows to open
- **Energy Savings**: Reduce AC usage and lower energy bills while enjoying fresh air
- **Intelligent Notifications**: Receive timely alerts about optimal window opening conditions

## App Structure

```
easybreezy/
├── lib/
│   ├── api/
│   │   └── weather_service.dart      # OpenWeatherMap API integration
│   ├── models/
│   │   ├── home_config.dart          # Home orientation and window configuration
│   │   └── weather_data.dart         # Weather data model
│   ├── providers/
│   │   ├── home_provider.dart        # Home configuration state management
│   │   └── weather_provider.dart     # Weather data state management
│   ├── screens/
│   │   ├── home_screen.dart          # Main screen with recommendations
│   │   ├── onboarding_screen.dart    # Initial setup screens
│   │   └── settings_screen.dart      # User preferences
│   ├── utils/
│   │   ├── notification_service.dart # Local notifications
│   │   └── recommendation_engine.dart # Window opening algorithm
│   ├── widgets/
│   │   ├── recommendation_card.dart  # Window recommendation display
│   │   └── weather_display.dart      # Weather information UI
│   └── main.dart                     # Application entry point
└── pubspec.yaml                      # Dependencies
```

## Installation

1. Make sure you have Flutter installed on your development machine
2. Clone this repository
3. Navigate to the project directory and run:

```bash
flutter pub get
```

4. Open the `lib/api/weather_service.dart` file and replace the placeholder API key with your OpenWeatherMap API key
5. Connect a device or start an emulator and run:

```bash
flutter run
```

## Usage

1. **First Launch**: When you first launch the app, you'll be guided through an onboarding process to configure your home orientation and window positions

2. **Home Screen**: The main screen displays:
   - Current weather conditions
   - A recommendation card suggesting whether to open windows
   - Which specific windows to open for optimal cross-ventilation
   - Hourly forecast
   - Your current home configuration

3. **Settings**: Access the settings screen to update your home configuration:
   - Change home orientation
   - Update window positions
   - Adjust comfort temperature range
   - Enable/disable notifications

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
