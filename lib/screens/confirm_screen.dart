import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart_screen.dart';
import 'done_screen.dart';
import 'login_gate.dart';
import 'payment_screen.dart';

/// تأكيد الحجز: ملخص الموعد وزر واحد (بدون أي خانات؛ بيانات المستخدم من ملفه)
class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({
    super.key,
    required this.doctor,
    required this.cat,
    required this.day,
    required this.time,
    required this.branchId,
    this.items = const [],
    this.fromCart = false,
  });

  final Doctor doctor;
  final String cat;
  final int day;
  final int time;
  final String branchId;

  /// الخدمات المدفوعة (فاضية = زيارة عادية والدفع في العيادة)
  final List<OrderItem> items;
  final bool fromCart;

  Future<void> _confirm(BuildContext context) async {
    // قاعدة وحدة: الحجز يحتاج جوال موثّق
    if (!await requireLogin(context)) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    if (items.isNotEmpty) {
      nav.push(iosRoute(PaymentScreen(
        branchId: branchId,
        items: items,
        fromCart: fromCart,
        appointment: Appointment(doctorId: doctor.id, cat: cat, day: day, time: time),
      )));
      return;
    }
    final b = AppScope.read(context).addBooking(doctorId: doctor.id, cat: cat, day: day, time: time, branchId: branchId);
    nav.pushReplacement(iosRoute(DoneScreen(booking: b)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = doctor;
    final branch = branchById(branchId);
    final subtotal = items.fold(0, (a, b) => a + b.total);
    final title = items.isEmpty ? (categories[cat] ?? '') : items.map((i) => i.service.name).join('، ');

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
                      Text(title, style: ts(14, color: AppColors.body)),
                      const SizedBox(height: 12),
                      Text(DayInfo(day).full, style: ts(24, color: AppColors.blue)),
                      Text(fmtRange(time, d.duration), style: ts(15)),
                      const SizedBox(height: 6),
                      Text(branch.name, style: ts(15, weight: FontWeight.w600)),
                      Text(branch.area, style: ts(13, color: AppColors.faint)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isNotEmpty)
                    AmountSummary(subtotal: subtotal, vat: s.vatFor(subtotal))
                  else
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(32)),
                      child: Column(
                        children: [
                          amountRow('سعر الكشف', d.price, bold: true),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text('الدفع في العيادة', style: ts(13, color: AppColors.faint)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: items.isNotEmpty ? 'متابعة للدفع' : 'تأكيد الحجز',
                  height: 66,
                  onTap: () => _confirm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
