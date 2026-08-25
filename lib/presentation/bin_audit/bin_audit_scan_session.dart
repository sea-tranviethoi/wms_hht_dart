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
  ///
  /// Matching is by prefix, not exact equality: many warehouses print one
  /// barcode per physical unit with a serial suffix appended to the item
  /// code (e.g. item code "2022MIWA02" printed as "2022MIWA02001",
  /// "2022MIWA02002", ...). Any scanned code starting with a known item
  /// code counts toward that item; the longest matching item code wins so a
  /// more specific code isn't shadowed by a shorter unrelated one.
  BinAuditScanSplit splitBy(Set<String> validCodes) {
    final matcher = BinAuditCodeMatcher(validCodes);
    final matched = <String, int>{};
    final unmatched = <String, int>{};
    _counts.forEach((code, qty) {
      final itemCode = matcher.matchFor(code);
      if (itemCode != null) {
        matched[itemCode] = (matched[itemCode] ?? 0) + qty;
      } else {
        unmatched[code] = qty;
      }
    });
    return BinAuditScanSplit(matched: matched, unmatched: unmatched);
  }
}

/// Matches a raw scanned barcode value against a set of known item codes,
/// by exact match or by prefix (see [BinAuditScanSession.splitBy]).
class BinAuditCodeMatcher {
  final List<String> _sortedCodes;

  BinAuditCodeMatcher(Set<String> validCodes)
      : _sortedCodes = validCodes
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));

  /// Returns the item code [rawCode] belongs to, or null if none matches.
  String? matchFor(String rawCode) {
    final code = rawCode.trim();
    for (final itemCode in _sortedCodes) {
      if (code == itemCode || code.startsWith(itemCode)) return itemCode;
    }
    return null;
  }
}

/// Result of matching a scan session against the stocktake line item codes.
class BinAuditScanSplit {
  /// itemCode -> counted units, for scanned codes that matched a line.
  final Map<String, int> matched;

  /// raw code -> counted units, for codes with no matching line.
  final Map<String, int> unmatched;

  const BinAuditScanSplit({required this.matched, required this.unmatched});

  bool get hasUnmatched => unmatched.isNotEmpty;
}
