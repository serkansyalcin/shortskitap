import 'reader_profile_model.dart';
import 'user_model.dart';

class AuthSessionModel {
  final UserModel account;
  final List<ReaderProfileModel> profiles;
  final ReaderProfileModel? activeProfile;

  const AuthSessionModel({
    required this.account,
    required this.profiles,
    required this.activeProfile,
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
  };
}
