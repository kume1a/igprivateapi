import 'dart:math';

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
