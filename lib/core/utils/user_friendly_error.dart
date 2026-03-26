import 'package:dio/dio.dart';

/// Maps API / network errors to short Turkish copy for end users (no stack traces).
String userFacingErrorMessage(
  Object? error, {
  String fallback = 'Bir şeyler ters gitti. Lütfen bir süre sonra tekrar dene.',
}) {
  if (error is DioException) {
    return _dioMessage(error, fallback: fallback);
  }
  final raw = error?.toString() ?? '';
  if (_looksLikeNetworkError(raw)) {
    return 'İnternet bağlantısı yok veya sunucuya ulaşılamıyor. Bağlantını kontrol edip tekrar dene.';
  }
  return fallback;
}

bool _looksLikeNetworkError(String raw) {
  final s = raw.toLowerCase();
  return s.contains('xmlhttprequest') ||
      s.contains('connection error') ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection reset');
}

String _dioMessage(DioException e, {required String fallback}) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Bağlantı zaman aşımına uğradı. İnternetini kontrol edip tekrar dene.';
    case DioExceptionType.connectionError:
      return 'İnternet bağlantısı yok veya sunucuya ulaşılamıyor. Wi‑Fi veya mobil verini kontrol edip tekrar dene.';
    case DioExceptionType.badCertificate:
      return 'Güvenli bağlantı kurulamadı. Daha sonra tekrar dene.';
    case DioExceptionType.cancel:
      return 'İstek iptal edildi.';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) {
        return 'Oturumun sona ermiş olabilir. Tekrar giriş yapmayı dene.';
      }
      if (code == 403) {
        return 'Bu içeriğe erişim yetkin yok.';
      }
      if (code == 404) {
        return 'Aradığın içerik bulunamadı.';
      }
      if (code != null && code >= 500) {
        return 'Sunucu şu an yanıt veremiyor. Lütfen bir süre sonra tekrar dene.';
      }
      return 'İstek tamamlanamadı. Tekrar dene.';
    case DioExceptionType.unknown:
      final msg = (e.message ?? '').toLowerCase();
      if (_looksLikeNetworkError(msg) ||
          msg.contains('handshake') ||
          msg.contains('connection closed')) {
        return 'İnternet bağlantısı yok veya sunucuya ulaşılamıyor. Bağlantını kontrol edip tekrar dene.';
      }
      return fallback;
  }
}
