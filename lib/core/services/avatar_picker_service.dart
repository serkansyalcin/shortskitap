import 'avatar_picker_types.dart';
import 'avatar_picker_service_stub.dart'
    if (dart.library.html) 'avatar_picker_service_web.dart'
    if (dart.library.io) 'avatar_picker_service_mobile.dart' as impl;

AvatarPickerService createAvatarPickerService() =>
    impl.createAvatarPickerService();
