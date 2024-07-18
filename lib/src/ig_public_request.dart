import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'util/session.dart';
import 'util/util.dart';

class IGPublicRequest {
  IGPublicRequest({
    List<int>? delayRange,
  }) {
    _public = Session(
      defaultHeaders: {
        'Connection': 'Keep-Alive',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip,deflate',
        'Accept-Language': 'en-US',
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15',
      },
    );

    requestTimeout = requestTimeout;
    _delayRange = delayRange ?? [1, 3];
  }

  late final Session _public;

  final String publicApiUrl = 'https://www.instagram.com/';
  final String graphqlPublicApiUrl = 'https://www.instagram.com/graphql/query/';

  List<int> _delayRange = [];
  int publicRequestsCount = 0;
  http.Response? lastPublicResponse;
  Map<String, dynamic> lastPublicJson = {};
  int requestTimeout = 1;
  int lastResponseTs = 0;

  Future<http.Response?> publicRequest(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? params,
    Map<String, String>? headers,
    int retriesCount = 3,
    int retriesTimeout = 2,
  }) async {
    assert(retriesCount <= 10, 'Retries count is too high');
    assert(retriesTimeout <= 600, 'Retries timeout is too high');

    for (int iteration = 0; iteration < retriesCount; iteration++) {
      try {
        if (_delayRange.isNotEmpty) {
          randomDelay(delayRange: _delayRange);
        }
        return _sendPublicRequest(
          url,
          data: data,
          params: params,
          headers: headers,
        );
      } on ClientLoginRequired {
        rethrow; // Stop retries
      } on ClientNotFoundError {
        rethrow; // Stop retries
      } on ClientBadRequestError {
        rethrow; // Stop retries
      } on ClientError catch (e) {
        final msg = e.toString();
        if (e is ClientConnectionError &&
            msg.contains('SOCKSHTTPSConnectionPool') &&
            msg.contains('Max retries exceeded with url') &&
            msg.contains('Failed to establish a new connection')) {
          rethrow;
        }
        if (retriesCount > iteration + 1) {
          await Future.delayed(Duration(seconds: retriesTimeout));
        } else {
          rethrow;
        }
        continue;
      }
    }
    return null;
  }

  Future<http.Response?> _sendPublicRequest(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? params,
    Map<String, String>? headers,
    bool stream = false,
  }) async {
    publicRequestsCount++;
    if (headers != null) {
      _public.headers.addAll(headers);
    }
    if (lastResponseTs != 0 && (DateTime.now().millisecondsSinceEpoch - lastResponseTs) < 1000) {
      await Future.delayed(const Duration(seconds: 1));
    }
    if (requestTimeout != 0) {
      await Future.delayed(Duration(seconds: requestTimeout));
    }
    try {
      http.Response response;
      if (data != null) {
        response = await _public.post(
          Uri.parse(url),
          body: data,
          extraHeaders: headers,
          params: params,
        );
      } else {
        response = await _public.get(
          Uri.parse(url),
          extraHeaders: headers,
          params: params,
        );
      }

      if (stream) {
        return response;
      }

      int expectedLength = int.parse(response.headers['Content-Length'] ?? '0');
      int actualLength = response.bodyBytes.length;
      if (actualLength < expectedLength) {
        throw ClientIncompleteReadError(
          'Incomplete read ($actualLength bytes read, $expectedLength more expected)',
        );
      }

      return response;
    } on FormatException catch (e) {
      // if (response.request!.url.path.contains('/login/')) {
      //   throw ClientLoginRequired(e.toString());
      // }

      throw ClientJSONDecodeError('JSONDecodeError $e while opening $url');
    } on http.ClientException catch (e) {
      // if (e.!.statusCode == 401) {
      //   throw ClientUnauthorizedError(e.toString(), response: e.response!);
      // } else if (e.response!.statusCode == 403) {
      //   throw ClientForbiddenError(e.toString(), response: e.response!);
      // } else if (e.response!.statusCode == 400) {
      //   throw ClientBadRequestError(e.toString(), response: e.response!);
      // } else if (e.response!.statusCode == 429) {
      //   throw ClientThrottledError(e.toString(), response: e.response!);
      // } else if (e.response!.statusCode == 404) {
      //   throw ClientNotFoundError(e.toString(), response: e.response!);
      // }
      // throw ClientError(e.toString(), response: e.response!);
    } finally {
      lastResponseTs = DateTime.now().millisecondsSinceEpoch;
    }
    return null;
  }
}
