import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// سياسة الخصوصية (نص تجريبي، يُستبدل بنص العيادة المعتمد قبل النشر)
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    ('البيانات اللي نجمعها', 'اسمك ورقم جوالك وتفاصيل مواعيدك فقط، عشان نحجز لك ونرسل التذكيرات.'),
    ('كيف نستخدمها', 'لإدارة مواعيدك في العيادة وإرسال تذكير قبل الموعد. ما نرسل لك عروض إلا إذا وافقت عليها بشكل منفصل.'),
    ('مشاركة البيانات', 'ما نبيع بياناتك ولا نشاركها مع أي جهة خارج العيادة، إلا إذا طلب نظام ذلك.'),
    ('الحفظ والحماية', 'بياناتك محفوظة داخل المملكة ومشفّرة، ويوصل لها موظفو العيادة المخولين فقط.'),
    ('حقوقك', 'تقدر تطلب نسخة من بياناتك أو تعديلها، وتقدر تحذف حسابك في أي وقت من صفحة "حسابي".'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
            const SizedBox(height: 18),
            const BigTitle('سياسة\nالخصوصية', size: 38),
            const SizedBox(height: 16),
            for (final (title, body) in _sections)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(title, style: ts(18, weight: FontWeight.w600))),
                    const SizedBox(height: 6),
                    Text(body, style: ts(16, color: AppColors.body, height: 1.7)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
