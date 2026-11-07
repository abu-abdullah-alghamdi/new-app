import 'package:flutter/widgets.dart';

/// ألوان التطبيق بحسب الدور (التطبيق فاتح دايماً)
abstract final class AppColors {
  /// خلفية الشاشة
  static const bg = Color(0xFFEEEEF0);

  /// سطح البطاقات والأزرار البيضاء
  static const white = Color(0xFFFFFFFF);

  /// النص الأساسي والأيقونات
  static const ink = Color(0xFF000000);
  static const body = Color(0xFF333333);
  static const title = Color(0xFF3A3A3A);
  static const faint = Color(0xFF636366);

  /// اللون الليموني ونصه (دايماً أسود فوق الليموني)
  static const lime = Color(0xFFE3FF3A);
  static const onAccent = Color(0xFF000000);

  /// نص فوق الأحمر
  static const onRed = Color(0xFFFFFFFF);

  static const disabled = Color(0xFFDADCE1);
  static const disabledText = Color(0xFF5E5E5E);
  static const closed = Color(0xFFE2E3E7);
  static const closedText = Color(0xFF6A6A6E);
  static const green = Color(0xFF13803C);
  static const blue = Color(0xFF1F4FD8);
  static const red = Color(0xFFB42318);
  static const softShadow = Color(0x0F000000);
}

const cardShadow = [BoxShadow(color: AppColors.softShadow, blurRadius: 16, offset: Offset(0, 6))];

const pillShadow = [BoxShadow(color: AppColors.softShadow, blurRadius: 10, offset: Offset(0, 2))];

/// مدة الحركة، وتصير صفر إذا المستخدم مفعّل "تقليل الحركة"
Duration motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: ms);

/// هل المستخدم مفعّل "زيادة التباين"؟ (نستخدمه أيضاً بديلاً عن "تقليل الشفافية")
bool highContrast(BuildContext context) => MediaQuery.highContrastOf(context);

/// معامل تكبير الخط للعناصر المضغوطة (الكبسولات والصفوف الأفقية) يتبع إعداد الجوال لين الضعف
double uiScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(1.0, 2.0);
