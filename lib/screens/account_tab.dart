import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data.dart';
import '../main.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'favorites_screen.dart';
import 'orders_screen.dart';
import 'phone_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'shell.dart';

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
    // تنبيه آبل الأصلي (iOS 26)
    final result = await CNAlert.show<String>(
      context: context,
      title: 'حذف الحساب؟',
      message: 'بيتم حذف بياناتك ومواعيدك من التطبيق نهائياً، وما تقدر تتراجع',
      actions: const [
        CNAlertAction(label: 'إلغاء', isCancel: true),
        CNAlertAction(label: 'حذف', value: 'delete', isDestructive: true),
      ],
    );
    final yes = result?.value == 'delete';
    if (yes && context.mounted) {
      s.deleteAccount();
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final title = s.name.trim().isNotEmpty ? s.name.trim() : (s.loggedIn ? 'أهلاً بك' : 'زائر');
    final sub = s.phone.trim().isNotEmpty
        ? (s.loggedIn ? displayPhone(s.phone.trim()) : s.phone.trim())
        : 'سجّل دخولك لحفظ مواعيدك';

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

    // العنوان الكبير يتعامل مع الساعة فوق، والـ SafeArea للأطراف بس
    return SafeArea(
      top: false,
      bottom: false,
      child: LargeTitleScroll(
        title: 'حسابي',
        horizontal: 14,
        bottomSpace: navBottomSpace,
        children: [
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
              stat(fmtNum(s.upcoming.length), 'مواعيد قادمة', true),
              const SizedBox(width: 10),
              stat(fmtNum(s.completedCount), 'زيارات مكتملة', false),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
            child: Column(
              children: [
                if (s.loggedIn && s.profile != null)
                  row('معلوماتي الشخصية',
                      onTap: () => Navigator.of(context).push(
                            iosRoute(ProfileScreen(phone: s.profile!.phone, initial: s.profile)),
                          )),
                if (s.loggedIn)
                  row('طلباتي',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.orders.isNotEmpty) Text(fmtNum(s.orders.length), style: ts(16, color: AppColors.faint)),
                          const SizedBox(width: 6),
                          Icon(CupertinoIcons.forward, size: 18, color: AppColors.faint),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(iosRoute(const OrdersScreen()))),
                row('المفضلة', onTap: () => Navigator.of(context).push(iosRoute(const FavoritesScreen()))),
                row('تذكير المواعيد على واتساب',
                    trailing: SizedBox(
                      width: 64,
                      height: 32,
                      // مفتاح آبل الأصلي
                      child: CNSwitch(value: s.remindOnWhatsapp, color: AppColors.ink, onChanged: (_) => s.toggleRemind()),
                    ),
                    onTap: s.toggleRemind),
                row('تواصل مع العيادة', onTap: () => _contact(context)),
                row('سياسة الخصوصية', divider: false, onTap: () => Navigator.of(context).push(iosRoute(const PrivacyScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // فروعنا: مربع واضح، وكل فرع في مربع لحاله
          Container(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Semantics(header: true, child: Text('فروعنا', style: ts(22, weight: FontWeight.w500))),
                ),
                for (final b in branches) ...[
                  _BranchBox(branch: b, onOpen: (uri) => _open(context, uri)),
                  if (b != branches.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (s.loggedIn)
            PillButton(
              label: 'تسجيل الخروج',
              bg: AppColors.white,
              fontSize: 17,
              onTap: () {
                s.logout();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            )
          else
            // الزائر: تسجيل الدخول ثم المعلومات الشخصية، وبعدها يرجع لهذي الصفحة
            PillButton(
              label: 'تسجيل الدخول',
              icon: CupertinoIcons.person_crop_circle,
              fontSize: 17,
              onTap: () => Navigator.of(context).push(
                iosRoute(const PhoneScreen(inside: true), name: loginRouteName),
              ),
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

/// مربع فرع: الاسم، مفتوح/مغلق، الأيام والساعات، الحي، وزرين (اتصال · الاتجاهات)
class _BranchBox extends StatelessWidget {
  const _BranchBox({required this.branch, required this.onOpen});

  final Branch branch;
  final void Function(Uri uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final b = branch;
    final open = b.openAt(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(28),
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(b.name, style: ts(19, weight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: open ? AppColors.green.withAlpha(26) : AppColors.closed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        open ? 'مفتوح الآن' : 'مغلق الآن',
                        style: ts(13, weight: FontWeight.w600, color: open ? AppColors.green : AppColors.closedText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(Branch.hoursText, style: ts(14, color: AppColors.body)),
                const SizedBox(height: 2),
                Text(b.area, style: ts(13, color: AppColors.faint)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'اتصال',
                  icon: CupertinoIcons.phone_fill,
                  height: 48,
                  fontSize: 15,
                  padding: 12,
                  bg: AppColors.white,
                  onTap: () => onOpen(Uri.parse('tel:${b.phone}')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: 'الاتجاهات',
                  icon: CupertinoIcons.location_fill,
                  height: 48,
                  fontSize: 15,
                  padding: 12,
                  bg: AppColors.ink,
                  fg: AppColors.white,
                  onTap: () => onOpen(b.mapsUri),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

