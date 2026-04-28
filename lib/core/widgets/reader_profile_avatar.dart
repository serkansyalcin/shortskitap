import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum ReaderProfileAvatarCharacter {
  pigtailGirl,
  cheerfulBoy,
  curlyGirl,
  bookishBoy,
  bobGirl,
  playfulBoy,
}

class ReaderProfileAvatarPreset {
  const ReaderProfileAvatarPreset({
    required this.token,
    required this.label,
    required this.character,
    required this.backgroundStartColor,
    required this.backgroundEndColor,
    required this.decorationColor,
    required this.skinColor,
    required this.hairColor,
    required this.shirtColor,
    required this.accentColor,
  });

  final String token;
  final String label;
  final ReaderProfileAvatarCharacter character;
  final Color backgroundStartColor;
  final Color backgroundEndColor;
  final Color decorationColor;
  final Color skinColor;
  final Color hairColor;
  final Color shirtColor;
  final Color accentColor;
}

class ReaderProfileAvatarCatalog {
  static const String defaultPrefix = 'reader-avatar://default/';

  static const List<ReaderProfileAvatarPreset> presets =
      <ReaderProfileAvatarPreset>[
        ReaderProfileAvatarPreset(
          token: 'fox',
          label: 'Mina',
          character: ReaderProfileAvatarCharacter.pigtailGirl,
          backgroundStartColor: Color(0xFFFFD6C8),
          backgroundEndColor: Color(0xFFFFF0D4),
          decorationColor: Color(0xFFFFE2DA),
          skinColor: Color(0xFFF6C39C),
          hairColor: Color(0xFF7A3E1D),
          shirtColor: Color(0xFFF97393),
          accentColor: Color(0xFFEF476F),
        ),
        ReaderProfileAvatarPreset(
          token: 'star',
          label: 'Efe',
          character: ReaderProfileAvatarCharacter.cheerfulBoy,
          backgroundStartColor: Color(0xFFE0EEFF),
          backgroundEndColor: Color(0xFFF8EED8),
          decorationColor: Color(0xFFD6E7FF),
          skinColor: Color(0xFFF0C7A6),
          hairColor: Color(0xFF5B3B2E),
          shirtColor: Color(0xFF4D8BF5),
          accentColor: Color(0xFF2D6AE3),
        ),
        ReaderProfileAvatarPreset(
          token: 'planet',
          label: 'Defne',
          character: ReaderProfileAvatarCharacter.curlyGirl,
          backgroundStartColor: Color(0xFFDDF5D0),
          backgroundEndColor: Color(0xFFF6F6D7),
          decorationColor: Color(0xFFEAF8E2),
          skinColor: Color(0xFFD8996D),
          hairColor: Color(0xFF4B2E22),
          shirtColor: Color(0xFF7BC96F),
          accentColor: Color(0xFF2F855A),
        ),
        ReaderProfileAvatarPreset(
          token: 'leaf',
          label: 'Aras',
          character: ReaderProfileAvatarCharacter.bookishBoy,
          backgroundStartColor: Color(0xFFFFE2CF),
          backgroundEndColor: Color(0xFFFFF4E1),
          decorationColor: Color(0xFFFFEADB),
          skinColor: Color(0xFFEAB68C),
          hairColor: Color(0xFF2E4057),
          shirtColor: Color(0xFF3FB6A8),
          accentColor: Color(0xFF2A9D8F),
        ),
        ReaderProfileAvatarPreset(
          token: 'rocket',
          label: 'Elif',
          character: ReaderProfileAvatarCharacter.bobGirl,
          backgroundStartColor: Color(0xFFF5D7FF),
          backgroundEndColor: Color(0xFFFFEDF6),
          decorationColor: Color(0xFFF9E0FF),
          skinColor: Color(0xFFF1C39C),
          hairColor: Color(0xFF2C1E3F),
          shirtColor: Color(0xFFB779E3),
          accentColor: Color(0xFF8E59D1),
        ),
        ReaderProfileAvatarPreset(
          token: 'cloud',
          label: 'Can',
          character: ReaderProfileAvatarCharacter.playfulBoy,
          backgroundStartColor: Color(0xFFD9F4FF),
          backgroundEndColor: Color(0xFFE8FBE4),
          decorationColor: Color(0xFFD8F7F6),
          skinColor: Color(0xFFF0C39B),
          hairColor: Color(0xFF4C2F27),
          shirtColor: Color(0xFFFFA94D),
          accentColor: Color(0xFF1E8878),
        ),
      ];

