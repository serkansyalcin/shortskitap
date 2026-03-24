import 'package:image_picker/image_picker.dart';

import 'avatar_picker_types.dart';

class _MobileAvatarPickerService implements AvatarPickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedAvatar?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (file == null) return null;

    return PickedAvatar(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );
  }

  @override
  Future<PickedAvatar?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (file == null) return null;

    return PickedAvatar(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );
  }
}

AvatarPickerService createAvatarPickerService() => _MobileAvatarPickerService();
