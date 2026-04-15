import 'reader_profile_model.dart';
import 'reader_profile_capabilities_model.dart';
import 'user_model.dart';

class AuthSessionModel {
  final UserModel account;
  final List<ReaderProfileModel> profiles;
  final ReaderProfileModel? activeProfile;
  final ReaderProfileCapabilitiesModel profileCapabilities;

  const AuthSessionModel({
    required this.account,
    required this.profiles,
    required this.activeProfile,
    this.profileCapabilities = const ReaderProfileCapabilitiesModel.defaults(),
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final profilesJson =
        json['profiles'] as List<dynamic>? ?? const <dynamic>[];
    final profiles = profilesJson
        .whereType<Map<String, dynamic>>()
        .map(ReaderProfileModel.fromJson)
        .toList(growable: false);

    return AuthSessionModel(
      account: UserModel.fromJson(
        (json['account'] ?? json['user']) as Map<String, dynamic>,
      ),
      profiles: profiles,
      profileCapabilities: json['profile_capabilities'] is Map<String, dynamic>
          ? ReaderProfileCapabilitiesModel.fromJson(
              json['profile_capabilities'] as Map<String, dynamic>,
            )
          : const ReaderProfileCapabilitiesModel.defaults(),
      activeProfile: json['active_profile'] is Map<String, dynamic>
          ? ReaderProfileModel.fromJson(
              json['active_profile'] as Map<String, dynamic>,
            )
          : (profiles.isNotEmpty ? profiles.first : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'account': account.toJson(),
    'profiles': profiles.map((profile) => profile.toJson()).toList(),
    'active_profile': activeProfile?.toJson(),
    'profile_capabilities': profileCapabilities.toJson(),
  };
}
