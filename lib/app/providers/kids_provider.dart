import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/kids_mode_pin_service.dart';

final kidsModeProvider = StateProvider<bool>((ref) => false);

final kidsModePinServiceProvider = FutureProvider<KidsModePinService>((ref) async {
  return KidsModePinService.create();
});
