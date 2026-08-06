import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;
import '../constants/app_constants.dart';

/// Ported from services/encryption/MD5.js
///
/// Original logic (JS — CryptoJS):
///   const TDESKey = CryptoJS.MD5(passphrase);   // 16-byte MD5
///   CryptoJS.TripleDES.decrypt(message, TDESKey, {
///     mode: ECB, padding: Pkcs7
///   });
///
/// CryptoJS.TripleDES with a 16-byte key → expanded to 24 bytes (DES2 key schedule):
///   key24 = key16[0..15] + key16[0..7]
class CryptoService {
  CryptoService._();

  // ─── TripleDES decrypt QR Login ───────────────────────────────

  /// Decrypts a QR login string encrypted with TripleDES/ECB/PKCS7
  /// [encrypted] : Base64 string from the QR code
  /// [passphrase]: defaults to 'WmsHt123@456'
  static String decryptQRCode(
    String encrypted, {
    String passphrase = AppConstants.qrPassphrase,
  }) {
    if (encrypted.isEmpty) return '';
    try {
      // Step 1: MD5(passphrase) → 16 bytes
      final md5Bytes = Uint8List.fromList(
        md5.convert(utf8.encode(passphrase)).bytes,
      );

      // Step 2: Expand 16 → 24 bytes (CryptoJS DES2 key schedule)
      final key24 = Uint8List(24);
      key24.setRange(0, 16, md5Bytes);
      key24.setRange(16, 24, md5Bytes.sublist(0, 8));

      // Step 3: Base64-decode the ciphertext
      final cipherBytes = base64.decode(encrypted);

      // Step 4: TripleDES ECB PKCS7 decrypt using pointycastle
      final cipher = pc.PaddedBlockCipherImpl(
        pc.PKCS7Padding(),
        pc.ECBBlockCipher(pc.DESedeEngine()),
      );
      cipher.init(
        false, // decrypt
        pc.PaddedBlockCipherParameters<pc.CipherParameters, pc.CipherParameters>(
          pc.KeyParameter(key24),
          null,
        ),
      );

      final plainBytes = cipher.process(Uint8List.fromList(cipherBytes));
      return utf8.decode(plainBytes);
    } catch (_) {
      return '';
    }
  }

  // ─── MD5 Hash ─────────────────────────────────────────────────

  /// MD5 hash of a string → 32-character hex string
  static String md5Hash(String input) =>
      md5.convert(utf8.encode(input)).toString();

  // ─── Base64 utils ─────────────────────────────────────────────

  static String encodeBase64(String input) =>
      base64.encode(utf8.encode(input));

  static String decodeBase64(String input) =>
      utf8.decode(base64.decode(input));
}
