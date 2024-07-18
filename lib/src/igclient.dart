import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'util/session.dart';
import 'util/util.dart';
import 'util/uuid_factory.dart';

List<Map<String, String>> supportedCapabilities = [
  {
    'value':
        '119.0,120.0,121.0,122.0,123.0,124.0,125.0,126.0,127.0,128.0,129.0,130.0,131.0,132.0,133.0,134.0,135.0,136.0,137.0,138.0,139.0,140.0,141.0,142.0',
    'name': 'SUPPORTED_SDK_VERSIONS',
  },
  {'value': '14', 'name': 'FACE_TRACKER_VERSION'},
  {'value': 'ETC2_COMPRESSION', 'name': 'COMPRESSION'},
  {'value': 'gyroscope_enabled', 'name': 'gyroscope'},
];

class IGClient {
  IGClient(
    this._uuidFactory, {
    List<int>? delayRange,
  }) {
    _uuid = _uuidFactory.v4();
    _phoneId = _uuidFactory.v4();
    _sessionId = _uuidFactory.v4();
    _traySessionId = _uuidFactory.v4();
    _requestId = _uuidFactory.v4();
    _androidDeviceId = generateAndroidDeviceId();
    _userAgent =
        'Instagram ${_deviceSettings['app_version']} Android (${_deviceSettings['android_version']}/${_deviceSettings['android_release']}; ${_deviceSettings['dpi']}; ${_deviceSettings['resolution']}; ${_deviceSettings['manufacturer']}; ${_deviceSettings['model']}; ${_deviceSettings['device']}; ${_deviceSettings['cpu']}; ${_deviceSettings['locale']}; ${_deviceSettings['version_code']})';

    _delayRange = delayRange ?? [1, 3];

    _private = Session();
  }

  final UuidFactory _uuidFactory;

  late final List<int> _delayRange;
  late final Session _private;

  final Map<String, String> _cookieDict = {};
  Map<String, dynamic> _authorizationData = {};
  final Map<String, dynamic> _deviceSettings = {
    'app_version': '269.0.0.18.75',
    'android_version': 26,
    'android_release': '8.0.0',
    'dpi': '480dpi',
    'resolution': '1080x1920',
    'manufacturer': 'OnePlus',
    'device': 'devitron',
    'model': '6T Dev',
    'cpu': 'qcom',
    'version_code': '314665256',
  };
  String _userAgent = '';
  String _uuid = '';
  String _phoneId = '';
  String _sessionId = '';
  String _traySessionId = '';
  String _requestId = '';
  String _androidDeviceId = '';
  String _token = '';
  String _mid = '';
  final int _timezoneOffset = -14400; // New York, GMT-4 in seconds
  final String _locale = 'en_US';
  final String _country = 'US';
  final String _bloksVersioningId =
      'ce555e5500576acd8e84a66018f54a05720f2dce29f0bb5a1f97f0c10d6fac48'; // this param is constant and will change by Instagram app version
  final String _appId = '567067343352427';
  final String _domain = 'i.instagram.com';
  final int _requestTimeout = 1000;

  int _privateRequestsCount = 0;
  int _reloginAttempt = 0;
  dynamic _lastResponse;

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

  String get mid {
    final def = _cookieDict['mid'] ?? '';

    return _mid.isNotEmpty ? _mid : def;
  }

  String get authorization {
    if (_authorizationData.isNotEmpty) {
      String b64part = base64.encode(json.encode(_authorizationData).codeUnits);

      return 'Bearer IGT:2:$b64part';
    }
    return '';
  }

  String generateAndroidDeviceId() {
    return 'android-${sha256.convert(utf8.encode(DateTime.now().millisecondsSinceEpoch.toString())).toString().substring(0, 16)}';
  }

