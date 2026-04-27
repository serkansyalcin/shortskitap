import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/models/family_reading_summary_model.dart';
import '../../core/services/auth_service.dart';
import 'auth_provider.dart';

final familyReadingSummaryProvider =
    FutureProvider.autoDispose<FamilyReadingSummaryModel?>((ref) async {
      final auth = ref.watch(authProvider);
      if (!auth.isAuthenticated || auth.activeProfile?.isParent != true) {
        return null;
      }

      try {
        return AuthService().getFamilyReadingSummary();
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Okuma özeti alınamadı.';

        if (data is Map<String, dynamic>) {
          final apiMessage = data['message']?.toString().trim();
          final apiCode = data['code']?.toString().trim();

          if (apiMessage != null && apiMessage.isNotEmpty) {
            message = apiMessage;
          } else if (apiCode != null && apiCode.isNotEmpty) {
            message = apiCode;
          }
        } else if ((error.message ?? '').trim().isNotEmpty) {
          message = error.message!.trim();
        }

        if (statusCode != null) {
          throw StateError('[$statusCode] $message');
        }

        throw StateError(message);
      } on TypeError {
        throw StateError('Aile özeti verisi şu anda işlenemedi.');
      } on FormatException {
        throw StateError('Aile özeti verisi şu anda işlenemedi.');
      } catch (error) {
        throw StateError(error.toString());
      }
    });
