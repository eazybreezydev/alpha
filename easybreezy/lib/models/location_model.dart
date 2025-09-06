class LocationModel {
  final String id;
  final String name;
  final String city;
  final String province;
  final double latitude;
  final double longitude;
  final bool isCurrentLocation;
  final DateTime createdAt;

  const LocationModel({
    required this.id,
    required this.name,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.isCurrentLocation = false,
    required this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      isCurrentLocation: json['isCurrentLocation'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'isCurrentLocation': isCurrentLocation,
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
    bool? isCurrentLocation,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      province: province ?? this.province,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => name.isNotEmpty ? name : city;
  String get fullLocation => province.isNotEmpty ? '$city, $province' : city;
}
