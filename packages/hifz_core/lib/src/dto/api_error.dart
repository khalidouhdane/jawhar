import 'wire_codec.dart';

/// The `/v1` error body (roadmap §5):
/// `{"error":{"code":"…","message":"…","retryable":bool}}`.
///
/// `retryable` drives the outbox: `false` (validation, ownership) poisons
/// the row — kept for diagnostics, never retried; `true` (rate limit, 5xx,
/// network) means exponential backoff with jitter.
final class ApiError {
  final String code;
  final String message;
  final bool retryable;

  const ApiError({
    required this.code,
    required this.message,
    required this.retryable,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    code: WireCodec.requireString(json, 'code'),
    message: WireCodec.requireString(json, 'message', allowEmpty: true),
    retryable: WireCodec.requireBool(json, 'retryable'),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'retryable': retryable,
  };

  @override
  bool operator ==(Object other) =>
      other is ApiError &&
      other.code == code &&
      other.message == message &&
      other.retryable == retryable;

  @override
  int get hashCode => Object.hash(code, message, retryable);

  @override
  String toString() => 'ApiError($code, retryable: $retryable, $message)';
}

/// Top-level error envelope: `{"error": {...}}`.
final class ApiErrorEnvelope {
  final ApiError error;

  const ApiErrorEnvelope(this.error);

  factory ApiErrorEnvelope.fromJson(Map<String, dynamic> json) =>
      ApiErrorEnvelope(ApiError.fromJson(WireCodec.requireMap(json, 'error')));

  Map<String, dynamic> toJson() => {'error': error.toJson()};
}
