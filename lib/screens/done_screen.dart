import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../native.dart';
import '../services_data.dart';
import '../state.dart';
import '../states.dart';
import '../theme.dart';
import '../widgets.dart';

class DoneScreen extends StatefulWidget {
  const DoneScreen({super.key, required this.booking, this.edited = false, this.order});

  final Booking booking;
  final bool edited;

  /// لو الموعد مدفوع من التطبيق: تطلع تفاصيل الدفع بدل بطاقة الطبيب
  final Order? order;

  @override
  State<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<DoneScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  Future<void> _addToCalendar() async {
    final ok = await addBookingToCalendar(widget.booking);
    if (!ok && mounted) await showCalendarBlockedSheet(context);
  }

  void _goTab(int tab) {
    AppScope.read(context).setTab(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final d = b.doctor;
    final paid = widget.order != null && widget.order!.paidOnline ? widget.order : null;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: motion(context, 600),
                              curve: Curves.elasticOut,
                              builder: (context, v, child) => Transform.scale(scale: 0.4 + 0.6 * v, child: child),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 60, color: AppColors.onAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (paid != null) ...[
                            Semantics(header: true, child: Text('تم الدفع بنجاح', textAlign: TextAlign.center, style: ts(32))),
                            const SizedBox(height: 6),
                            Text('موعدك تأكد وصار في "مواعيدي"', textAlign: TextAlign.center, style: ts(15, color: AppColors.body)),
                            const SizedBox(height: 20),
                            receiptCard([
                              receiptRow('المبلغ', money(paid.total)),
                              receiptRow('طريقة الدفع', paid.methodText),
                              receiptRow('رقم العملية', '#${paid.number}'),
                              receiptRow('التاريخ', fmtStamp(paid.date)),
                            ]),
                          ] else ...[
                            Semantics(
                              header: true,
                              child: Text(widget.edited ? 'تم تعديل موعدك' : 'تم تأكيد حجزك', textAlign: TextAlign.center, style: ts(34)),
                            ),
                            const SizedBox(height: 16),
                            CutCard(
                              image: d.image,
                              imageWidth: 140,
                              imageHeight: 186,
                              textWidth: 200,
                              padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
                              shadow: false,
                              children: [
                                Text('${d.n1}\n${d.n2}', style: ts(24, height: 1.2)),
                                const SizedBox(height: 8),
                                Text(b.day.full, style: ts(22, color: AppColors.blue)),
                                Text(b.range, style: ts(15)),
                                const SizedBox(height: 4),
                                Text(b.title, style: ts(14, color: AppColors.body)),
                                Text(b.branch.name, style: ts(15, weight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('يوصلك تذكير على واتساب قبل موعدك بيوم، وتنبيه من جوالك قبله بساعة', style: ts(14, color: AppColors.body)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // يفتح نافذة التقويم من آبل والموعد معبّى فيها
                PillButton(
                  label: 'أضف إلى التقويم',
                  icon: CupertinoIcons.calendar_badge_plus,
                  height: 58,
                  fontSize: 16,
                  bg: AppColors.white,
                  weight: FontWeight.w400,
                  onTap: _addToCalendar,
                ),
                const SizedBox(height: 10),
                PillButton(label: 'عرض مواعيدي', height: 66, onTap: () => _goTab(1)),
                const SizedBox(height: 10),
                PillButton(label: 'الرئيسية', height: 66, bg: AppColors.white, weight: FontWeight.w400, onTap: () => _goTab(0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
