import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../main.dart';
import '../payments.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'done_screen.dart';
import 'orders_screen.dart';

IconData payIcon(PayMethod m) => switch (m) {
      PayMethod.applePay => Icons.apple,
      PayMethod.mada => Icons.credit_card_rounded,
      PayMethod.card => Icons.payment_rounded,
      PayMethod.cash => Icons.storefront_rounded,
    };

/// الموعد اللي ينحجز بعد الدفع
class Appointment {
  const Appointment({required this.doctorId, required this.cat, required this.day, required this.time});

  final String doctorId;
  final String cat;
  final int day;
  final int time;
}

/// صفحة الدفع (شكلية لين يتم الربط مع بوابة دفع حقيقية — شوف lib/payments.dart)
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.branchId, required this.items, this.appointment, this.fromCart = false});

  final String branchId;
  final List<OrderItem> items;

  /// لو موجود: بعد الدفع ينحجز الموعد ويطلع في "مواعيدي"
  final Appointment? appointment;
  final bool fromCart;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod _method = PayMethod.applePay;
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _paying = false;

  int get _subtotal => widget.items.fold(0, (a, b) => a + b.total);

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String _digits(TextEditingController c) => normalizeDigits(c.text).replaceAll(RegExp(r'\D'), '');

  bool get _cardOk {
    if (!_method.needsCard) return true;
    return _digits(_number).length == 16 &&
        _holder.text.trim().length >= 3 &&
        RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(_expiry.text) &&
        RegExp(r'^\d{3,4}$').hasMatch(_digits(_cvv));
  }

  Future<void> _pay() async {
    if (!_cardOk || _paying) return;
    FocusScope.of(context).unfocus();
    final s = AppScope.read(context);
    setState(() => _paying = true);
    final result = await PaymentGateway.instance.pay(
      amount: _subtotal + s.vatFor(_subtotal),
      method: _method,
      card: _method.needsCard
          ? CardDetails(number: _digits(_number), holder: _holder.text.trim(), expiry: _expiry.text, cvv: _digits(_cvv))
          : null,
    );
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'ما تمت عملية الدفع، حاول مرة ثانية', style: ts(14, color: AppColors.white))),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final order = s.placeOrder(
      items: widget.items,
      branchId: widget.branchId,
      method: _method,
      reference: result.reference ?? '',
      clearCart: widget.fromCart,
    );
    final a = widget.appointment;
    if (a != null) {
      // الخدمة تصير موعد في "مواعيدي"
      final b = s.addBooking(
        doctorId: a.doctorId,
        cat: a.cat,
        day: a.day,
        time: a.time,
        branchId: widget.branchId,
        serviceIds: [for (final i in widget.items) i.service.id],
      );
      Navigator.of(context).pushAndRemoveUntil(iosRoute(DoneScreen(booking: b)), (r) => r.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(iosRoute(OrderDoneScreen(order: order)), (r) => r.isFirst);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
        child: Text(text, style: ts(20, weight: FontWeight.w500)),
      );

  Widget _field(String hint, TextEditingController c,
          {TextInputType? keyboard, List<TextInputFormatter>? formatters, bool obscure = false, List<String>? autofill}) =>
      Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: c,
          style: ts(17).copyWith(letterSpacing: 1),
          keyboardType: keyboard,
          inputFormatters: formatters,
          obscureText: obscure,
          autocorrect: false,
          autofillHints: autofill,
          decoration: pillInput(hint),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final total = _subtotal + s.vatFor(_subtotal);
    final payLabel = _paying
        ? 'جاري الدفع…'
        : (_method == PayMethod.cash ? 'تأكيد الطلب · ${money(total)}' : 'ادفع ${money(total)}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const ScreenHeader(title: 'الدفع'),
                  const SizedBox(height: 16),
                  if (PaymentGateway.instance.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.info_circle_fill, size: 22, color: AppColors.ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'وضع تجريبي: لن يتم خصم أي مبلغ، ولا تُحفظ بيانات البطاقة أو تُرسل',
                              style: ts(14, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _label('ملخص الطلب'),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.location_solid, size: 16, color: AppColors.faint),
                            const SizedBox(width: 6),
                            Text(branchById(widget.branchId).name, style: ts(15, weight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final it in widget.items)
                          amountRow('${it.service.name}${it.qty > 1 ? ' × ${fmtNum(it.qty)}' : ''}', money(it.total)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AmountSummary(subtotal: _subtotal, vat: s.vatFor(_subtotal)),
                  _label('طريقة الدفع'),
                  for (final m in PayMethod.values) ...[
                    _MethodTile(method: m, selected: _method == m, onTap: () => setState(() => _method = m)),
                    const SizedBox(height: 8),
                  ],
                  if (_method.needsCard) ...[
                    _label('بيانات البطاقة'),
                    _field('0000 0000 0000 0000', _number,
                        keyboard: TextInputType.number,
                        formatters: [const WesternDigits(), _CardNumberFormatter()],
                        autofill: const [AutofillHints.creditCardNumber]),
                    const SizedBox(height: 8),
                    _field('الاسم على البطاقة', _holder,
                        keyboard: TextInputType.name, autofill: const [AutofillHints.creditCardName]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _field('MM/YY', _expiry,
                              keyboard: TextInputType.number,
                              formatters: [const WesternDigits(), _ExpiryFormatter()],
                              autofill: const [AutofillHints.creditCardExpirationDate]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field('CVV', _cvv,
                              keyboard: TextInputType.number,
                              obscure: true,
                              formatters: [
                                const WesternDigits(),
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              autofill: const [AutofillHints.creditCardSecurityCode]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            BottomAction(
              child: _method == PayMethod.applePay && !_paying
                  ? PillButton(
                      label: 'الدفع عبر Apple Pay',
                      icon: Icons.apple,
                      height: 66,
                      bg: AppColors.ink,
                      fg: AppColors.white,
                      onTap: _pay,
                    )
                  : PillButton(label: payLabel, height: 66, fontSize: 17, enabled: _cardOk && !_paying, onTap: _pay),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  final PayMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: '${method.label}، ${method.hint}',
        child: AnimatedContainer(
          duration: motion(context, 200),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
                child: Icon(payIcon(method), size: 24, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.label, style: ts(17, weight: FontWeight.w600)),
                    Text(method.hint, style: ts(13, color: AppColors.faint)),
                  ],
                ),
              ),
              SelectDot(selected: selected),
            ],
          ),
        ),
      );
}

/// رقم البطاقة: 16 رقم في مجموعات من 4
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = d.length > 16 ? d.substring(0, 16) : d;
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(digits[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// تاريخ الانتهاء MM/YY
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = d.length > 4 ? d.substring(0, 4) : d;
    final t = digits.length > 2 ? '${digits.substring(0, 2)}/${digits.substring(2)}' : digits;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// صفحة نجاح الطلب
class OrderDoneScreen extends StatelessWidget {
  const OrderDoneScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final cash = order.method == PayMethod.cash;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
                children: [
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 56, color: AppColors.onAccent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text('تم الطلب بنجاح', textAlign: TextAlign.center, style: ts(32)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم الطلب #${order.number}',
                    textAlign: TextAlign.center,
                    style: ts(16, color: AppColors.body),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cash
                        ? 'الدفع عند زيارتك للفرع، ويتواصل معك الفرع لتحديد موعد الخدمة'
                        : 'تم الدفع (تجريبي)، ويتواصل معك الفرع لتحديد موعد الخدمة',
                    textAlign: TextAlign.center,
                    style: ts(15, color: AppColors.body, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  OrderCard(order: order),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(label: 'تم', height: 64, onTap: () => Navigator.of(context).pop()),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: 'عرض طلباتي',
                      height: 56,
                      fontSize: 16,
                      bg: AppColors.white,
                      onTap: () {
                        final nav = Navigator.of(context);
                        AppScope.read(context).setTab(3);
                        nav.pop();
                        nav.push(iosRoute(const OrdersScreen()));
                      },
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
