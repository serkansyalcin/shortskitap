import 'package:flutter/material.dart';

import 'offline_aware_image_stub.dart'
    if (dart.library.io) 'offline_aware_image_io.dart' as impl;

/// [localPath] doluysa ve dosya varsa yerel görüntü; aksi halde [networkUrl] ile ağ (önbellek).
Widget buildOfflineAwareImage({
  required String? networkUrl,
  required String? localPath,
  required BoxFit fit,
  required Widget placeholder,
  required Widget errorWidget,
  Duration fadeInDuration = const Duration(milliseconds: 200),
}) {
  return impl.buildOfflineAwareImage(
    networkUrl: networkUrl,
    localPath: localPath,
    fit: fit,
    placeholder: placeholder,
    errorWidget: errorWidget,
    fadeInDuration: fadeInDuration,
  );
}
