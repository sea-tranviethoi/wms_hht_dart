import '../../core/utils/json_utils.dart';

class Tenant {
  final int tenantId;
  final String tenantFullName;

  Tenant({required this.tenantId, required this.tenantFullName});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      tenantId: toInt(json['tenantId']) ?? toInt(json['id']) ?? 0,
      tenantFullName: (json['tenantFullName'] ?? json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tenantId': tenantId,
    'tenantFullName': tenantFullName,
  };
}
