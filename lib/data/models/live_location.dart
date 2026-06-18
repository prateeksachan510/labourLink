class LiveLocation {
  const LiveLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  final double lat;
  final double lng;
  final String updatedAt;

  factory LiveLocation.fromMap(Map<Object?, Object?> map) {
    return LiveLocation(
      lat: double.tryParse((map['lat'] ?? '0').toString()) ?? 0,
      lng: double.tryParse((map['lng'] ?? '0').toString()) ?? 0,
      updatedAt: (map['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'updatedAt': updatedAt,
    };
  }
}
