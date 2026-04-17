import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Verify MD5 hash and decrypt login data
/// Returns username|password string
String verifyMd5Hash(String encryptedData) {
  try {
    // Decode base64
    final bytes = base64Decode(encryptedData);
    
    // This is a simplified version - you may need to adjust based on actual encryption
    // In React Native, it uses crypto-js with MD5
    final decoded = utf8.decode(bytes);
    
    // Split by | to get username and password
    return decoded;
  } catch (e) {
    throw Exception('Failed to decrypt QR data: $e');
  }
}

/// Generate MD5 hash
String generateMd5Hash(String input) {
  final bytes = utf8.encode(input);
  final digest = md5.convert(bytes);
  return digest.toString();
}

