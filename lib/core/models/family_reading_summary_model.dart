import 'reader_profile_model.dart';

class FamilyReadingSummaryModel {
  const FamilyReadingSummaryModel({
    required this.periodDays,
    required this.periodLabel,
    this.startDate,
    this.endDate,
    required this.totalParagraphs,
    required this.totalMinutes,
    required this.completedBooks,
    required this.activeProfiles,
    required this.profiles,
  });

  factory FamilyReadingSummaryModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] is Map<String, dynamic>
        ? json['period'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final totals = json['totals'] is Map<String, dynamic>
        ? json['totals'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final profiles = (json['profiles'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FamilyReadingProfileStatModel.fromJson)
        .toList(growable: false);

    return FamilyReadingSummaryModel(
      periodDays: (period['days'] as num?)?.toInt() ?? 28,
      periodLabel: period['label'] as String? ?? 'Son 4 hafta',
      startDate: _parseDate(period['start_date']),
      endDate: _parseDate(period['end_date']),
      totalParagraphs: (totals['total_paragraphs'] as num?)?.toInt() ?? 0,
      totalMinutes: (totals['total_minutes'] as num?)?.toInt() ?? 0,
      completedBooks: (totals['completed_books'] as num?)?.toInt() ?? 0,
      activeProfiles: (totals['active_profiles'] as num?)?.toInt() ?? 0,
      profiles: profiles,
    );
  }

  final int periodDays;
  final String periodLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalParagraphs;
  final int totalMinutes;
  final int completedBooks;
  final int activeProfiles;
  final List<FamilyReadingProfileStatModel> profiles;

  List<FamilyReadingProfileStatModel> get activeProfileStats =>
      profiles.where((profile) => profile.hasActivity).toList(growable: false);

  FamilyReadingProfileStatModel? get topReader =>
      activeProfileStats.isEmpty ? null : activeProfileStats.first;

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

class FamilyReadingProfileStatModel {
  const FamilyReadingProfileStatModel({
    required this.profile,
    required this.totalParagraphs,
    required this.totalMinutes,
    required this.completedBooks,
    required this.activeDays,
    this.lastActivityDate,
    required this.heatmap,
  });

  factory FamilyReadingProfileStatModel.fromJson(Map<String, dynamic> json) {
    final rawHeatmap = json['heatmap'] as Map<String, dynamic>? ?? {};
    final heatmap = <String, int>{};
    rawHeatmap.forEach((key, value) {
      heatmap[key] = int.tryParse(value.toString()) ?? 0;
    });

    return FamilyReadingProfileStatModel(
      profile: ReaderProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      totalParagraphs: (json['total_paragraphs'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      completedBooks: (json['completed_books'] as num?)?.toInt() ?? 0,
      activeDays: (json['active_days'] as num?)?.toInt() ?? 0,
      lastActivityDate: FamilyReadingSummaryModel._parseDate(
        json['last_activity_date'],
      ),
      heatmap: heatmap,
    );
  }

  final ReaderProfileModel profile;
  final int totalParagraphs;
  final int totalMinutes;
  final int completedBooks;
  final int activeDays;
  final DateTime? lastActivityDate;
  final Map<String, int> heatmap;

  bool get hasActivity => totalParagraphs > 0 || activeDays > 0;
}
