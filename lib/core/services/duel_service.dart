import 'package:kitaplig/core/api/api_client.dart';
import 'package:dio/dio.dart';
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

  Future<DuelActionResult> challenge(int userId) async {
    try {
      final response = await _api.post('/duels/challenge/$userId');
      return DuelActionResult(
        success: response.data['success'] as bool? ?? true,
        message:
            response.data['message']?.toString() ??
            'Düello teklifi gönderildi.',
        duel: _duelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return DuelActionResult(
        success: false,
        message: _messageFromError(
          e,
          fallback: 'Düello teklifi gönderilemedi.',
        ),
        duel: _duelFromPayload(e.response?.data),
      );
    }
  }

  Future<DuelActionResult> accept(int duelId) async {
    try {
      final response = await _api.post('/duels/$duelId/accept');
      return DuelActionResult(
        success: response.data['success'] as bool? ?? true,
        message: response.data['message']?.toString() ?? 'Düello kabul edildi.',
        duel: _duelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return DuelActionResult(
        success: false,
        message: _messageFromError(e, fallback: 'Düello kabul edilemedi.'),
        duel: _duelFromPayload(e.response?.data),
      );
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
        duel: _duelFromPayload(response.data),
      );
    } on DioException catch (e) {
      return DuelActionResult(
        success: false,
        message: _messageFromError(
          e,
          fallback: 'Düello teklifi güncellenemedi.',
        ),
        duel: _duelFromPayload(e.response?.data),
      );
    }
  }

  Future<DuelModel> getDuelDetails(int duelId) async {
    final response = await _api.get('/duels/$duelId');
    return DuelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  DuelModel? _duelFromPayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final duelJson = payload['data'];
    if (duelJson is! Map<String, dynamic>) {
      return null;
    }

    return DuelModel.fromJson(duelJson);
  }

  String _messageFromError(DioException error, {required String fallback}) {
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
