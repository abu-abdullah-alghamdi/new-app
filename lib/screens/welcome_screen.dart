import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'phone_screen.dart';
import 'shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _guest(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(iosRoute(const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 60),
              child: IntrinsicHeight(
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.ink, width: 3.5),
                    ),
                    child: const Icon(Icons.add_rounded, size: 26, color: AppColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Text('عيادات أريام', style: ts(27, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 56),
              Text('أهلاً بعودتك', textAlign: TextAlign.center, style: ts(32)),
              const SizedBox(height: 10),
              Text(
                'سجّل دخولك عشان تحجز مواعيدك، وتتابع زياراتك، وتوصلك التذكيرات. كل شي في مكان واحد.',
                textAlign: TextAlign.center,
                style: ts(15, color: AppColors.body, height: 1.8),
              ),
              const SizedBox(height: 30),
              PillButton(
                label: 'التسجيل برقم الجوال',
                icon: Icons.phone_rounded,
                height: 66,
                onTap: () => Navigator.of(context).push(iosRoute(const PhoneScreen())),
              ),
              const SizedBox(height: 10),
              PillButton(
                label: 'التسجيل بالبريد الإلكتروني',
                icon: Icons.mail_rounded,
                bg: AppColors.white,
                weight: FontWeight.w400,
                height: 66,
                onTap: () => _guest(context),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFA0A0A0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('أو', style: ts(16, color: AppColors.faint)),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFA0A0A0))),
                ],
              ),
              const SizedBox(height: 14),
              Text('عندك حساب من قبل؟', textAlign: TextAlign.center, style: ts(18)),
              const SizedBox(height: 14),
              PillButton(
                label: 'تسجيل الدخول',
                bg: AppColors.white,
                weight: FontWeight.w400,
                height: 66,
                onTap: () => Navigator.of(context).push(iosRoute(const PhoneScreen())),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('تبي تتخطى؟ ', style: ts(16)),
                  GestureDetector(
                    onTap: () => _guest(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('تصفح كزائر', style: ts(16, decoration: TextDecoration.underline)),
                    ),
                  ),
                ],
              ),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
