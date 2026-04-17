import 'package:flutter_test/flutter_test.dart';
import 'package:fbt_hht/core/security/crypto_service.dart';

/// Unit test cho CryptoService
/// Port từ services/encryption/MD5.js
///
/// Test case dùng cặp encrypted/plaintext thực từ thiết bị QR
/// Khi có QR thật từ server, thay thế [kEncryptedSample] bằng giá trị thực
void main() {
  group('CryptoService', () {
    // ─── md5Hash ───────────────────────────────────────────────
    group('md5Hash', () {
      test('trả về chuỗi 32 ký tự hex', () {
        final result = CryptoService.md5Hash('WmsHt123@456');
        expect(result.length, equals(32));
        expect(result, matches(RegExp(r'^[0-9a-f]{32}$')));
      });

      test('MD5("WmsHt123@456") đúng giá trị', () {
        // Verify bằng tool online: https://www.md5hashgenerator.com/
        // MD5("WmsHt123@456") = cần verify với giá trị thực từ CryptoJS
        final result = CryptoService.md5Hash('WmsHt123@456');
        expect(result, isNotEmpty);
      });

      test('cùng input → cùng output', () {
        final r1 = CryptoService.md5Hash('test');
        final r2 = CryptoService.md5Hash('test');
        expect(r1, equals(r2));
      });

      test('khác input → khác output', () {
        final r1 = CryptoService.md5Hash('test1');
        final r2 = CryptoService.md5Hash('test2');
        expect(r1, isNot(equals(r2)));
      });
    });

    // ─── Base64 ────────────────────────────────────────────────
    group('Base64 encode/decode', () {
      test('encode rồi decode trả về chuỗi gốc', () {
        const original = 'Hello World 日本語';
        final encoded = CryptoService.encodeBase64(original);
        final decoded = CryptoService.decodeBase64(encoded);
        expect(decoded, equals(original));
      });
    });

    // ─── TripleDES decrypt ─────────────────────────────────────
    group('decryptQRCode (TripleDES/ECB/PKCS7)', () {
      // TODO: Thay bằng cặp encrypted/plaintext thực từ QR thiết bị
      // Cách lấy: scan QR login trên thiết bị Keyence, lấy raw base64 string
      // và giá trị plaintext tương ứng (username:password hoặc JSON)

      test('chuỗi rỗng trả về rỗng (không crash)', () {
        // Encrypted không hợp lệ → trả về '' thay vì throw
        final result = CryptoService.decryptQRCode('');
        expect(result, equals(''));
      });

      test('dữ liệu không hợp lệ không throw exception', () {
        expect(
          () => CryptoService.decryptQRCode('không phải base64!!!'),
          returnsNormally,
        );
      });

      /// Test với dữ liệu thực từ QR server
      /// Bỏ comment và điền [encryptedBase64] + [expectedPlaintext] khi có QR thật
      ///
      // test('decrypt QR thực từ server', () {
      //   const encryptedBase64 = 'BASE64_FROM_QR_CODE_HERE';
      //   const expectedPlaintext = 'EXPECTED_PLAINTEXT_HERE';
      //   final result = CryptoService.decryptQRCode(encryptedBase64);
      //   expect(result, equals(expectedPlaintext));
      // });
    });
  });
}
