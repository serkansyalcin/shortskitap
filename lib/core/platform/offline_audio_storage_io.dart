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

Future<Directory> _bookIllustrationDirectory(int bookId) async {
  final baseDirectory = await getApplicationSupportDirectory();
  return Directory(
    p.join(baseDirectory.path, 'offline_illustrations', 'book_$bookId'),
  );
}

/// Paragraf görselini (CDN URL) yerel dosyaya indirir; çevrimdışı okuma için.
Future<String?> cacheIllustrationFile({
  required int bookId,
  required int paragraphId,
  required String imageUrl,
  String? currentLocalPath,
}) async {
  if (currentLocalPath != null &&
      currentLocalPath.isNotEmpty &&
      await File(currentLocalPath).exists()) {
    return currentLocalPath;
  }

  final targetDirectory = await _bookIllustrationDirectory(bookId);
  await targetDirectory.create(recursive: true);

  final uri = Uri.tryParse(imageUrl);
  final extension = _resolveImageExtension(uri);
  final filePath = p.join(
    targetDirectory.path,
    'paragraph_$paragraphId$extension',
  );
  final file = File(filePath);

  if (await file.exists()) {
    return file.path;
  }

  try {
    final response = await _audioDownloadClient.get<List<int>>(imageUrl);
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

Future<void> deleteBookIllustrationCache(int bookId) async {
  final directory = await _bookIllustrationDirectory(bookId);
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

Future<bool> localIllustrationFileExists(String path) async {
  if (path.isEmpty) return false;
  return File(path).exists();
}

String _resolveImageExtension(Uri? uri) {
  final pathStr = uri?.path ?? '';
  final extension = p.extension(pathStr).toLowerCase();
  const ok = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};
  if (extension.isNotEmpty && ok.contains(extension)) {
    return extension;
  }
  return '.jpg';
}

String _resolveExtension(Uri? uri) {
  final path = uri?.path ?? '';
  final extension = p.extension(path);
  if (extension.isEmpty) {
    return '.mp3';
  }
  return extension;
}
