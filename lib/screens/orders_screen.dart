import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../payments.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

String _date(DateTime d) => '${fmtNum(d.day)} ${monthNames[d.month - 1]} ${fmtNum(d.year)}';

/// بطاقة طلب: رقم الطلب، الخدمات، الفرع، طريقة الدفع، الإجمالي
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final cash = order.method == PayMethod.cash;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('طلب #${order.number}', style: ts(18, weight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cash ? AppColors.bg : AppColors.lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cash ? 'الدفع في العيادة' : 'مدفوع',
                  style: ts(13, weight: FontWeight.w600, color: cash ? AppColors.ink : AppColors.onAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_date(order.date)} · ${branchById(order.branchId).name} · ${order.method.label}',
              style: ts(13, color: AppColors.faint)),
          const SizedBox(height: 8),
          for (final it in order.items)
            amountRow('${it.service.name}${it.qty > 1 ? ' × ${fmtNum(it.qty)}' : ''}', money(it.total)),
          amountRow('ضريبة القيمة المضافة', money(order.vat)),
          const Divider(color: AppColors.bg, height: 16, thickness: 1.5),
          amountRow('الإجمالي', money(order.total), bold: true),
        ],
      ),
    );
  }
}

/// طلباتي (من صفحة "حسابي")
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
            const SizedBox(height: 18),
            const BigTitle('طلباتي', size: 40),
            const SizedBox(height: 14),
            if (s.orders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.doc_text, size: 44, color: AppColors.faint),
                    const SizedBox(height: 12),
                    Text('ما عندك طلبات حتى الآن', style: ts(20)),
                    const SizedBox(height: 6),
                    Text('طلبات الخدمات اللي تدفعها تظهر هنا', style: ts(15, color: AppColors.body)),
                  ],
                ),
              )
            else
              for (final o in s.orders) ...[
                OrderCard(order: o),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
