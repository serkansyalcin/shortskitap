import 'dart:typed_data';

class PickedAvatar {
  const PickedAvatar({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

abstract class AvatarPickerService {
  Future<PickedAvatar?> pickFromGallery();
  Future<PickedAvatar?> pickFromCamera();
}
