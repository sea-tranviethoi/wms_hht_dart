class InventStockTakeRecording {
  final String? id;
  final String? stockTakeNo;
  final int? recordNo;
  final String? location;
  final String? personInCharge;
  final DateTime? transactionDate;
  final String? status;
  final String? remarks;
  final String? hhtStatus;
  final String? hhtInfo;
  final int? tenantId;

  InventStockTakeRecording({
    this.id,
    this.stockTakeNo,
    this.recordNo,
    this.location,
    this.personInCharge,
    this.transactionDate,
    this.status,
    this.remarks,
    this.hhtStatus,
    this.hhtInfo,
    this.tenantId,
    this.lines,
  });

  factory InventStockTakeRecording.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['transactionDate'] is String &&
        (json['transactionDate'] as String).isNotEmpty) {
      try {
        parsedDate = DateTime.parse(json['transactionDate'] as String);
      } catch (_) {
        parsedDate = null;
      }
    }

    return InventStockTakeRecording(
      id: json['id'] as String?,
      stockTakeNo: json['stockTakeNo'] as String?,
      recordNo: json['recordNo'] is int
          ? json['recordNo'] as int
          : (json['recordNo'] is num
                ? (json['recordNo'] as num).toInt()
                : null),
      location: json['location'] as String?,
      personInCharge: json['personInCharge'] as String?,
      transactionDate: parsedDate,
      status: json['status']?.toString(),
      remarks: json['remarks'] as String?,
      hhtStatus: json['hhtStatus']?.toString(),
      hhtInfo: json['hhtInfo'] as String?,
      tenantId: json['tenantId'] is int
          ? json['tenantId'] as int
          : (json['tenantId'] is num
                ? (json['tenantId'] as num).toInt()
                : null),
      lines: (() {
        final raw =
            json['inventStockTakeRecordingLineDtos'] ??
            json['lineDtos'] ??
            json['lines'];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map(
                (e) => InventStockTakeRecordingLine.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
        return null;
      })(),
    );
  }

  final List<InventStockTakeRecordingLine>? lines;

  Map<String, dynamic> toJson() => {
    'id': id,
    'stockTakeNo': stockTakeNo,
    'recordNo': recordNo,
    'location': location,
    'personInCharge': personInCharge,
    'transactionDate': transactionDate?.toIso8601String(),
    'status': status,
    'remarks': remarks,
    'hhtStatus': hhtStatus,
    'hhtInfo': hhtInfo,
    'tenantId': tenantId,
    'inventStockTakeRecordingLineDtos': lines?.map((e) => e.toJson()).toList(),
  };

  /// Human-friendly status text. Maps common status codes:
  ///  - '0' or 0 -> 'Pending'
  ///  - '1' or 1 -> 'Done'
  /// Otherwise returns original status string.
  String? get statusText {
    if (status == null) return null;
    final s = status!.trim();
    if (s == '0') return 'Pending';
    final n = int.tryParse(s);
    if (n != null) {
      if (n == 0) return 'Pending';
      if (n == 1) return 'Done';
    }
    // preserve existing human words
    if (s.toLowerCase() == 'pending' || s.toLowerCase() == 'done') {
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }
    return s;
  }
}

class InventStockTakeRecordingLine {
  final Map<String, dynamic> _raw;

  InventStockTakeRecordingLine(this._raw);

  factory InventStockTakeRecordingLine.fromJson(Map<String, dynamic> json) {
    return InventStockTakeRecordingLine(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => _raw;

  String? get itemCode {
    return _raw['itemCode'] as String? ??
        _raw['productNo'] as String? ??
        _raw['productCode'] as String?;
  }

  String? get description =>
      _raw['description'] as String? ?? _raw['desc'] as String?;

  String? get lot {
    return _raw['lot'] as String? ??
        _raw['lotNo'] as String? ??
        _raw['batch'] as String? ??
        _raw['batchNo'] as String? ??
        _raw['lotNumber'] as String?;
  }

  String? get bin {
    return _raw['bin'] as String? ??
        _raw['binLocation'] as String? ??
        _raw['binCode'] as String? ??
        _raw['storageLocation'] as String? ??
        _raw['location'] as String?;
  }

  num? get expectedQty {
    final v =
        _raw['expectedQty'] ??
        _raw['expectedQuantity'] ??
        _raw['qtyExpected'] ??
        _raw['plannedQty'] ??
        _raw['expected'];
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  num? get actualQty {
    final v =
        _raw['actualQty'] ??
        _raw['actualQuantity'] ??
        _raw['countedQty'] ??
        _raw['qtyCounted'] ??
        _raw['qty'] ??
        _raw['quantity'];
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  // Deprecated: alias for actualQty for backward compatibility
  num? get qty => actualQty;

  String prettyPrimary() {
    final code = itemCode ?? _raw['id']?.toString();
    return code ?? 'Line';
  }
}

// Đây là file model, không chứa logic gọi API hay provider.
// Nếu bạn muốn thêm các hàm tiện ích chuyển đổi hoặc validate, hãy nói rõ yêu cầu cụ thể.
