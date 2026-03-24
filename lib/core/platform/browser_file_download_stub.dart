Future<void> downloadBytes({
  required List<int> bytes,
  required String mimeType,
  required String filename,
}) async {
  throw UnsupportedError('Browser download is only available on web.');
}
