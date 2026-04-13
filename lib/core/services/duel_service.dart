import 'package:kitaplig/core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kitaplig/core/models/duel_model.dart';

class DuelService {
  final ApiClient _api;
  DuelService(this._api);

  Future<List<DuelModel>> getMyDuels() async {
    final response = await _api.get('/duels/me');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => DuelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DuelActionResult> challenge(
    int userId, {
    int? opponentReaderProfileId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (opponentReaderProfileId != null) {
        data['opponent_reader_profile_id'] = opponentReaderProfileId;
      }

      final response = await _api.post(
        '/duels/challenge/$userId',
        data: data.isEmpty ? null : data,
      );
      return DuelActionResult(
        success: response.data['success'] as bool? ?? true,
        message:
            response.data['message']?.toString() ??
            'Düello teklifi gönderildi.',
        duel: tryParseDuelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return actionResultFromError(
        e,
        fallback: 'Düello teklifi gönderilemedi.',
      );
    }
  }

  Future<DuelActionResult> accept(int duelId) async {
    try {
      final response = await _api.post('/duels/$duelId/accept');
      return DuelActionResult(
        success: response.data['success'] as bool? ?? true,
        message: response.data['message']?.toString() ?? 'Düello kabul edildi.',
        duel: tryParseDuelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return actionResultFromError(e, fallback: 'Düello kabul edilemedi.');
    }
  }

  Future<DuelActionResult> decline(int duelId) async {
    try {
      final response = await _api.post('/duels/$duelId/decline');
      return DuelActionResult(
        success: response.data['success'] as bool? ?? true,
        message:
            response.data['message']?.toString() ??
            'Düello teklifi güncellendi.',
        duel: tryParseDuelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return actionResultFromError(
        e,
        fallback: 'Düello teklifi güncellenemedi.',
      );
    }
  }

  Future<DuelModel> getDuelDetails(int duelId) async {
    final response = await _api.get('/duels/$duelId');
    return DuelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @visibleForTesting
  static DuelModel? tryParseDuelFromPayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final duelJson = payload['data'];
    if (duelJson is! Map<String, dynamic>) {
      return null;
    }

    try {
      return DuelModel.fromJson(duelJson);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @visibleForTesting
  static DuelActionResult actionResultFromError(
    DioException error, {
    required String fallback,
  }) {
    return DuelActionResult(
      success: false,
      message: _messageFromError(error, fallback: fallback),
      duel: tryParseDuelFromPayload(error.response?.data),
    );
  }

  static String _messageFromError(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null) {
        return message.toString();
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }

    return fallback;
  }
}
