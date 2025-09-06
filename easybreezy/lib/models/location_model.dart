import '../models/home_config.dart';

class LocationModel {
  final String id;
  final String name;
  final String city;
  final String province;
  final String? address; // Full address string
  final double latitude;
  final double longitude;
  final HomeOrientation? orientation; // Building orientation
  final bool isCurrentLocation;
  final bool isHome; // Indicates if this is the home location
  final DateTime createdAt;

  const LocationModel({
    required this.id,
    required this.name,
    required this.city,
    required this.province,
    this.address,
    required this.latitude,
    required this.longitude,
    this.orientation,
    this.isCurrentLocation = false,
    this.isHome = false,
    required this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      orientation: json['orientation'] != null 
          ? HomeOrientation.values.firstWhere(
              (e) => e.toString() == json['orientation'],
              orElse: () => HomeOrientation.north,
            )
          : null,
      isCurrentLocation: json['isCurrentLocation'] as bool? ?? false,
      isHome: json['isHome'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'province': province,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'orientation': orientation?.toString(),
      'isCurrentLocation': isCurrentLocation,
      'isHome': isHome,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LocationModel copyWith({
    String? id,
    String? name,
    String? city,
    String? province,
    double? latitude,
    double? longitude,
    String? address,
    HomeOrientation? orientation,
    bool? isCurrentLocation,
    bool? isHome,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      province: province ?? this.province,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      orientation: orientation ?? this.orientation,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      isHome: isHome ?? this.isHome,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => name.isNotEmpty ? name : city;
  String get fullLocation => province.isNotEmpty ? '$city, $province' : city;
}
