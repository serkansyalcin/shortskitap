import 'package:dio/dio.dart';

/// Maps API / network errors to short Turkish copy for end users.
String userFacingErrorMessage(
  Object? error, {
  String fallback = 'Bir şeyler ters gitti. Lütfen biraz sonra tekrar dene.',
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
        return 'Sunucu şu an yanıt veremiyor. Lütfen biraz sonra tekrar dene.';
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

String apiFormErrorMessage(
  Object? error, {
  String fallback = 'İşlem tamamlanamadı. Tekrar dene.',
}) {
  if (error is DioException) {
    if (error.type != DioExceptionType.badResponse) {
      return userFacingErrorMessage(error, fallback: fallback);
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          final normalized = _normalizeApiMessage(first.first.toString());
          if (normalized != null) return normalized;
        }
        if (first is String) {
          final normalized = _normalizeApiMessage(first);
          if (normalized != null) return normalized;
        }
      }

      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        final normalized = _normalizeApiMessage(msg.trim());
        if (normalized != null) return normalized;
      }
    }

    return fallback;
  }

  return userFacingErrorMessage(error, fallback: fallback);
}

String? _normalizeApiMessage(String raw) {
  final message = raw.trim();
  if (message.isEmpty) return null;

  final compact = message.toLowerCase().replaceAll(' ', '');

  if (compact == 'thegivendatawasinvalid.' ||
      compact == 'validation.failed' ||
      compact == 'validation.invalid') {
    return null;
  }

  if (compact.contains('validation.digits_between') ||
      compact.contains('digitsbetween')) {
    return 'Şifre 4 ile 6 hane arasında olmalı.';
  }
  if (compact.contains('validation.required')) {
    return 'Bu alan zorunludur.';
  }
  if (compact.contains('validation.confirmed')) {
    return 'Girilen bilgiler eşleşmiyor.';
  }
  if (compact.contains('validation.numeric') ||
      compact.contains('validation.digits')) {
    return 'Lütfen yalnızca rakamlardan oluşan bir değer girin.';
  }
  if (compact.contains('validation.min')) {
    return 'Girilen değer çok kısa.';
  }
  if (compact.contains('validation.max')) {
    return 'Girilen değer çok uzun.';
  }
  if (compact.contains('parent_pin') && compact.contains('required')) {
    return 'Lütfen ebeveyn şifresini girin.';
  }

  return message;
}
