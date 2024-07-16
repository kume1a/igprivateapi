import 'package:uuid/uuid.dart';

class UuidFactory {
  final Uuid _uuid = const Uuid();

  String get v4 => _uuid.v4();
}