  Map<String, String> get _baseHeaders {
    String locale = _locale.replaceAll('-', '_');
    List<String> acceptLanguage = ['en-US'];
    if (locale.isNotEmpty) {
      String lang = locale.replaceAll('_', '-');
      if (!acceptLanguage.contains(lang)) {
        acceptLanguage.insert(0, lang);
      }
    }
    Map<String, String> headers = {
      'X-IG-App-Locale': locale,
      'X-IG-Device-Locale': locale,
      'X-IG-Mapped-Locale': locale,
      'X-Pigeon-Session-Id': _uuidFactory.v4(prefix: 'UFS-', suffix: '-1'),
      'X-Pigeon-Rawclienttime': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-IG-Bandwidth-Speed-KBPS': (Random().nextInt(5000) + 2500).toString(),
      'X-IG-Bandwidth-TotalBytes-B': (Random().nextInt(85000000) + 5000000).toString(),
      'X-IG-Bandwidth-TotalTime-MS': (Random().nextInt(7000) + 2000).toString(),
      'X-IG-App-Startup-Country': _country.toUpperCase(),
      'X-Bloks-Version-Id': _bloksVersioningId,
      'X-IG-WWW-Claim': '0',
      'X-Bloks-Is-Layout-RTL': 'false',
      'X-Bloks-Is-Panorama-Enabled': 'true',
      'X-IG-Device-ID': _uuid,
      'X-IG-Family-Device-ID': _phoneId,
      'X-IG-Android-ID': _androidDeviceId,
      'X-IG-Timezone-Offset': _timezoneOffset.toString(),
      'X-IG-Connection-Type': 'WIFI',
      'X-IG-Capabilities': '3brTvx0=',
      'X-IG-App-ID': _appId,
      'Priority': 'u=3',
      'User-Agent': _userAgent,
      'Accept-Language': acceptLanguage.join(', '),
      'X-MID': mid,
      'Accept-Encoding': 'gzip, deflate',
      'Host': _domain,
      'X-FB-HTTP-Engine': 'Liger',
      'Connection': 'keep-alive',
      'X-FB-Client-IP': 'True',
      'X-FB-Server-Cluster': 'True',
      'IG-INTENDED-USER-ID': (userId ?? 0).toString(),
      'X-IG-Nav-Chain': '9MV:self_profile:2,ProfileMediaTabFragment:self_profile:3,9Xf:self_following:4',
      'X-IG-SALT-IDS': (Random().nextInt(100100000) + 1061162222).toString(),
    };
    if (userId != null) {
      int nextYear = DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch;
      headers.addAll({
        'IG-U-DS-USER-ID': userId.toString(),
        'IG-U-IG-DIRECT-REGION-HINT':
            'LLA,$userId,$nextYear:01f7bae7d8b131877d8e0ae1493252280d72f6d0d554447cb1dc9049b6b2c507c08605b7',
        'IG-U-SHBID':
            '12695,$userId,$nextYear:01f778d9c9f7546cf3722578fbf9b85143cd6e5132723e5c93f40f55ca0459c8ef8a0d9f',
        'IG-U-SHBTS':
            '${DateTime.now().millisecondsSinceEpoch},$userId,$nextYear:01f7ace11925d0388080078d0282b75b8059844855da27e23c90a362270fddfb3fae7e28',
        'IG-U-RUR':
            'RVA,$userId,$nextYear:01f7f627f9ae4ce2874b2e04463efdb184340968b1b006fa88cb4cc69a942a04201e544c',
      });
    }
    // if (_private.igURur != null) {
    //   headers['IG-U-RUR'] = _private.igURur!;
    // }
    // if (_private.igWwwClaim != null) {
    //   headers['X-IG-WWW-Claim'] = _private.igWwwClaim!;
    // }
    return headers;
  }

  void _requestLog(http.Response response) {
    dev.log(
      "$_private [${response.statusCode}] ${response.request?.method} ${response.request?.url} (${_deviceSettings['app_version']}, ${_deviceSettings['manufacturer']} ${_deviceSettings['model']})",
    );
  }

