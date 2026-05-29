/// Model for a warehouse location
/// Used in LocationSelectionScreen
class Location {
  final int locationId;
  final String locationCode;
  final String locationName;

  const Location({
    required this.locationId,
    required this.locationCode,
    required this.locationName,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: (json['id'] ?? json['locationId'] ?? 0) as int,
        locationCode: (json['code'] ?? json['locationCode'] ?? '').toString(),
        locationName: (json['name'] ?? json['locationName'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'locationCode': locationCode,
        'locationName': locationName,
      };

  @override
  String toString() => '$locationCode - $locationName';
}
