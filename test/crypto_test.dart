import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_hub/services/crypto_service.dart';

void main() {
  test('CryptoService derives master key and decrypts box', () async {
    final service = CryptoService();
    final salt = Uint8List.fromList(utf8.encode('16bytesSaltValue'));
    final masterKey = await service.deriveMasterKey('secret123', salt, 5000);

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final aesGcm = AesGcm.with256bits();

    final derived = await hkdf.deriveKey(
      secretKey: masterKey,
      nonce: salt,
      info: utf8.encode('testInfo'),
    );
    final nonce = List<int>.generate(12, (i) => i + 1);
    final box = await aesGcm.encrypt(
      utf8.encode('Hello Antigravity Study Hub!'),
      secretKey: derived,
      nonce: nonce,
      aad: utf8.encode('testAad'),
    );

    final combined = <int>[...box.nonce, ...box.cipherText, ...box.mac.bytes];
    final b64 = base64.encode(combined);

    final decrypted = await service.openBox(
      masterKey: masterKey,
      salt: salt,
      info: 'testInfo',
      aad: 'testAad',
      base64Payload: b64,
    );

    expect(decrypted, equals('Hello Antigravity Study Hub!'));
  });
}
