import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

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

Future<void> getPasswordPublicKeys() async {
  final response = await http.get(Uri.parse('https://i.instagram.com/api/v1/qe/sync/'));
  final publickeyid = int.parse(response.headers['ig-set-password-encryption-key-id']!);
  final publickey = response.headers['ig-set-password-encryption-pub-key']!;
}

String passwordEncrypt(String password) {
  final publickeyid = passwordPublickeys().publickeyid;
  final publickey = passwordPublickeys().publickey;
  final sessionKey = randomBytes(32);
  final iv = randomBytes(12);
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final decodedPublickey = base64.decode(publickey);
  final recipientKey = RSA.importKey(decodedPublickey);
  final cipherRsa = PKCS1v15();
  final rsaEncrypted = cipherRsa.encrypt(sessionKey, recipientKey);
  final cipherAes = AES.GCM(sessionKey, iv);
  cipherAes.update(utf8.encode(timestamp));
  final aesEncrypted = cipherAes.encrypt(utf8.encode(password));
  final tag = cipherAes.getAuthTag();
  final sizeBuffer = rsaEncrypted.length.toBytes(Endian.little);
  final payload = base64.encode(
    Uint8List.fromList([
      0x01,
      publickeyid.toBytes(),
      iv,
      sizeBuffer,
      rsaEncrypted,
      tag,
      aesEncrypted,
    ]),
  );
  return '#PWD_INSTAGRAM:4:$timestamp:$payload';
}
