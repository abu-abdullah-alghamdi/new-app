import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'service_booking_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
                  const ScreenHeader(title: 'السلة'),
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
              // السلة تكمل في نفس رحلة الحجز: الفرع ← الطبيب ← اليوم ← الوقت ← الدفع
              BottomAction(
                child: PillButton(
                  label: 'اختيار الموعد · ${money(s.cartTotal)}',
                  icon: CupertinoIcons.calendar,
                  height: 66,
                  fontSize: 17,
                  onTap: () => openServiceBooking(context, s.cartItems, fromCart: true),
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
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.bag, size: 42, color: AppColors.faint),
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
              label: 'الكمية ${fmtNum(item.qty)}',
              child: ExcludeSemantics(
                child: Text(fmtNum(item.qty), textAlign: TextAlign.center, style: ts(18, weight: FontWeight.w600)),
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
