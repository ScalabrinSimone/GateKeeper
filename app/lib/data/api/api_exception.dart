//Eccezione tipata sollevata dall'API client.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;
  bool get isNetwork => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
