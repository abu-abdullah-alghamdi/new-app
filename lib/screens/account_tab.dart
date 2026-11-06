import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data.dart';
import '../main.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'privacy_screen.dart';
import 'shell.dart';
import 'welcome_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ما قدرنا نفتح الرابط على هذا الجهاز', style: ts(14, color: AppColors.white))),
      );
    }
  }

  void _contact(BuildContext context) {
    final digits = clinicPhone.replaceAll('+', '');
    showAppSheet(
      context,
      title: 'تواصل مع العيادة',
      children: [
        PillButton(
          label: 'اتصال',
          icon: CupertinoIcons.phone_fill,
          bg: AppColors.bg,
          onTap: () => _open(context, Uri.parse('tel:$clinicPhone')),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: 'واتساب',
          icon: CupertinoIcons.chat_bubble_fill,
          bg: AppColors.bg,
          onTap: () => _open(context, Uri.parse('https://wa.me/$digits')),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final s = AppScope.read(context);
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('حذف الحساب؟', style: ts(17, weight: FontWeight.w600)),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('بيتم حذف بياناتك ومواعيدك من التطبيق نهائياً، وما تقدر تتراجع.', style: ts(14, height: 1.5)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء', style: ts(17, weight: FontWeight.w600, color: AppColors.ink)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('حذف', style: ts(17, color: AppColors.red)),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      s.deleteAccount();
      Navigator.of(context).pushAndRemoveUntil(iosRoute(const WelcomeScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final title = s.name.trim().isNotEmpty ? s.name.trim() : (s.loggedIn ? 'أهلاً بك' : 'زائر');
    final sub = s.phone.trim().isNotEmpty ? s.phone.trim() : 'سجّل دخولك عشان تحفظ مواعيدك';

    Widget row(String label, {Widget? trailing, bool divider = true, VoidCallback? onTap, Color? color}) => Pressable(
          onTap: onTap,
          // صف المفتاح يخلي قارئ الشاشة يقرأ حالته (مفعّل/متوقف)
          semanticLabel: trailing == null ? label : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: divider ? Border(bottom: BorderSide(color: AppColors.bg)) : null,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: ts(17, color: color))),
                trailing ?? Icon(CupertinoIcons.forward, size: 18, color: AppColors.faint),
              ],
            ),
          ),
        );

    Widget stat(String n, String label, bool lime) => Expanded(
          child: Pressable(
            onTap: () => s.setTab(1),
            semanticLabel: '$n $label',
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lime ? AppColors.lime : AppColors.white,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n, style: ts(34, color: lime ? AppColors.onAccent : AppColors.ink)),
                  const SizedBox(height: 12),
                  Text(label, style: ts(15, color: lime ? AppColors.onAccent : AppColors.ink)),
                ],
              ),
            ),
          ),
        );

    // المحتوى يمر تحت الساعة والبطارية وهو ينزل (بدون حد يفصلهم)
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 30, 14, navBottomSpace),
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
                  child: Text(s.initial, style: ts(30, weight: FontWeight.w600, color: AppColors.onAccent)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ts(24)),
                      const SizedBox(height: 4),
                      Text(sub, style: ts(15, color: AppColors.body), textDirection: s.phone.isNotEmpty ? TextDirection.ltr : null),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat(ar(s.upcoming.length), 'مواعيد قادمة', true),
              const SizedBox(width: 10),
              stat(ar(s.completedCount), 'زيارات مكتملة', false),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
            child: Column(
              children: [
                row('تذكير المواعيد على واتساب',
                    trailing: AppSwitch(value: s.remindOnWhatsapp, onChanged: s.toggleRemind), onTap: s.toggleRemind),
                row('تواصل مع العيادة', onTap: () => _contact(context)),
                row('سياسة الخصوصية', divider: false, onTap: () => Navigator.of(context).push(iosRoute(const PrivacyScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'تسجيل الخروج',
            bg: AppColors.white,
            fontSize: 17,
            onTap: () {
              s.logout();
              Navigator.of(context).pushAndRemoveUntil(iosRoute(const WelcomeScreen()), (_) => false);
            },
          ),
          const SizedBox(height: 10),
          if (s.loggedIn)
            PillButton(
              label: 'حذف الحساب',
              bg: Colors.transparent,
              fg: AppColors.red,
              fontSize: 16,
              onTap: () => _deleteAccount(context),
            ),
        ],
      ),
    );
  }
}
