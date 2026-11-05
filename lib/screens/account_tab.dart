import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';
import 'welcome_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final title = s.name.trim().isNotEmpty ? s.name.trim() : (s.loggedIn ? 'أهلاً بك' : 'زائر');
    final sub = s.phone.trim().isNotEmpty ? s.phone.trim() : 'سجّل دخولك عشان تحفظ مواعيدك';

    Widget row(String label, {Widget? trailing, bool divider = true, VoidCallback? onTap}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              border: divider ? const Border(bottom: BorderSide(color: AppColors.bg)) : null,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: ts(16))),
                trailing ?? const Icon(CupertinoIcons.forward, size: 18, color: AppColors.ink),
              ],
            ),
          ),
        );

    Widget stat(String n, String label, Color bg) => Expanded(
          child: Pressable(
            onTap: () => s.setTab(1),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(34)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(n, style: ts(34)), Text(label, style: ts(15))],
              ),
            ),
          ),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 30, 14, navBottomSpace),
        children: [
          const BigTitle('حسابي'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(46), boxShadow: cardShadow),
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                  child: Text(s.initial, style: ts(30, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ts(24)),
                      const SizedBox(height: 4),
                      Text(sub, style: ts(14, color: AppColors.body), textDirection: s.phone.isNotEmpty ? TextDirection.ltr : null),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat(ar(s.upcoming.length), 'مواعيد قادمة', AppColors.lime),
              const SizedBox(width: 10),
              stat(ar(s.completedCount), 'زيارات مكتملة', AppColors.white),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
            child: Column(
              children: [
                row('تذكير المواعيد على واتساب',
                    trailing: AppSwitch(value: s.remindOnWhatsapp, onChanged: s.toggleRemind), onTap: s.toggleRemind),
                row('اللغة', trailing: Text('العربية', style: ts(14, color: AppColors.body))),
                row('تواصل مع العيادة'),
                row('سياسة الخصوصية', divider: false),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'تسجيل الخروج',
            bg: AppColors.white,
            fg: AppColors.red,
            fontSize: 17,
            onTap: () {
              s.logout();
              Navigator.of(context).pushAndRemoveUntil(iosRoute(const WelcomeScreen()), (_) => false);
            },
          ),
        ],
      ),
    );
  }
}
