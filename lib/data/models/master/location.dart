/// Model for a warehouse location
/// Used in LocationSelectionScreen
///
/// Backed by the WMS Location entity (FBT.ShareModels.WMS.Location):
/// Id is a Guid (serialized as a string), LocationCD/LocationName are
/// strings -- NOT an int id as this model originally (incorrectly) assumed.
class Location {
  final String locationId;
  final String locationCode;
  final String locationName;

  const Location({
    required this.locationId,
    required this.locationCode,
    required this.locationName,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: (json['id'] ?? json['locationId'] ?? '').toString(),
        locationCode: (json['locationCD'] ??
                json['locationCd'] ??
                json['code'] ??
                json['locationCode'] ??
                '')
            .toString(),
        locationName: (json['locationName'] ?? json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'locationCode': locationCode,
        'locationName': locationName,
      };

  @override
  String toString() => '$locationCode - $locationName';
}
