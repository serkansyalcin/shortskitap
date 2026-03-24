import 'avatar_picker_types.dart';

class _StubAvatarPickerService implements AvatarPickerService {
  @override
  Future<PickedAvatar?> pickFromCamera() async => null;

  @override
  Future<PickedAvatar?> pickFromGallery() async => null;
}

AvatarPickerService createAvatarPickerService() => _StubAvatarPickerService();
