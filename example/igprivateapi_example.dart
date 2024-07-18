import 'package:igprivateapi/src/igclient.dart';
import 'package:igprivateapi/src/util/uuid_factory.dart';

Future<void> main() async {
  IGClient igClient = IGClient(UuidFactory());

  await igClient.login(username: 'test_brainrot', password: 'testbrainrot123');
}