  static String tokenValue(String token) => '$defaultPrefix$token';

  static String tokenValueAt(int index) {
    final normalizedIndex = index % presets.length;
    return tokenValue(presets[normalizedIndex].token);
  }

  static String suggestedTokenValue({int? index, String? seedText}) {
    if (index != null) {
      return tokenValueAt(index.abs());
    }

    if (seedText != null && seedText.trim().isNotEmpty) {
      final hash = seedText.trim().runes.fold<int>(
        0,
        (value, rune) => value + rune,
      );
      return tokenValueAt(hash);
    }

    return tokenValueAt(0);
  }

  static bool isDefaultAvatar(String? value) =>
      value != null && value.startsWith(defaultPrefix);

  static ReaderProfileAvatarPreset? presetForValue(String? value) {
    if (!isDefaultAvatar(value)) return null;
    final token = value!.substring(defaultPrefix.length);
    for (final preset in presets) {
      if (preset.token == token) return preset;
    }
    return null;
  }
}

class ReaderProfileAvatar extends StatelessWidget {
  const ReaderProfileAvatar({
    super.key,
    required this.name,
    this.avatarRef,
    this.memoryBytes,
    this.size = 72,
    this.borderRadius,
  });

  final String name;
  final String? avatarRef;
  final Uint8List? memoryBytes;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.3);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: _buildChild(context)),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (memoryBytes != null) {
      return Image.memory(memoryBytes!, fit: BoxFit.cover);
    }

    final preset = ReaderProfileAvatarCatalog.presetForValue(avatarRef);
    if (preset != null) {
      return _PresetAvatarTile(preset: preset);
    }

    if (ReaderProfileAvatarCatalog.isDefaultAvatar(avatarRef)) {
      return _InitialFallback(name: name, size: size);
    }

    if (avatarRef != null && avatarRef!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarRef!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _InitialFallback(name: name, size: size),
      );
    }

    return _InitialFallback(name: name, size: size);
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim()[0].toUpperCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF75B43E).withValues(alpha: 0.14),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF75B43E),
          ),
        ),
      ),
    );
  }
}

class _PresetAvatarTile extends StatelessWidget {
  const _PresetAvatarTile({required this.preset});

  final ReaderProfileAvatarPreset preset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ReaderProfileAvatarPainter(preset));
  }
}

class _ReaderProfileAvatarPainter extends CustomPainter {
  const _ReaderProfileAvatarPainter(this.preset);

  final ReaderProfileAvatarPreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    const rect = Rect.fromLTWH(0, 0, 100, 100);
    final clipRRect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [preset.backgroundStartColor, preset.backgroundEndColor],
      ).createShader(rect);
    canvas.drawRRect(clipRRect, backgroundPaint);

    canvas.save();
    canvas.clipRRect(clipRRect);

    _paintBackdrop(canvas);
    _paintBody(canvas);
    _paintHairBack(canvas);
    _paintFace(canvas);
    _paintHairFront(canvas);
    _paintAccessory(canvas);
    _paintFaceDetails(canvas);

    canvas.restore();
    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    var blobPaint = Paint()..color = preset.decorationColor;
    canvas.drawCircle(const Offset(18, 18), 16, blobPaint);
    canvas.drawCircle(const Offset(82, 82), 18, blobPaint);
    blobPaint = Paint()..color = _soften(preset.decorationColor, 0.12);
    canvas.drawCircle(const Offset(76, 24), 11, blobPaint);

    final accentPaint = Paint()
      ..color = preset.accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(12, 72), 7, accentPaint);
    canvas.drawCircle(const Offset(84, 14), 5, accentPaint);
  }

  void _paintBody(Canvas canvas) {
    final bodyPaint = Paint()..color = preset.shirtColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 66, 56, 38),
        const Radius.circular(24),
      ),
      bodyPaint,
    );

    final collarPaint = Paint()..color = _soften(preset.shirtColor, 0.18);
    final collarPath = Path()
      ..moveTo(39, 66)
      ..quadraticBezierTo(50, 75, 61, 66)
      ..lineTo(55, 66)
      ..quadraticBezierTo(50, 71, 45, 66)
      ..close();
    canvas.drawPath(collarPath, collarPaint);

    final neckPaint = Paint()..color = _shade(preset.skinColor, 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 58, 10, 12),
        const Radius.circular(5),
      ),
      neckPaint,
    );
  }

  void _paintFace(Canvas canvas) {
    final skinPaint = Paint()..color = preset.skinColor;
    canvas.drawCircle(const Offset(31, 43), 4.5, skinPaint);
    canvas.drawCircle(const Offset(69, 43), 4.5, skinPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 43), width: 36, height: 40),
      skinPaint,
    );

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A8A).withValues(alpha: 0.22);
    canvas.drawCircle(const Offset(39, 48), 3.7, blushPaint);
    canvas.drawCircle(const Offset(61, 48), 3.7, blushPaint);
  }

  void _paintHairBack(Canvas canvas) {
    final hairPaint = Paint()..color = preset.hairColor;

    switch (preset.character) {
      case ReaderProfileAvatarCharacter.pigtailGirl:
        canvas.drawCircle(const Offset(24, 39), 10, hairPaint);
        canvas.drawCircle(const Offset(76, 39), 10, hairPaint);
        canvas.drawArc(
          const Rect.fromLTWH(28, 18, 44, 28),
          3.14,
          3.14,
          true,
          hairPaint,
        );
      case ReaderProfileAvatarCharacter.cheerfulBoy:
        canvas.drawArc(
          const Rect.fromLTWH(29, 18, 42, 22),
          3.14,
          3.14,
          true,
          hairPaint,
        );
      case ReaderProfileAvatarCharacter.curlyGirl:
        for (final offset in const <Offset>[
          Offset(28, 32),
          Offset(38, 22),
          Offset(50, 19),
          Offset(62, 22),
          Offset(72, 32),
        ]) {
          canvas.drawCircle(offset, 7.5, hairPaint);
        }
      case ReaderProfileAvatarCharacter.bookishBoy:
        canvas.drawArc(
          const Rect.fromLTWH(28, 18, 44, 24),
          3.14,
          3.14,
          true,
          hairPaint,
        );
      case ReaderProfileAvatarCharacter.bobGirl:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 19, 40, 35),
            const Radius.circular(18),
          ),
          hairPaint,
        );
      case ReaderProfileAvatarCharacter.playfulBoy:
        final spikePath = Path()
          ..moveTo(30, 34)
          ..lineTo(38, 20)
          ..lineTo(46, 32)
          ..lineTo(54, 18)
          ..lineTo(62, 32)
          ..lineTo(70, 21)
          ..lineTo(72, 36)
          ..close();
        canvas.drawPath(spikePath, hairPaint);
    }
  }

  void _paintHairFront(Canvas canvas) {
    final hairPaint = Paint()..color = preset.hairColor;

    switch (preset.character) {
      case ReaderProfileAvatarCharacter.pigtailGirl:
        final bangs = Path()
          ..moveTo(34, 31)
          ..quadraticBezierTo(40, 24, 48, 27)
          ..quadraticBezierTo(53, 22, 60, 25)
          ..quadraticBezierTo(66, 27, 67, 34)
          ..lineTo(66, 38)
          ..quadraticBezierTo(58, 33, 50, 36)
          ..quadraticBezierTo(43, 33, 34, 38)
          ..close();
        canvas.drawPath(bangs, hairPaint);
      case ReaderProfileAvatarCharacter.cheerfulBoy:
        final fringe = Path()
          ..moveTo(33, 31)
          ..quadraticBezierTo(44, 22, 58, 25)
          ..quadraticBezierTo(67, 27, 69, 36)
          ..quadraticBezierTo(59, 33, 51, 36)
          ..quadraticBezierTo(43, 32, 33, 36)
          ..close();
        canvas.drawPath(fringe, hairPaint);
      case ReaderProfileAvatarCharacter.curlyGirl:
        final fringe = Path()
          ..moveTo(35, 33)
          ..quadraticBezierTo(43, 25, 50, 28)
          ..quadraticBezierTo(57, 24, 65, 33)
          ..lineTo(65, 37)
          ..quadraticBezierTo(50, 34, 35, 37)
          ..close();
        canvas.drawPath(fringe, hairPaint);
      case ReaderProfileAvatarCharacter.bookishBoy:
        final crop = Path()
          ..moveTo(32, 30)
          ..quadraticBezierTo(41, 22, 56, 24)
          ..quadraticBezierTo(68, 25, 69, 36)
          ..quadraticBezierTo(59, 35, 50, 37)
          ..quadraticBezierTo(42, 34, 32, 36)
          ..close();
        canvas.drawPath(crop, hairPaint);
      case ReaderProfileAvatarCharacter.bobGirl:
        final bangs = Path()
          ..moveTo(33, 31)
          ..quadraticBezierTo(42, 23, 50, 27)
          ..quadraticBezierTo(59, 23, 67, 31)
          ..lineTo(67, 39)
          ..quadraticBezierTo(50, 34, 33, 39)
          ..close();
        canvas.drawPath(bangs, hairPaint);
      case ReaderProfileAvatarCharacter.playfulBoy:
        final fringe = Path()
          ..moveTo(34, 31)
          ..lineTo(41, 24)
          ..lineTo(46, 31)
          ..lineTo(54, 23)
          ..lineTo(59, 31)
          ..lineTo(66, 26)
          ..lineTo(67, 38)
          ..quadraticBezierTo(50, 34, 34, 38)
          ..close();
        canvas.drawPath(fringe, hairPaint);
    }
  }

  void _paintAccessory(Canvas canvas) {
    switch (preset.character) {
      case ReaderProfileAvatarCharacter.pigtailGirl:
        var bowPaint = Paint()..color = preset.accentColor;
        canvas.drawCircle(const Offset(65, 22), 4.5, bowPaint);
        canvas.drawCircle(const Offset(73, 22), 4.5, bowPaint);
        bowPaint = Paint()..color = _soften(preset.accentColor, 0.25);
        canvas.drawCircle(const Offset(69, 23), 2.2, bowPaint);
      case ReaderProfileAvatarCharacter.curlyGirl:
        final clipPaint = Paint()..color = preset.accentColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(61, 27, 10, 4),
            const Radius.circular(3),
          ),
          clipPaint,
        );
      case ReaderProfileAvatarCharacter.bookishBoy:
        final glassesPaint = Paint()
          ..color = _shade(preset.hairColor, 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1;
        canvas.drawCircle(const Offset(42, 43), 5.5, glassesPaint);
        canvas.drawCircle(const Offset(58, 43), 5.5, glassesPaint);
        canvas.drawLine(
          const Offset(47.5, 43),
          const Offset(52.5, 43),
          glassesPaint,
        );
      case ReaderProfileAvatarCharacter.bobGirl:
        final starPaint = Paint()..color = preset.accentColor;
        final star = Path()
          ..moveTo(70, 23)
          ..lineTo(71.8, 27.5)
          ..lineTo(76.7, 27.8)
          ..lineTo(72.8, 30.8)
          ..lineTo(74.2, 35.5)
          ..lineTo(70, 32.8)
          ..lineTo(65.8, 35.5)
          ..lineTo(67.2, 30.8)
          ..lineTo(63.3, 27.8)
          ..lineTo(68.2, 27.5)
          ..close();
        canvas.drawPath(star, starPaint);
      case ReaderProfileAvatarCharacter.playfulBoy:
        final badgePaint = Paint()..color = preset.accentColor;
        canvas.drawCircle(const Offset(67, 71), 4.5, badgePaint);
      case ReaderProfileAvatarCharacter.cheerfulBoy:
        break;
    }
  }

  void _paintFaceDetails(Canvas canvas) {
    final eyePaint = Paint()..color = const Color(0xFF2D241E);
    canvas.drawCircle(const Offset(43, 43), 1.8, eyePaint);
    canvas.drawCircle(const Offset(57, 43), 1.8, eyePaint);

    final mouthPaint = Paint()
      ..color = const Color(0xFF9F4A3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(44, 47, 12, 8),
      0.2,
      2.7,
      false,
      mouthPaint,
    );

    final nosePaint = Paint()
      ..color = _shade(preset.skinColor, 0.12)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 44.5), const Offset(50, 47), nosePaint);
  }

  Color _soften(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  Color _shade(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  @override
  bool shouldRepaint(covariant _ReaderProfileAvatarPainter oldDelegate) {
    return oldDelegate.preset != preset;
  }
}
