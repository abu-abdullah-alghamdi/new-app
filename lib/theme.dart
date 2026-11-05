import 'package:flutter/material.dart';

/// ألوان التطبيق
class AppColors {
  static const bg = Color(0xFFEEEEF0);
  static const ink = Color(0xFF000000);
  static const body = Color(0xFF333333);
  static const title = Color(0xFF3A3A3A);
  static const faint = Color(0xFF6E6E6E);
  static const lime = Color(0xFFE3FF3A);
  static const white = Color(0xFFFFFFFF);
  static const disabled = Color(0xFFDADCE1);
  static const disabledText = Color(0xFF5E5E5E);
  static const closed = Color(0xFFE2E3E7);
  static const closedText = Color(0xFF7E7E7E);
  static const green = Color(0xFF13803C);
  static const blue = Color(0xFF1F4FD8);
  static const red = Color(0xFFB42318);
  static const softShadow = Color(0x0F000000); // أسود بشفافية ~6%
}

const cardShadow = [
  BoxShadow(color: AppColors.softShadow, blurRadius: 24, offset: Offset(0, 8)),
];

const pillShadow = [
  BoxShadow(color: AppColors.softShadow, blurRadius: 10, offset: Offset(0, 2)),
];
