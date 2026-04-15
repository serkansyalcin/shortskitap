class AiStoryOptionModel {
  final String value;
  final String label;
  final String description;
  final bool isAdult;
  final bool isPublicAllowed;

  const AiStoryOptionModel({
    required this.value,
    required this.label,
    required this.description,
    this.isAdult = false,
    this.isPublicAllowed = true,
  });

  factory AiStoryOptionModel.fromJson(Map<String, dynamic> json) =>
      AiStoryOptionModel(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isAdult: json['is_adult'] == true,
        isPublicAllowed: json['is_public_allowed'] != false,
      );
}