  String _generateSignature(String data) {
    return 'signed_body=SIGNATURE.${Uri.encodeComponent(data)}';
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

  Future<bool> loginFlow() async {
    List<Map<String, dynamic>?> checkFlow = [];
    await _getReelsTrayFeed(reason: 'cold_start');
    await _getTimelineFeed(reason: 'cold_start_fetch');

    return checkFlow.every((element) => element != null);
  }

  Future<Map<String, dynamic>?> _getTimelineFeed({
    String reason = 'pull_to_refresh',
    String? maxId,
  }) {
    Map<String, String> headers = {
      'X-Ads-Opt-Out': '0',
      'X-DEVICE-ID': _uuid,
      'X-CM-Bandwidth-KBPS': '-1.000',
      'X-CM-Latency': random.nextInt(5).toString(),
    };

    Map<String, dynamic> data = {
      'has_camera_permission': '1',
      'feed_view_info': '[]',
      'phone_id': _phoneId,
      'reason': reason,
      'battery_level': 100,
      'timezone_offset': _timezoneOffset.toString(),
      '_csrftoken': token,
      'device_id': _uuid,
      'request_id': _requestId,
      '_uuid': _uuid,
      'is_charging': random.nextInt(2),
      'is_dark_mode': 1,
      'will_sound_on': random.nextInt(2),
      'session_id': _sessionId,
      'bloks_versioning_id': _bloksVersioningId,
    };

    if (reason == 'pull_to_refresh' || reason == 'auto_refresh') {
      data['is_pull_to_refresh'] = '1';
    } else {
      data['is_pull_to_refresh'] = '0';
    }

    if (maxId != null) {
      data['max_id'] = maxId;
    }

    return _privateRequest(
      'feed/timeline/',
      data: data,
      withSignature: false,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>?> _getReelsTrayFeed({
    String reason = 'pull_to_refresh',
  }) {
    Map<String, dynamic> data = {
      'supported_capabilities_new': supportedCapabilities,
      'reason': reason,
      'timezone_offset': _timezoneOffset.toString(),
      'tray_session_id': _traySessionId,
      'request_id': _uuid,
      '_uuid': _uuid,
      'page_size': 50,
    };

    if (reason == 'cold_start') {
      data['reel_tray_impressions'] = {};
    } else {
      data['reel_tray_impressions'] = {userId.toString(): DateTime.now().millisecondsSinceEpoch.toString()};
    }

    return _privateRequest(
      'feed/reels_tray/',
      data: data,
    );
  }

  Future<bool> login({
    required String username,
    required String password,
    bool relogin = false,
    String verificationCode = '',
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw ArgumentError('Both username and password must be provided.');
    }

    if (relogin) {
      _authorizationData.clear();
      _private.headers.remove('Authorization');
      _cookieDict.clear();
      if (_reloginAttempt > 1) {
        throw ReloginAttemptExceeded();
      }
      _reloginAttempt++;
    }

    if (userId != null && !relogin) {
      // already logged in
      return Future.value(true);
    }

    try {
      preLoginFlow();
    } on PleaseWaitFewMinutes {
      dev.log('Ignore 429: Continue login');
    } on ClientThrottledError {
      dev.log('Ignore 429: Continue login');
    } catch (e) {
      dev.log(e.toString());
    }

    // The instagram application ignores this error and continues to log in (repeat this behavior)
    String encPassword = await passwordEncrypt(password);
    Map<String, dynamic> data = {
      'jazoest': generateJazoest(_phoneId),
      'country_codes': '[{"country_code":"1","source":["default"]}]',
      'phone_id': _phoneId,
      'enc_password': encPassword,
      'username': username,
      'adid': _uuid,
      'guid': _uuid,
      'device_id': _androidDeviceId,
      'google_tokens': '[]',
      'login_attempt_count': '0',
    };

    try {
      await _privateRequest(
        'accounts/login/',
        data: data,
        login: true,
      );
      _authorizationData = parseAuthorization(_lastResponse.headers['ig-set-authorization']);

      return true;
    } on TwoFactorRequired catch (e) {
      if (verificationCode.isEmpty) {
        throw TwoFactorRequired('$e (you did not provide verification_code for login method)');
      }
      String? twoFactorIdentifier = _lastResponse['two_factor_info']['two_factor_identifier'];
      Map<String, dynamic> data = {
        'verification_code': verificationCode,
        'phone_id': _phoneId,
        '_csrftoken': token,
        'two_factor_identifier': twoFactorIdentifier,
        'username': username,
        'trust_this_device': '0',
        'guid': _uuid,
        'device_id': _androidDeviceId,
        'waterfall_id': _uuidFactory.v4(),
        'verification_method': '3',
      };
      await _privateRequest(
        'accounts/two_factor_login/',
        data: data,
        login: true,
      );
      _authorizationData = parseAuthorization(_lastResponse.headers['ig-set-authorization']);

      return true;
    } catch (e) {
      dev.log(e.toString());
    }

    return false;
  }

  Map<String, dynamic> parseAuthorization(String authorization) {
    try {
      String b64part = authorization.split(':').last;
      if (b64part.isEmpty) {
        return {};
      }
      return json.decode(utf8.decode(base64.decode(b64part)));
    } catch (e) {
      dev.log(e.toString());
    }
    return {};
  }

  Future<Map<String, dynamic>?> _privateRequest(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? params,
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
    try {
      if (_delayRange.isNotEmpty) {
        await randomDelay(delayRange: _delayRange);
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

  Future<Map<String, dynamic>> _sendPrivateRequest(
    String endpoint, {
    dynamic data,
    Map<String, String>? params,
    bool login = false,
    bool withSignature = true,
    Map<String, String>? headers,
    dynamic extraSig,
    String? domain,
  }) async {
    _lastResponse = null;
    Map<String, dynamic> lastJson = {};
    _private.headers.addAll(_baseHeaders);
    if (headers != null) {
      _private.headers.addAll(headers);
    }
    if (!login) {
      await Future.delayed(Duration(seconds: _requestTimeout));
    }
    try {
      if (!endpoint.startsWith('/')) {
        endpoint = '/v1/$endpoint';
      }

      if (endpoint == '/challenge/') {
        endpoint = '/v1/challenge/';
      }

      String apiUrl = 'https://$domain/api$endpoint';
      dev.log(apiUrl);
      if (data != null) {
        _private.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
        if (withSignature) {
          data = _generateSignature(json.encode(data));
          if (extraSig != null) {
            data += '&${extraSig.join("&")}';
          }
        }
        var response = await _private.post(
          Uri.parse(apiUrl),
          body: data,
          params: params,
          // proxies: _private.proxies,
        );
        dev.log('private_request ${response.statusCode}: ${response.request?.url} (${response.body})');
        var mid = response.headers['ig-set-x-mid'];
        if (mid != null) {
          _mid = mid;
        }
        _requestLog(response);
        _lastResponse = response;
        lastJson = json.decode(response.body);
        dev.log('last_json $lastJson');
      } else {
        _private.headers.remove('Content-Type');
        var response = await _private.get(
          Uri.parse(apiUrl),
          params: params,
          // proxies: _private.proxies,
        );
        dev.log('private_request ${response.statusCode}: ${response.request?.url} (${response.body})');
        var mid = response.headers['ig-set-x-mid'];
        if (mid != null) {
          _mid = mid;
        }
        _requestLog(response);
        _lastResponse = response;
        // response.raiseForStatus();
        lastJson = json.decode(response.body);
        dev.log('last_json $lastJson');
      }
    } on FormatException catch (e) {
      dev.log(
        'Status ${_lastResponse.statusCode}: JSONDecodeError in private_request (user_id=$userId, endpoint=$endpoint) >>> ${_lastResponse.body}',
      );
      throw ClientJSONDecodeError(
        'JSONDecodeError $e while opening ${_lastResponse.url}',
        // response: _lastResponse,
      );
    } on http.ClientException catch (e) {
      throw ClientConnectionError('${e.runtimeType} $e');
    }

    if (lastJson.containsKey('status') && lastJson['status'] == 'fail') {
      throw ClientError(response: _lastResponse);
    } else if (lastJson.containsKey('error_title')) {
      throw ClientError(response: _lastResponse);
    }
    return lastJson;
  }
}
