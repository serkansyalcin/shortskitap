// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'avatar_picker_types.dart';

class _WebAvatarPickerService implements AvatarPickerService {
  @override
  Future<PickedAvatar?> pickFromGallery() => _pickImage(capture: false);

  @override
  Future<PickedAvatar?> pickFromCamera() => _pickImage(capture: true);

  Future<PickedAvatar?> _pickImage({required bool capture}) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    if (capture) {
      input.setAttribute('capture', 'environment');
    }

    final completer = Completer<PickedAvatar?>();
    input.onChange.first.then((_) async {
      final file = input.files?.isNotEmpty == true ? input.files!.first : null;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(
          PickedAvatar(bytes: result.asUint8List(), fileName: file.name),
        );
        return;
      }

      if (result is Uint8List) {
        completer.complete(PickedAvatar(bytes: result, fileName: file.name));
        return;
      }

      completer.complete(null);
    });

    input.click();
    return completer.future;
  }
}

AvatarPickerService createAvatarPickerService() => _WebAvatarPickerService();
