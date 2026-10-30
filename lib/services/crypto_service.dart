import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  Future<SecretKey> deriveMasterKey(String password, Uint8List salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<String> openBox({
    required SecretKey masterKey,
    required Uint8List salt,
    required String info,
    required String aad,
    required String base64Payload,
  }) async {
    final d = base64.decode(base64Payload);
    if (d.length < 28) {
      throw Exception('Ciphertext too short');
    }
    final iv = d.sublist(0, 12);
    final cipherText = d.sublist(12, d.length - 16);
    final tag = d.sublist(d.length - 16);

    final derivedKey = await _hkdf.deriveKey(
      secretKey: masterKey,
      nonce: salt,
      info: utf8.encode(info),
    );

    final secretBox = SecretBox(
      cipherText,
      nonce: iv,
      mac: Mac(tag),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: derivedKey,
      aad: utf8.encode(aad),
    );

    return utf8.decode(decryptedBytes);
  }
}
