import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';

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

Future<Map<String, dynamic>> _getPasswordPublicKeys() async {
  final response = await http.get(Uri.parse('https://i.instagram.com/api/v1/qe/sync/'));
  final publickeyid = int.parse(response.headers['ig-set-password-encryption-key-id']!);
  final publickey = response.headers['ig-set-password-encryption-pub-key']!;

  return {
    'publickeyid': publickeyid,
    'publickey': publickey,
  };
}

Future<String> passwordEncrypt(String password) async {
  final publicKeys = await _getPasswordPublicKeys();
  int publickeyid = publicKeys['publickeyid'];
  String publickey = publicKeys['publickey'];

  // Generate random session key and IV
  final sessionKey = randomBytes(32);
  final iv = randomBytes(12);

  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Decode public key
  final decodedPublicKey = base64Decode(publickey);

  // RSA encryption
  final parser = RSAKeyParser();
  final recipientKey = parser.parse(decodedPublicKey);
  final rsaCipher = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(recipientKey));
  final rsaEncrypted = rsaCipher.process(sessionKey);

  // AES encryption
  final aesCipher = GCMBlockCipher(AESEngine())
    ..init(
      true,
      AEADParameters(
          KeyParameter(sessionKey), 128, iv, Uint8List.fromList(utf8.encode(timestamp.toString()))),
    );
  final paddedPassword = Uint8List.fromList(utf8.encode(password));
  final aesEncrypted = aesCipher.process(paddedPassword);

  // Construct payload
  final sizeBuffer = Uint8List(2)..buffer.asByteData().setUint16(0, rsaEncrypted.length, Endian.little);
  final payload = base64Encode(
    Uint8List.fromList(
      [
        0x01,
        publickeyid,
        ...iv,
        ...sizeBuffer,
        ...rsaEncrypted,
        ...aesEncrypted,
      ],
    ),
  );

  return '#PWD_INSTAGRAM:4:$timestamp:$payload';
}

class RSAKeyParser {
  RSAPublicKey parse(Uint8List key) {
    final asn1Parser = ASN1Parser(key);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    if (topLevelSeq.elements?.length != 2) {
      throw ArgumentError('Invalid RSA key');
    }

    final publicKeySeq = topLevelSeq.elements![1] as ASN1Sequence;
    final modulus = publicKeySeq.elements![0] as ASN1Integer;
    final exponent = publicKeySeq.elements![1] as ASN1Integer;

    if (modulus.integer == null || exponent.integer == null) {
      throw ArgumentError('Invalid RSA key');
    }

    return RSAPublicKey(modulus.integer!, exponent.integer!);
  }
}

String generateJazoest(String symbols) {
  int amount = symbols.codeUnits.reduce((a, b) => a + b);
  return '2$amount';
}
