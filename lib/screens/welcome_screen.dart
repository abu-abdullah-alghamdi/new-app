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
                        ExcludeSemantics(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.ink, width: 3.5),
                            ),
                            child: Icon(Icons.add_rounded, size: 26, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(child: Text('عيادات أريام', style: ts(27, weight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 56),
                    Semantics(header: true, child: Text('أهلاً بك', textAlign: TextAlign.center, style: ts(32))),
                    const SizedBox(height: 10),
                    Text(
                      'احجز مواعيدك وتابع زياراتك، وتوصلك التذكيرات على واتساب. كل شي في مكان واحد.',
                      textAlign: TextAlign.center,
                      style: ts(17, color: AppColors.body, height: 1.7),
                    ),
                    const SizedBox(height: 34),
                    PillButton(
                      label: 'المتابعة برقم الجوال',
                      icon: Icons.phone_rounded,
                      height: 66,
                      onTap: () => Navigator.of(context).push(iosRoute(const PhoneScreen())),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نفس الخطوة للتسجيل الجديد أو الدخول لحسابك',
                      textAlign: TextAlign.center,
                      style: ts(14, color: AppColors.faint),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    PillButton(
                      label: 'تصفح كزائر',
                      bg: AppColors.white,
                      weight: FontWeight.w400,
                      height: 60,
                      fontSize: 17,
                      onTap: () => _guest(context),
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
