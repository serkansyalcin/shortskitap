import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/daily_quote_model.dart';

final dailyQuoteProvider = FutureProvider<DailyQuoteModel?>((ref) async {
  try {
    final response = await ApiClient.instance.get('/daily-quote');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return DailyQuoteModel.fromJson(response.data['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});
