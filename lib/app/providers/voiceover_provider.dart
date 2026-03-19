import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auto_voiceover_service.dart';

final autoVoiceoverServiceProvider = Provider<AutoVoiceoverService>((ref) {
  final service = AutoVoiceoverService();
  ref.onDispose(service.dispose);
  return service;
});

final voiceoverEnabledProvider = StateProvider<bool>((ref) => false);
