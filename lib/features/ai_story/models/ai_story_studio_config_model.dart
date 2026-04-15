import 'ai_quota_model.dart';
import 'ai_story_generation_model.dart';
import 'ai_story_option_model.dart';

class AiStoryStudioConfigModel {
  final AiQuotaModel quota;
  final List<AiStoryOptionModel> types;
  final List<AiStoryOptionModel> visibilityOptions;
  final String defaultVisibility;
  final bool isChild;
  final bool publicRequiresParentPin;
  final bool forcesPrivateByDefault;
  final AiStoryGenerationModel? activeGeneration;

  const AiStoryStudioConfigModel({
    required this.quota,
    required this.types,
    required this.visibilityOptions,
    required this.defaultVisibility,
    required this.isChild,
    required this.publicRequiresParentPin,
    required this.forcesPrivateByDefault,
    this.activeGeneration,
  });

  factory AiStoryStudioConfigModel.fromJson(Map<String, dynamic> json) {
    final rules = json['child_mode_rules'] as Map<String, dynamic>? ?? const {};
    return AiStoryStudioConfigModel(
      quota: AiQuotaModel.fromJson(json['quota'] as Map<String, dynamic>? ?? {}),
      types: (json['types'] as List<dynamic>? ?? const [])
          .map((item) => AiStoryOptionModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      visibilityOptions:
          (json['visibility_options'] as List<dynamic>? ?? const [])
              .map(
                (item) => AiStoryOptionModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
      defaultVisibility: json['default_visibility'] as String? ?? 'private',
      isChild: rules['is_child'] == true,
      publicRequiresParentPin: rules['public_requires_parent_pin'] == true,
      forcesPrivateByDefault: rules['forces_private_by_default'] == true,
      activeGeneration: json['active_generation'] != null
          ? AiStoryGenerationModel.fromJson(
              json['active_generation'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
