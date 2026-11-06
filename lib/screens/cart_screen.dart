import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'service_booking_screen.dart';

/// صف في ملخص المبلغ
Widget amountRow(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: ts(bold ? 17 : 15, weight: bold ? FontWeight.w600 : FontWeight.w400, color: bold ? AppColors.ink : AppColors.body)),
          ),
          Text(value, style: ts(bold ? 19 : 15, weight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );

/// ملخص المبلغ: المجموع والضريبة والإجمالي
class AmountSummary extends StatelessWidget {
  const AmountSummary({super.key, required this.subtotal, required this.vat});

  final num subtotal;
  final double vat;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          children: vat > 0
              ? [
                  amountRow('المجموع', money(subtotal)),
                  amountRow('ضريبة القيمة المضافة (${ar((vatRate * 100).round())}%)', money(vat)),
                  Divider(color: AppColors.bg, height: 18, thickness: 1.5),
                  amountRow('الإجمالي', money(subtotal + vat), bold: true),
                ]
              // المواطن السعودي (والزائر قبل التسجيل): الإجمالي بس
              : [amountRow('الإجمالي', money(subtotal), bold: true)],
        ),
      );
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.cartItems;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                children: [
                  Row(
                    children: [
                      const BackCircle(),
                      Expanded(child: Text('السلة', textAlign: TextAlign.center, style: ts(18, weight: FontWeight.w500))),
                      const SizedBox(width: 58),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    _Empty(onBrowse: () => Navigator.of(context).maybePop())
                  else ...[
                    const BigTitle('سلتك', size: 38),
                    const SizedBox(height: 14),
                    for (final it in items) ...[
                      Dismissible(
                        key: ValueKey(it.service.id),
                        direction: DismissDirection.horizontal,
                        onDismissed: (_) => s.removeFromCart(it.service.id),
                        background: _deleteBg(AlignmentDirectional.centerStart),
                        secondaryBackground: _deleteBg(AlignmentDirectional.centerEnd),
                        child: _CartRow(item: it),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 14),
                    AmountSummary(subtotal: s.cartSubtotal, vat: s.cartVat),
                  ],
                ],
              ),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  // السلة تكمل في نفس رحلة الحجز: الفرع ← الطبيب ← اليوم ← الوقت ← الدفع
                  child: PillButton(
                    label: 'اختيار الموعد · ${money(s.cartTotal)}',
                    icon: CupertinoIcons.calendar,
                    height: 66,
                    fontSize: 17,
                    onTap: () => openServiceBooking(context, s.cartItems, fromCart: true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBg(AlignmentGeometry align) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(28)),
        child: const Icon(CupertinoIcons.trash, color: AppColors.onRed),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: Icon(CupertinoIcons.bag, size: 42, color: AppColors.faint),
            ),
            const SizedBox(height: 18),
            Text('السلة فاضية', style: ts(24)),
            const SizedBox(height: 6),
            Text('أضف الخدمات اللي تحتاجها من صفحة الخدمات', textAlign: TextAlign.center, style: ts(15, color: AppColors.body)),
            const SizedBox(height: 22),
            PillButton(label: 'تصفح الخدمات', height: 58, fontSize: 16, onTap: onBrowse),
          ],
        ),
      );
}

/// صف خدمة في السلة مع تغيير الكمية
class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final sv = item.service;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          ServiceImage(service: sv, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sv.name, style: ts(16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(money(item.total), style: ts(15, color: AppColors.body)),
              ],
            ),
          ),
          CircleButton(
            icon: item.qty == 1 ? CupertinoIcons.trash : CupertinoIcons.minus,
            size: 44,
            iconSize: 18,
            bg: AppColors.bg,
            semanticLabel: item.qty == 1 ? 'حذف ${sv.name}' : 'إنقاص الكمية',
            onTap: () => s.setQty(sv.id, item.qty - 1),
          ),
          SizedBox(
            width: 34,
            child: Semantics(
              label: 'الكمية ${ar(item.qty)}',
              child: ExcludeSemantics(
                child: Text(ar(item.qty), textAlign: TextAlign.center, style: ts(18, weight: FontWeight.w600)),
              ),
            ),
          ),
          CircleButton(
            icon: CupertinoIcons.plus,
            size: 44,
            iconSize: 18,
            bg: AppColors.lime,
            semanticLabel: 'زيادة الكمية',
            onTap: () => s.setQty(sv.id, item.qty + 1),
          ),
        ],
      ),
    );
  }
}
