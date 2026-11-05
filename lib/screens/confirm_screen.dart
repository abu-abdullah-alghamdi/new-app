import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'done_screen.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key, required this.doctor, required this.cat, required this.day, required this.time});

  final Doctor doctor;
  final String cat;
  final int day;
  final int time;

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _consent = false;
  bool _marketing = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _name = TextEditingController(text: s.name);
    _phone = TextEditingController(text: s.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _valid {
    final digits = en(_phone.text).replaceAll(RegExp(r'\D'), '');
    return _name.text.trim().length > 1 && digits.length >= 9 && _consent;
  }

  void _confirm() {
    if (!_valid) return;
    final s = AppScope.read(context);
    s.setProfile(name: _name.text.trim(), phone: _phone.text.trim());
    final b = s.addBooking(doctorId: widget.doctor.id, cat: widget.cat, day: widget.day, time: widget.time);
    Navigator.of(context).pushReplacement(iosRoute(DoneScreen(booking: b)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                children: [
                  const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
                  const SizedBox(height: 14),
                  const BigTitle('تأكيد\nالحجز', size: 40),
                  const SizedBox(height: 14),
                  CutCard(
                    image: d.image,
                    imageWidth: 150,
                    imageHeight: 200,
                    textWidth: 200,
                    padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
                    shadow: false,
                    children: [
                      Text('${d.n1}\n${d.n2}', style: ts(26, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(categories[widget.cat] ?? '', style: ts(14, color: AppColors.body)),
                      const SizedBox(height: 12),
                      Text(DayInfo(widget.day).full, style: ts(24, color: AppColors.blue)),
                      Text(fmtRange(widget.time, d.duration), style: ts(15)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('الاسم', style: ts(15)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    style: ts(16),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: pillInput('اسمك الكامل'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('رقم الجوال (واتساب)', style: ts(15)),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _phone,
                      style: ts(16),
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: pillInput('05xxxxxxxx'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCheck(
                    value: _consent,
                    onChanged: () => setState(() => _consent = !_consent),
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'أوافق على '),
                        TextSpan(text: 'سياسة الخصوصية', style: ts(13, decoration: TextDecoration.underline, height: 1.7)),
                        const TextSpan(text: ' واستخدام بياناتي لإدارة الموعد وإرسال التذكير.'),
                      ]),
                      style: ts(13, height: 1.7),
                    ),
                  ),
                  AppCheck(
                    value: _marketing,
                    onChanged: () => setState(() => _marketing = !_marketing),
                    child: Text('أرغب باستقبال العروض والتذكيرات الدورية (اختياري)', style: ts(13, color: AppColors.body, height: 1.7)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(label: 'تأكيد الحجز', height: 66, enabled: _valid, onTap: _confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
