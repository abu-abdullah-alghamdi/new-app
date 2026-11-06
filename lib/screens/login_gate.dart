import 'package:flutter/material.dart';

import '../main.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'phone_screen.dart';

/// قاعدة وحدة: أي حجز أو دفع يحتاج جوال موثّق.
/// لو المستخدم مسجّل يرجّع true على طول، وإلا يطلب منه الدخول ويرجعه لنفس الخطوة
Future<bool> requireLogin(BuildContext context, {String title = 'سجّل دخولك لإكمال الحجز'}) async {
  final s = AppScope.read(context);
  if (s.loggedIn) return true;
  var go = false;
  await showAppSheet(
    context,
    title: title,
    children: [
      Text('رقم جوالك يوصلك عليه التذكير، واختيارك محفوظ', style: ts(15, color: AppColors.body, height: 1.7)),
      const SizedBox(height: 16),
      PillButton(
        label: 'المتابعة برقم الجوال',
        onTap: () {
          go = true;
          Navigator.of(context).pop();
        },
      ),
      const SizedBox(height: 8),
    ],
  );
  if (!go || !context.mounted) return false;
  await Navigator.of(context).push(iosRoute(const PhoneScreen(inside: true), name: loginRouteName));
  return context.mounted && s.loggedIn;
}
