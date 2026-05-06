import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../models/daily_quote_model.dart';
import '../widgets/shareable_quote_overlay.dart';

class DailyQuoteShareService {
  DailyQuoteShareService._();

  static Future<Uint8List> renderQuoteImage({
    required DailyQuoteModel quote,
    required bool isDark,
  }) {
    return ScreenshotController().captureFromWidget(
      Material(
        child: ShareableQuoteOverlay(quote: quote, isDark: isDark),
      ),
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2,
    );
  }

  static String shareText(DailyQuoteModel quote) {
    final buffer = StringBuffer()
      ..writeln('"${quote.content}"')
      ..writeln();

    final author = quote.book.author?.trim();
    if (author != null && author.isNotEmpty) {
      buffer.writeln('${quote.book.title} - $author');
    } else {
      buffer.writeln(quote.book.title);
    }

    buffer
      ..writeln()
      ..write('KitapLig\'de keşfettiğim bu alıntıya göz at: kitaplig.com');

    return buffer.toString();
  }
}
