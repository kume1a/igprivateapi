import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'util/util.dart';
import 'util/uuid_factory.dart';

class PreLoginFlow {
  PreLoginFlow(
    this._uuidFactory,
  ) {
    _uuid = _uuidFactory.v4;
  }

  final UuidFactory _uuidFactory;

  final Map<String, String> _cookieDict = {};
  final Map<String, String> _authorizationData = {};
  String _uuid = '';
  String _token = '';

  int? get userId {
    String? userId = _cookieDict['ds_user_id'];
    if (userId == null && _authorizationData.isNotEmpty) {
      userId = _authorizationData['ds_user_id'];
    }

    if (userId != null) {
      return int.parse(userId);
    }

    return null;
  }

  String get token {
    if (_token.isEmpty) {
      _token = _cookieDict['csrftoken'] ?? genToken(size: 64);
    }
    return _token;
  }

  Future<bool> preLoginFlow() async {
    await _syncLauncher(true);

    return true;
  }

  Future<Map<String, dynamic>> _syncLauncher(bool login) async {
    Map<String, dynamic> data = {
      'id': _uuid,
      'server_config_retrieval': '1',
    };

    if (login == false) {
      data['_uid'] = userId;
      data['_uuid'] = _uuid;
      data['_csrftoken'] = token;
    }

    return _privateRequest('launcher/sync/', data, login: login);
  }
}
