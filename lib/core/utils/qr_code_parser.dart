/// Parse QR code for picking (format: productCode:janCode:lotNo:expired:...)
Map<String, String?> splitQRCodePick(String qrcode) {
  final parts = qrcode.split(':');
  return {
    'productCode': parts.isNotEmpty && parts[0] != 'N/A' ? parts[0] : null,
    'janCode': parts.length > 1 && parts[1] != 'N/A' ? parts[1] : null,
    'lotNo': parts.length > 2 && parts[2] != 'N/A' ? parts[2] : null,
    'expired': parts.length > 3 ? parts[3] : null,
    'receiptCode': parts.length > 6 ? parts[6] : null,
  };
}

/// Parse QR code for bin (format: locationCode:binCode:...)
Map<String, String?> splitQRCodeBin(String qrcode) {
  final parts = qrcode.split(':');
  return {
    'locationCode': parts.isNotEmpty ? parts[0] : null,
    'locationDescription': parts.length > 1 ? parts[1] : null,
    'binCode': parts.length > 1 ? parts[1] : null,
  };
}

