import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';

import '../ig_public_request.dart';

final random = Random();
const ascii = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String genToken({int size = 10, bool symbols = false}) {
  String charset = ascii;
  if (symbols) {
    charset += '!@#\$%^&*()_-+=[]{}|;:,.<>/?';
  }

  final charsetLength = charset.length;

  return List.generate(
    size,
    (index) => charset[random.nextInt(charsetLength)],
  ).join();
}

Future<void> randomDelay({
  required List<int> delayRange,
}) {
  final random = Random();
  final minSleep = delayRange[0];
  final maxSleep = delayRange[1];
  final delay = Duration(seconds: minSleep + random.nextInt(maxSleep - minSleep));

  return Future.delayed(delay);
}

Uint8List randomBytes(int length) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (index) => random.nextInt(256));
  return Uint8List.fromList(bytes);
}

String generateJazoest(String symbols) {
  int amount = symbols.codeUnits.reduce((a, b) => a + b);
  return '2$amount';
}

Future<Map<String, dynamic>> _getPasswordPublicKeys() async {
  final publicRequest = IGPublicRequest();

  final response = await publicRequest.publicRequest('https://i.instagram.com/api/v1/qe/sync/');
  final publickeyid = int.parse(response?.headers['ig-set-password-encryption-key-id'] ?? '');
  final publickey = response?.headers['ig-set-password-encryption-pub-key']!;

  return {
    'publickeyid': publickeyid,
    'publickey': publickey,
  };
}

Future<String> encryptPassword(String password) async {
  final publicKeys = await _getPasswordPublicKeys();

  final int publicKeyId = publicKeys['publickeyid'];
  final String publicKey = publicKeys['publickey'];

  // Generating random bytes for session key and IV
  final sessionKey = randomBytes(32);
  final iv = randomBytes(12);
  final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();

  // RSA Encryption
  final decodedPublicKey = utf8.decode(base64Decode(publicKey));

  final rsaPublicKey = RSAKeyParser().parse(decodedPublicKey) as RSAPublicKey;
  final encrypter = Encrypter(RSA(publicKey: rsaPublicKey));
  final rsaEncrypted = encrypter.encryptBytes(sessionKey, iv: IV.fromLength(0)).bytes;

  // AES Encryption
  final aesEncrypter = Encrypter(AES(Key(sessionKey), mode: AESMode.gcm, padding: null));
  final aesEncrypted = aesEncrypter.encrypt(password, iv: IV(iv));

  // Preparing the payload
  final sizeBuffer = Uint8List(2)..buffer.asByteData().setInt16(0, rsaEncrypted.length, Endian.little);
  final payload = Uint8List.fromList([
    0x01,
    publicKeyId,
    ...iv,
    ...sizeBuffer,
    ...rsaEncrypted,
    ...aesEncrypted.bytes,
  ]);

  // Encoding the payload
  final encodedPayload = base64Encode(payload);
  return '#PWD_INSTAGRAM:4:$timestamp:$encodedPayload';
}

String truncate(String text, int length) {
  if (text.length <= length) {
    return text;
  }
  return '${text.substring(0, length)}${text.length > length ? '...' : ''}';
}
