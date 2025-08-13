class HomeConfig {
  final HomeOrientation orientation;
  final Map<WindowDirection, bool> windows;
  final double comfortTempMin;
  final double comfortTempMax;
  final bool notificationsEnabled;
  final String? address; // Add address field
  final double? latitude; // Add latitude
  final double? longitude; // Add longitude

  HomeConfig({
    required this.orientation,
    required this.windows,
    this.comfortTempMin = 65.0, // Default lower comfort threshold in Fahrenheit
    this.comfortTempMax = 78.0, // Default upper comfort threshold in Fahrenheit
    this.notificationsEnabled = true,
    this.address,
    this.latitude,
    this.longitude,
  });

  // Factory constructor to create a default home configuration
  factory HomeConfig.defaultConfig() {
    return HomeConfig(
      orientation: HomeOrientation.north,
      windows: {
        WindowDirection.north: false,
        WindowDirection.east: false,
        WindowDirection.south: false,
        WindowDirection.west: false,
      },
      address: '',
      latitude: null,
      longitude: null,
    );
  }

  // Create a copy with updated fields
  HomeConfig copyWith({
    HomeOrientation? orientation,
    Map<WindowDirection, bool>? windows,
    double? comfortTempMin,
    double? comfortTempMax,
    bool? notificationsEnabled,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return HomeConfig(
      orientation: orientation ?? this.orientation,
      windows: windows ?? this.windows,
      comfortTempMin: comfortTempMin ?? this.comfortTempMin,
      comfortTempMax: comfortTempMax ?? this.comfortTempMax,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Convert HomeConfig to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'orientation': orientation.index,
      'windows': {
        'north': windows[WindowDirection.north],
        'east': windows[WindowDirection.east],
        'south': windows[WindowDirection.south],
        'west': windows[WindowDirection.west],
      },
      'comfortTempMin': comfortTempMin,
      'comfortTempMax': comfortTempMax,
      'notificationsEnabled': notificationsEnabled,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create HomeConfig from JSON
  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    return HomeConfig(
      orientation: HomeOrientation.values[json['orientation'] as int],
      windows: {
        WindowDirection.north: json['windows']['north'] as bool,
        WindowDirection.east: json['windows']['east'] as bool,
        WindowDirection.south: json['windows']['south'] as bool,
        WindowDirection.west: json['windows']['west'] as bool,
      },
      comfortTempMin: (json['comfortTempMin'] as num).toDouble(),
      comfortTempMax: (json['comfortTempMax'] as num).toDouble(),
      notificationsEnabled: json['notificationsEnabled'] as bool,
      address: json['address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  // Check if a particular window direction exists in the home
  bool hasWindowInDirection(WindowDirection direction) {
    return windows[direction] ?? false;
  }
}

// Enum to represent home orientation
enum HomeOrientation {
  north,
  east,
  south,
  west,
}

// Enum to represent window directions
enum WindowDirection {
  north,
  east,
  south,
  west,
}

// Extension to get string values for directions
extension HomeOrientationExtension on HomeOrientation {
  String get name {
    switch (this) {
      case HomeOrientation.north:
        return 'North';
      case HomeOrientation.east:
        return 'East';
      case HomeOrientation.south:
        return 'South';
      case HomeOrientation.west:
        return 'West';
    }
  }
}

extension WindowDirectionExtension on WindowDirection {
  String get name {
    switch (this) {
      case WindowDirection.north:
        return 'North';
      case WindowDirection.east:
        return 'East';
      case WindowDirection.south:
        return 'South';
      case WindowDirection.west:
        return 'West';
    }
  }
}