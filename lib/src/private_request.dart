import 'package:http/http.dart' as http;

class PrivateRequest {
  Future<Map<String, dynamic>> sendPrivateRequest(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
    bool login = false,
    bool withSignature = true,
    Map<String, String>? headers,
    dynamic extraSig,
    String? domain,
  }) async {
    if (authorization != null) {
      // if (headers == null) {
      //   headers = {};
      // }
      if (!headers.containsKey('Authorization')) {
        headers['Authorization'] = authorization;
      }
    }
    var kwargs = {
      'data': data,
      'params': params,
      'login': login,
      'with_signature': withSignature,
      'headers': headers,
      'extra_sig': extraSig,
      'domain': domain,
    };
    try {
      if (delayRange != null) {
        await randomDelay(delayRange: delayRange);
      }
      privateRequestsCount++;
      return await _sendPrivateRequest(endpoint, kwargs);
    } on http.ClientRequestTimeoutException {
      logger.info('Wait 60 seconds and try one more time (ClientRequestTimeout)');
      await Future.delayed(const Duration(seconds: 60));
      return await _sendPrivateRequest(endpoint, kwargs);
    } catch (e) {
      if (handleException != null) {
        handleException(this, e);
      } else if (e is ChallengeRequired) {
        challengeResolve(lastJson);
      } else {
        rethrow;
      }
      if (login && userId != null) {
        return lastJson;
      }
      return await _sendPrivateRequest(endpoint, kwargs);
    }
  }

  Future<Map<String, dynamic>> _sendPrivateRequest(String endpoint, Map<String, dynamic> kwargs) async {
    // TODO: Implement the logic to send the private request
  }
}
