import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

import 'exceptions.dart';
import 'util/util.dart';
import 'util/uuid_factory.dart';

class PreLoginFlow {
  PreLoginFlow(
    this._uuidFactory, {
    List<int>? delayRange,
  }) {
    _uuid = _uuidFactory.v4;

    _delayRange = delayRange ?? [1, 3];
  }

  final UuidFactory _uuidFactory;

  late final List<int> _delayRange;

  final Map<String, String> _cookieDict = {};
  final Map<String, String> _authorizationData = {};
  String _uuid = '';
  String _token = '';
  int _privateRequestsCount = 0;
  dynamic _lastResponse;

  Future<void> _randomDelay({
    required List<int> delayRange,
  }) {
    final random = Random();
    final minSleep = delayRange[0];
    final maxSleep = delayRange[1];
    final delay = Duration(seconds: minSleep + random.nextInt(maxSleep - minSleep));

    return Future.delayed(delay);
  }

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

  String get authorization {
    if (_authorizationData.isNotEmpty) {
      String b64part = base64.encode(json.encode(_authorizationData).codeUnits);

      return 'Bearer IGT:2:$b64part';
    }
    return '';
  }

  Future<bool> preLoginFlow() async {
    await _syncLauncher(true);

    return true;
  }

  Future<Map<String, dynamic>?> _syncLauncher(bool login) async {
    Map<String, dynamic> data = {
      'id': _uuid,
      'server_config_retrieval': '1',
    };

    if (!login) {
      data['_uid'] = userId;
      data['_uuid'] = _uuid;
      data['_csrftoken'] = token;
    }

    return _privateRequest(
      'launcher/sync/',
      data: data,
      login: login,
    );
  }

  Future<Map<String, dynamic>?> _privateRequest(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
    bool login = false,
    bool withSignature = true,
    Map<String, String>? headers,
    dynamic extraSig,
    String? domain,
  }) async {
    if (authorization.isNotEmpty) {
      headers ??= {};

      if (!headers.containsKey('authorization')) {
        headers['Authorization'] = authorization;
      }
    }
    Map<String, dynamic> kwargs = {
      'data': data,
      'params': params,
      'login': login,
      'with_signature': withSignature,
      'headers': headers,
      'extra_sig': extraSig,
      'domain': domain,
    };
    try {
      if (_delayRange.isNotEmpty) {
        await _randomDelay(delayRange: _delayRange);
      }
      _privateRequestsCount++;
      return _sendPrivateRequest(
        endpoint,
        data: data,
        params: params,
        login: login,
        withSignature: withSignature,
        headers: headers,
        extraSig: extraSig,
        domain: domain,
      );
    } on ClientRequestTimeout {
      dev.log('Wait 60 seconds and try one more time (ClientRequestTimeout)');
      await Future.delayed(const Duration(seconds: 60));
      return _sendPrivateRequest(
        endpoint,
        data: data,
        params: params,
        login: login,
        withSignature: withSignature,
        headers: headers,
        extraSig: extraSig,
        domain: domain,
      );
    } catch (e) {
      dev.log('error sending private request $e');
    }
    return null;
  }

  // Future<Map<String, dynamic>> _sendPrivateRequest(
  //   String endpoint, {
  //   Map<String, dynamic>? data,
  //   Map<String, dynamic>? params,
  //   bool login = false,
  //   bool withSignature = true,
  //   Map<String, String>? headers,
  //   dynamic extraSig,
  //   String? domain,
  // }) async {
  //   _lastResponse = null;
  //   Map<String, dynamic> lastJson = {};
  //   _private.headers.addAll(_baseHeaders);
  //   if (headers != null) {
  //     _private.headers.addAll(headers);
  //   }
  //   if (!login) {
  //     await Future.delayed(Duration(seconds: _requestTimeout));
  //   }
  //   try {
  //     if (!endpoint.startsWith('/')) {
  //       endpoint = '/v1/$endpoint';
  //     }

  //     if (endpoint == '/challenge/') {
  //       endpoint = '/v1/challenge/';
  //     }

  //     String apiUrl = 'https://${domain ?? config.API_DOMAIN}/api$endpoint';
  //     logger.info(apiUrl);
  //     if (data != null) {
  //       _private.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
  //       if (withSignature) {
  //         data = generateSignature(json.encode(data));
  //         if (extraSig != null) {
  //           data += '&' + extraSig.join('&');
  //         }
  //       }
  //       var response = await _private.post(
  //         apiUrl,
  //         body: data,
  //         headers: _private.headers,
  //         params: params,
  //         proxies: _private.proxies,
  //       );
  //       logger.debug(
  //         'private_request ${response.statusCode}: ${response.url} (${response.body})',
  //       );
  //       var mid = response.headers['ig-set-x-mid'];
  //       if (mid != null) {
  //         _mid = mid;
  //       }
  //       _requestLog(response);
  //       _lastResponse = response;
  //       response.raiseForStatus();
  //       lastJson = json.decode(response.body);
  //       logger.debug('last_json $lastJson');
  //     } else {
  //       _private.headers.remove('Content-Type');
  //       var response = await _private.get(
  //         apiUrl,
  //         headers: _private.headers,
  //         params: params,
  //         proxies: _private.proxies,
  //       );
  //       logger.debug(
  //         'private_request ${response.statusCode}: ${response.url} (${response.body})',
  //       );
  //       var mid = response.headers['ig-set-x-mid'];
  //       if (mid != null) {
  //         _mid = mid;
  //       }
  //       _requestLog(response);
  //       _lastResponse = response;
  //       response.raiseForStatus();
  //       lastJson = json.decode(response.body);
  //       logger.debug('last_json $lastJson');
  //     }
  //   } on FormatException catch (e) {
  //     logger.error(
  //       'Status ${_lastResponse.statusCode}: JSONDecodeError in private_request (user_id=$_userId, endpoint=$endpoint) >>> ${_lastResponse.body}',
  //     );
  //     throw ClientJSONDecodeError(
  //       'JSONDecodeError $e while opening ${_lastResponse.url}',
  //       response: _lastResponse,
  //     );
  //   } on http.ClientException catch (e) {
  //     throw ClientConnectionError('${e.runtimeType} $e');
  //   } on http.HTTPException catch (e) {
  //     throw ClientError(e, response: _lastResponse, lastJson: lastJson);
  //   } on http.TimeoutException catch (e) {
  //     throw ClientRequestTimeout(e, response: _lastResponse, lastJson: lastJson);
  //   } on http.Response catch (e) {
  //     throw ClientError(e, response: _lastResponse, lastJson: lastJson);
  //   }
  //   if (lastJson.containsKey('status') && lastJson['status'] == 'fail') {
  //     throw ClientError(response: _lastResponse, lastJson: lastJson);
  //   } else if (lastJson.containsKey('error_title')) {
  //     throw ClientError(response: _lastResponse, lastJson: lastJson);
  //   }
  //   return lastJson;
  // }
}
