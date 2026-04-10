import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Dio _audioDownloadClient = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 90),
    followRedirects: true,
    responseType: ResponseType.bytes,
  ),
);

Future<String?> cacheAudioFile({
  required int bookId,
  required int paragraphId,
  required String audioUrl,
  String? currentLocalPath,
}) async {
  if (currentLocalPath != null &&
      currentLocalPath.isNotEmpty &&
      await File(currentLocalPath).exists()) {
    return currentLocalPath;
  }

  final targetDirectory = await _bookAudioDirectory(bookId);
  await targetDirectory.create(recursive: true);

  final uri = Uri.tryParse(audioUrl);
  final extension = _resolveExtension(uri);
  final filePath = p.join(
    targetDirectory.path,
    'paragraph_$paragraphId$extension',
  );
  final file = File(filePath);

  if (await file.exists()) {
    return file.path;
  }

  try {
    final response = await _audioDownloadClient.get<List<int>>(audioUrl);
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}

Future<void> deleteBookAudioCache(int bookId) async {
  final directory = await _bookAudioDirectory(bookId);
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

Future<bool> localAudioFileExists(String path) async {
  if (path.isEmpty) return false;
  return File(path).exists();
}

Future<Directory> _bookAudioDirectory(int bookId) async {
  final baseDirectory = await getApplicationSupportDirectory();
  return Directory(p.join(baseDirectory.path, 'offline_audio', 'book_$bookId'));
}

String _resolveExtension(Uri? uri) {
  final path = uri?.path ?? '';
  final extension = p.extension(path);
  if (extension.isEmpty) {
    return '.mp3';
  }
  return extension;
}
