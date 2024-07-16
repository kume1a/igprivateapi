import 'package:uuid/uuid.dart';

class UuidFactory {
  final Uuid _uuid = const Uuid();

  String v4({
    String prefix = '',
    String suffix = '',
  }) =>
      '$prefix${_uuid.v4()}$suffix';
}
