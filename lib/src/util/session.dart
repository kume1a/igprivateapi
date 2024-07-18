import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class Session {
  Session({
    Map<String, String> defaultHeaders = const {},
  }) {
    _client = RetryClient(
      http.Client(),
      when: (res) =>
          (res.statusCode == 429 ||
              res.statusCode == 500 ||
              res.statusCode == 502 ||
              res.statusCode == 503 ||
              res.statusCode == 504) &&
          (res.request?.method == 'GET' || res.request?.method == 'POST'),
    );

    headers.addAll(defaultHeaders);
  }

  late final http.Client _client;

  final Map<String, String> headers = {};

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? extraHeaders,
    Map<String, String>? params,
  }) async {
    if (params != null) {
      url = Uri(
        scheme: url.scheme,
        host: url.host,
        path: url.path,
        queryParameters: params,
      );
    }
    http.Response response = await _client.get(
      url,
      headers: _mergeHeaders(extraHeaders),
    );
    updateCookie(response);
    return response;
  }

  Future<http.Response> post(
    Uri url, {
    dynamic body,
    Map<String, String>? extraHeaders,
    Map<String, String>? params,
  }) async {
    if (params != null) {
      url = Uri(
        scheme: url.scheme,
        host: url.host,
        path: url.path,
        queryParameters: params,
      );
    }
    http.Response response = await _client.post(
      url,
      body: body,
      headers: _mergeHeaders(extraHeaders),
    );
    updateCookie(response);
    return response;
  }

  void updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie == null) {
      return;
    }

    int index = rawCookie.indexOf(';');
    headers['cookie'] = (index == -1) ? rawCookie : rawCookie.substring(0, index);
  }

  Map<String, String> _mergeHeaders(Map<String, String>? extraHeaders) {
    if (extraHeaders == null) {
      return headers;
    }

    return {...headers, ...extraHeaders};
  }
}
