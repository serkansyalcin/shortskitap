import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/platform/platform_support.dart';
import '../../../core/services/feedback_service.dart';
import '../widgets/star_rating_widget.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _service = FeedbackService();
  final _messageController = TextEditingController();

  String _packageName = 'com.kitaplig.app';
  String _selectedType = 'general';
  int _rating = 0;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  static const _types = [
    ('general', 'Genel', Icons.chat_bubble_outline_rounded),
    ('suggestion', 'Öneri', Icons.lightbulb_outline_rounded),
    ('bug_report', 'Hata Bildirimi', Icons.bug_report_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadPackageName();
  }

  Future<void> _loadPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted || info.packageName.isEmpty) return;
      setState(() => _packageName = info.packageName);
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _requestStoreReview() async {
    if (!PlatformSupport.isMobileNative) return;
    final inAppReview = InAppReview.instance;
    try {
      await inAppReview.openStoreListing();
      return;
    } catch (_) {
      // Mağaza diyaloğu açılamazsa sessizce devam et
    }
  }

  Future<void> _openStoreListingDirect() async {
    if (!PlatformSupport.isMobileNative) return;

    final inAppReview = InAppReview.instance;
    try {
      await inAppReview.openStoreListing();
      return;
    } catch (_) {}

    if (PlatformSupport.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$_packageName');
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$_packageName',
      );
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Lütfen bir mesaj yazın.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.submit(
        type: _selectedType,
        message: message,
        rating: _rating > 0 ? _rating : null,
      );
      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gönderim sırasında bir hata oluştu. Lütfen tekrar deneyin.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : const Color(0xFFF8FAF7);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final outlineColor = isDark ? AppColors.outline : AppColors.lightOutline;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Geri Bildirim',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _submitted ? _buildSuccess(textColor, secondaryText) : _buildForm(
        surfaceColor: surfaceColor,
        textColor: textColor,
        secondaryText: secondaryText,
        outlineColor: outlineColor,
        isDark: isDark,
      ),
    );
  }

  Widget _buildSuccess(Color textColor, Color secondaryText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Teşekkürler!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Geri bildiriminiz başarıyla alındı.\nGörüşleriniz uygulamamızı daha iyi hale getirmemize yardımcı oluyor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: secondaryText, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({
    required Color surfaceColor,
    required Color textColor,
    required Color secondaryText,
    required Color outlineColor,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mağaza değerlendirme kartı
          if (PlatformSupport.isMobileNative) ...[
            _buildStoreRatingCard(surfaceColor, textColor, secondaryText, outlineColor),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: outlineColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'veya görüşlerinizi yazın',
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ),
                Expanded(child: Divider(color: outlineColor)),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Geri bildirim tipi
          Text(
            'Bildirim türü',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _types.map((t) {
              final (value, label, icon) = t;
              final selected = _selectedType == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = value),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : outlineColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          color: selected ? AppColors.primary : secondaryText,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Yıldız puanlama
          Text(
            'Puan ver (isteğe bağlı)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          StarRatingWidget(
            rating: _rating,
            onRatingChanged: (v) => setState(() => _rating = v),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Mesaj
          Text(
            'Mesajınız',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 2000,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Görüşlerinizi, önerilerinizi veya karşılaştığınız sorunu buraya yazın...',
                hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(color: secondaryText, fontSize: 11),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gönder',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStoreRatingCard(
    Color surfaceColor,
    Color textColor,
    Color secondaryText,
    Color outlineColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF75B43E), Color(0xFF53802C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bizi değerlendirin!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'App Store veya Google Play\'de puan verin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openStoreListingDirect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mağazada Değerlendir',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Çok kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Mükemmel';
      default:
        return '';
    }
  }
}
