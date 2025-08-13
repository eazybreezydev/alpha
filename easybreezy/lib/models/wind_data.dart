class WindData {
  final DateTime timestamp;
  final double speed; // Speed in km/h

  WindData({
    required this.timestamp,
    required this.speed,
  });

  factory WindData.fromJson(Map<String, dynamic> json) {
    return WindData(
      timestamp: DateTime.parse(json['timestamp']),
      speed: json['speed'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }

  @override
  String toString() {
    return 'WindData(timestamp: $timestamp, speed: $speed km/h)';
  }
}
