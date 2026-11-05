import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'privacy_screen.dart';
import 'otp_screen.dart';

/// يرجّع الرقم الوطني (٩ أرقام يبدأ بـ ٥) أو null إذا غير صحيح
String? nationalNumber(String raw) {
  final digits = en(raw).replaceAll(RegExp(r'\D'), '');
  var n = digits;
  if (n.startsWith('9665')) n = n.substring(3);
  if (n.startsWith('05')) n = n.substring(1);
  return RegExp(r'^5\d{8}$').hasMatch(n) ? n : null;
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final n = nationalNumber(_ctrl.text);
    if (n == null) {
      setState(() => _error = true);
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(iosRoute(OtpScreen(national: n)));
  }

  @override
  Widget build(BuildContext context) {
    final valid = nationalNumber(_ctrl.text) != null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                children: [
                  const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
                  const SizedBox(height: 24),
                  const BigTitle('رقم\nجوالك'),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('بنرسل لك رمز تحقق من ٤ أرقام على هذا الرقم.', style: ts(15, color: AppColors.body, height: 1.8)),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('رقم الجوال', style: ts(15)),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: AnimatedContainer(
                      duration: motion(context, 200),
                      constraints: const BoxConstraints(minHeight: 70),
                      padding: const EdgeInsets.only(left: 8, right: 22),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _error ? AppColors.red : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            constraints: const BoxConstraints(minHeight: 52),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                            child: Text('+966', style: ts(16, weight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumberNational],
                              inputFormatters: [LengthLimitingTextInputFormatter(12)],
                              style: ts(20, height: 1.2).copyWith(letterSpacing: 1),
                              decoration: InputDecoration(
                                hintText: '5X XXX XXXX',
                                hintStyle: ts(20, color: AppColors.faint),
                                border: InputBorder.none,
                              ),
                              onChanged: (_) => setState(() => _error = false),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text('اكتب رقم جوال سعودي صحيح يبدأ بـ ٥ (مثل ٥٥١٢٣٤٥٦٧)', style: ts(14, color: AppColors.red)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(iosRoute(const PrivacyScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'بالمتابعة توافق على '),
                      TextSpan(text: 'الشروط', style: ts(13, color: AppColors.faint, decoration: TextDecoration.underline)),
                      const TextSpan(text: ' و'),
                      TextSpan(text: 'سياسة الخصوصية', style: ts(13, color: AppColors.faint, decoration: TextDecoration.underline)),
                    ]),
                    textAlign: TextAlign.center,
                    style: ts(13, color: AppColors.faint),
                  ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: 'إرسال الرمز',
                      height: 66,
                      bg: valid ? AppColors.lime : AppColors.disabled,
                      fg: valid ? AppColors.onAccent : AppColors.disabledText,
                      onTap: _send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
