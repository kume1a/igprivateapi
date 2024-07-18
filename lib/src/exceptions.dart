class ClientError implements Exception {
  ClientError({
    this.response,
    this.code,
    this.message,
  });

  final dynamic response;
  final dynamic code;
  final String? message;

  @override
  String toString() {
    return message ?? '';
  }
}

class ClientUnknownError extends ClientError {}

class WrongCursorError extends ClientError {
  @override
  String message = 'You specified a non-existent cursor';
}

class ClientStatusFail extends ClientError {}

class ClientErrorWithTitle extends ClientError {}

class ResetPasswordError extends ClientError {}

class GenericRequestError extends ClientError {
  GenericRequestError() : super(message: 'Sorry, there was a problem with your request');
}

class ClientGraphqlError extends ClientError {
  ClientGraphqlError() : super(message: 'Raised due to graphql issues');
}

class ClientJSONDecodeError extends ClientError {
  ClientJSONDecodeError(String? message) : super(message: message ?? 'Raised due to json decoding issues');
}

class ClientConnectionError extends ClientError {
  ClientConnectionError(String? message)
      : super(message: message ?? 'Raised due to network connectivity-related issues');
}

class ClientBadRequestError extends ClientError {
  ClientBadRequestError() : super(message: 'Raised due to a HTTP 400 response');
}

class ClientUnauthorizedError extends ClientError {
  ClientUnauthorizedError() : super(message: 'Raised due to a HTTP 401 response');
}

class ClientForbiddenError extends ClientError {
  ClientForbiddenError() : super(message: 'Raised due to a HTTP 403 response');
}

class ClientNotFoundError extends ClientError {
  ClientNotFoundError() : super(message: 'Raised due to a HTTP 404 response');
}

class ClientThrottledError extends ClientError {
  ClientThrottledError() : super(message: 'Raised due to a HTTP 429 response');
}

class ClientRequestTimeout extends ClientError {
  ClientRequestTimeout() : super(message: 'Raised due to a HTTP 408 response');
}

class ClientIncompleteReadError extends ClientError {
  ClientIncompleteReadError(String? message)
      : super(message: message ?? 'Raised due to incomplete read HTTP response');
}

class ClientLoginRequired extends ClientError {
  ClientLoginRequired(String? message)
      : super(message: message ?? 'Instagram redirect to https://www.instagram.com/accounts/login/');
}

class ReloginAttemptExceeded extends ClientError {}

class PrivateError extends ClientError {
  PrivateError({String? message}) : super(message: message ?? 'For Private API and last_json logic');
}

class NotFoundError extends PrivateError {
  String reason = 'Not found';
}

class FeedbackRequired extends PrivateError {}

class ChallengeError extends PrivateError {}

class ChallengeRedirection extends ChallengeError {}

class ChallengeRequired extends ChallengeError {}

class ChallengeSelfieCaptcha extends ChallengeError {}

class ChallengeUnknownStep extends ChallengeError {}

class SelectContactPointRecoveryForm extends ChallengeError {}

class RecaptchaChallengeForm extends ChallengeError {}

class SubmitPhoneNumberForm extends ChallengeError {}

class LegacyForceSetNewPasswordForm extends ChallengeError {}

class LoginRequired extends PrivateError {
  LoginRequired() : super(message: 'Instagram request relogin');
}

class SentryBlock extends PrivateError {}

class RateLimitError extends PrivateError {}

class ProxyAddressIsBlocked extends PrivateError {
  ProxyAddressIsBlocked()
      : super(
            message:
                'Instagram has blocked your IP address, use a quality proxy provider (not free, not shared)');
}

class BadPassword extends PrivateError {}

class BadCredentials extends PrivateError {}

class PleaseWaitFewMinutes extends PrivateError {}

class UnknownError extends PrivateError {}

class TrackNotFound extends NotFoundError {}

class MediaError extends PrivateError {}

class MediaNotFound extends MediaError {}

class StoryNotFound extends MediaError {}

class UserError extends PrivateError {}

class UserNotFound extends UserError {}

class CollectionError extends PrivateError {}

class CollectionNotFound extends CollectionError {}

class DirectError extends PrivateError {}

class DirectThreadNotFound extends DirectError {}

class DirectMessageNotFound extends DirectError {}

class VideoTooLongException extends PrivateError {}

class VideoNotDownload extends PrivateError {}

class VideoNotUpload extends PrivateError {}

class VideoConfigureError extends VideoNotUpload {}

class VideoConfigureStoryError extends VideoConfigureError {}

class PhotoNotUpload extends PrivateError {}

class PhotoConfigureError extends PhotoNotUpload {}

class PhotoConfigureStoryError extends PhotoConfigureError {}

class IGTVNotUpload extends PrivateError {}

class IGTVConfigureError extends IGTVNotUpload {}

class ClipNotUpload extends PrivateError {}

class ClipConfigureError extends ClipNotUpload {}

class AlbumNotDownload extends PrivateError {}

class AlbumUnknownFormat extends PrivateError {}

class AlbumConfigureError extends PrivateError {}

class HashtagError extends PrivateError {}

class HashtagNotFound extends HashtagError {}

class LocationError extends PrivateError {}

class LocationNotFound extends LocationError {}

class TwoFactorRequired extends PrivateError {
  TwoFactorRequired(String? message) : super(message: message);
}

class HighlightNotFound extends PrivateError {}

class NoteNotFound extends NotFoundError {
  @override
  String reason = 'Not found';
}

class PrivateAccount extends PrivateError {
  PrivateAccount() : super(message: 'This Account is Private');
}

class InvalidTargetUser extends PrivateError {
  InvalidTargetUser() : super(message: 'Invalid target user');
}

class InvalidMediaId extends PrivateError {
  InvalidMediaId() : super(message: 'Invalid media_id');
}

class MediaUnavailable extends PrivateError {
  MediaUnavailable() : super(message: 'Media is unavailable');
}
