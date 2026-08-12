/// Aggregates barcodes captured during a multi-scan cycle-count session.
///
/// Cycle counting needs to count each physical item, so a single "capture"
/// (one camera frame) may contain several barcodes — including several copies
/// of the same value when identical items sit side by side. Each detection in
/// a frame counts as one unit; values are grouped and summed across captures.
class BinAuditScanSession {
  final Map<String, int> _counts = {};
  int _captures = 0;

  /// Number of capture actions performed in this session.
  int get captureCount => _captures;

  /// Distinct barcode values seen.
  int get distinctCodes => _counts.length;

  /// Total units counted across all captures.
  int get totalUnits => _counts.values.fold(0, (a, b) => a + b);

  /// Read-only view of value -> counted units.
  Map<String, int> get counts => Map.unmodifiable(_counts);

  int countFor(String code) => _counts[code.trim()] ?? 0;

  bool get isEmpty => _counts.isEmpty;

  /// Adds one captured frame. [rawValuesInFrame] may contain duplicate values
  /// (one entry per physical barcode detected); each occurrence adds one unit.
  void addCapture(List<String> rawValuesInFrame) {
    _captures++;
    for (final raw in rawValuesInFrame) {
      final code = raw.trim();
      if (code.isEmpty) continue;
      _counts[code] = (_counts[code] ?? 0) + 1;
    }
  }

  /// Manually removes one unit of a value (undo a mis-scan).
  void decrement(String code) {
    final key = code.trim();
    final cur = _counts[key];
    if (cur == null) return;
    if (cur <= 1) {
      _counts.remove(key);
    } else {
      _counts[key] = cur - 1;
    }
  }

  void reset() {
    _counts.clear();
    _captures = 0;
  }

  /// Splits the counted values into those matching [validCodes] (existing
  /// stocktake lines) and those that do not correspond to any line.
  BinAuditScanSplit splitBy(Set<String> validCodes) {
    final normalized = validCodes.map((c) => c.trim()).toSet();
    final matched = <String, int>{};
    final unmatched = <String, int>{};
    _counts.forEach((code, qty) {
      if (normalized.contains(code)) {
        matched[code] = qty;
      } else {
        unmatched[code] = qty;
      }
    });
    return BinAuditScanSplit(matched: matched, unmatched: unmatched);
  }
}

/// Result of matching a scan session against the stocktake line item codes.
class BinAuditScanSplit {
  /// code -> counted units, for codes that match an existing line.
  final Map<String, int> matched;

  /// code -> counted units, for codes with no matching line.
  final Map<String, int> unmatched;

  const BinAuditScanSplit({required this.matched, required this.unmatched});

  bool get hasUnmatched => unmatched.isNotEmpty;
}
