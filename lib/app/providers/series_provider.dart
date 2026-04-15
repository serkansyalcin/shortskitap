import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/series_model.dart';
import '../../core/services/series_service.dart';

final seriesServiceProvider = Provider<SeriesService>((ref) => SeriesService());

final seriesListProvider = FutureProvider<List<SeriesModel>>((ref) {
  return ref.read(seriesServiceProvider).getSeries();
});

final seriesDetailProvider = FutureProvider.family<SeriesModel, int>((ref, id) {
  return ref.read(seriesServiceProvider).getSeriesDetail(id);
});
