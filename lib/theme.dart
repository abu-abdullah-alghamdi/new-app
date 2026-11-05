import 'package:flutter/widgets.dart';

/// ألوان التطبيق بحسب الدور، وتتبدل تلقائياً بين الوضع الفاتح والداكن.
/// (القيم تتحدد من main.dart حسب إعداد الجهاز)
class AppColors {
  static bool dark = false;

  static Color _p(int light, int darkValue) => Color(dark ? darkValue : light);

  /// خلفية الشاشة
  static Color get bg => _p(0xFFEEEEF0, 0xFF0B0B0C);

  /// سطح البطاقات والأزرار البيضاء
  static Color get white => _p(0xFFFFFFFF, 0xFF1C1C1E);

  /// النص الأساسي والأيقونات (أسود في الفاتح، أبيض في الداكن)
  static Color get ink => _p(0xFF000000, 0xFFFFFFFF);
  static Color get body => _p(0xFF333333, 0xFFD1D1D6);
  static Color get title => _p(0xFF3A3A3A, 0xFFE5E5EA);
  static Color get faint => _p(0xFF636366, 0xFFA1A1A6);

  /// اللون الليموني ونصه (دايماً أسود فوق الليموني)
  static const lime = Color(0xFFE3FF3A);
  static const onAccent = Color(0xFF000000);

  /// نص فوق الأحمر
  static const onRed = Color(0xFFFFFFFF);

  static Color get disabled => _p(0xFFDADCE1, 0xFF3A3A3C);
  static Color get disabledText => _p(0xFF5E5E5E, 0xFFB0B0B5);
  static Color get closed => _p(0xFFE2E3E7, 0xFF2C2C2E);
  static Color get closedText => _p(0xFF6A6A6E, 0xFF98989F);
  static Color get green => _p(0xFF13803C, 0xFF34C759);
  static Color get blue => _p(0xFF1F4FD8, 0xFF6EA8FF);
  static Color get red => _p(0xFFB42318, 0xFFFF6B5E);
  static Color get softShadow => _p(0x0F000000, 0x00000000);
  static Color get switchOff => _p(0xFFD5D8DE, 0xFF3A3A3C);

  // الزجاج العائم
  static Color get glassFill => _p(0x8CFAFAFC, 0x8C1C1C1E);
  static Color get glassBorder => _p(0xB3FFFFFF, 0x33FFFFFF);
  static Color get glassActive => _p(0xEBFFFFFF, 0xEB3A3A3C);
  static Color get glassLabel => _p(0xFF4D4D4D, 0xFFC7C7CC);
}

List<BoxShadow> get cardShadow => [
      BoxShadow(color: AppColors.softShadow, blurRadius: 24, offset: const Offset(0, 8)),
    ];

List<BoxShadow> get pillShadow => [
      BoxShadow(color: AppColors.softShadow, blurRadius: 10, offset: const Offset(0, 2)),
    ];

/// مدة الحركة، وتصير صفر إذا المستخدم مفعّل "تقليل الحركة"
Duration motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: ms);

/// هل المستخدم مفعّل "زيادة التباين"؟ (نستخدمه أيضاً بديلاً عن "تقليل الشفافية")
bool highContrast(BuildContext context) => MediaQuery.highContrastOf(context);

/// معامل تكبير الخط للعناصر المضغوطة (الكبسولات والشريط) بحد أقصى ١٫٣
double uiScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(1.0, 1.3);
