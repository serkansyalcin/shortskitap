class ReaderProfileCapabilitiesModel {
  final int maxChildProfiles;
  final int activeChildProfilesCount;
  final bool canCreateChildProfile;
  final bool requiresPremiumForMore;

  const ReaderProfileCapabilitiesModel({
    required this.maxChildProfiles,
    required this.activeChildProfilesCount,
    required this.canCreateChildProfile,
    required this.requiresPremiumForMore,
  });

  const ReaderProfileCapabilitiesModel.defaults()
    : maxChildProfiles = 1,
      activeChildProfilesCount = 0,
      canCreateChildProfile = true,
      requiresPremiumForMore = true;

  factory ReaderProfileCapabilitiesModel.fromJson(Map<String, dynamic> json) {
    return ReaderProfileCapabilitiesModel(
      maxChildProfiles: (json['max_child_profiles'] as num?)?.toInt() ?? 1,
      activeChildProfilesCount:
          (json['active_child_profiles_count'] as num?)?.toInt() ?? 0,
      canCreateChildProfile: json['can_create_child_profile'] != false,
      requiresPremiumForMore: json['requires_premium_for_more'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'max_child_profiles': maxChildProfiles,
    'active_child_profiles_count': activeChildProfilesCount,
    'can_create_child_profile': canCreateChildProfile,
    'requires_premium_for_more': requiresPremiumForMore,
  };
}
