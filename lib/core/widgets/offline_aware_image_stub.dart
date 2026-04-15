import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget buildOfflineAwareImage({
  required String? networkUrl,
  required String? localPath,
  required BoxFit fit,
  required Widget placeholder,
  required Widget errorWidget,
  Duration fadeInDuration = const Duration(milliseconds: 200),
}) {
  final url = networkUrl;
  if (url == null || url.isEmpty) {
    return errorWidget;
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    fadeInDuration: fadeInDuration,
    placeholder: (_, progress) => placeholder,
    errorWidget: (_, error, stackTrace) => errorWidget,
  );
}
