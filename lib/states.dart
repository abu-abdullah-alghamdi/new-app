/// الحالات اللي ما تطلع عادة: التحميل، الأخطاء، الصفحات الفاضية، ونوافذ التنبيه
library;

import 'dart:math' as math;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'native.dart';
import 'services_data.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

// ─── سياسة العيادة (قيم مبدئية، تتعدل حسب سياسة العيادة الفعلية) ───

/// الإلغاء من التطبيق متاح قبل الموعد بهذي المدة على الأقل
const cancelCutoff = Duration(hours: 2);

/// مدة رجوع المبلغ بعد إلغاء موعد مدفوع
const refundWindowText = 'خلال 3 إلى 7 أيام عمل';

/// إعدادات تجي من السيرفر بعد الربط (حالياً ثابتة)
abstract final class RemoteConfig {
  /// النسخة الحالية ما عاد تشتغل ويلزم تحديث
  static bool updateRequired = false;

  /// لو فيه صيانة: وقت الرجوع المتوقع
  static DateTime? maintenanceUntil;
}

// ─── مكونات مشتركة ───

/// دائرة فيها أيقونة (أعلى الحالات والنوافذ)
class StateIcon extends StatelessWidget {
  const StateIcon({super.key, required this.icon, this.size = 110, this.bg = AppColors.bg, this.fg = AppColors.ink});

  final IconData icon;
  final double size;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: size * 0.46, color: fg),
        ),
      );
}

/// بطاقة حالة في نص الصفحة: أيقونة، عنوان، سطر اختياري، وزر
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconBg = AppColors.bg,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconBg;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 26),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(46),
          border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: StateIcon(icon: icon, bg: iconBg)),
            const SizedBox(height: 18),
            Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: ts(24))),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: ts(15, color: AppColors.body, height: 1.7)),
            ],
            if (actions.isNotEmpty) const SizedBox(height: 22),
            ...actions,
          ],
        ),
      );
}

/// صفحة كاملة لحالة (انقطاع النت، خطأ، صيانة): البطاقة في نص الشاشة
class StatusPage extends StatelessWidget {
  const StatusPage({super.key, required this.card, this.footer, this.closable = true});

  final Widget card;
  final Widget? footer;

  /// زر رجوع فوق (للصفحات اللي تنفتح فوق غيرها)
  final bool closable;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (closable)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 18, 14, 0),
                  child: Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [card, if (footer != null) ...[const SizedBox(height: 14), footer!]],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// انقطاع الإنترنت
class OfflineCard extends StatelessWidget {
  const OfflineCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => StatusCard(
        icon: CupertinoIcons.wifi_slash,
        title: 'ما فيه اتصال بالإنترنت',
        subtitle: 'تأكد من الواي فاي أو بيانات الجوال، وحاول مرة ثانية',
        actions: [
          PillButton(
            label: 'حاول مرة ثانية',
            icon: CupertinoIcons.arrow_clockwise,
            height: 60,
            fontSize: 17,
            bg: AppColors.ink,
            fg: AppColors.white,
            onTap: onRetry,
          ),
        ],
      );
}

/// سطر تحت بطاقة انقطاع النت: المواعيد المحفوظة تبان بدونه
class OfflineHint extends StatelessWidget {
  const OfflineHint({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            const Icon(CupertinoIcons.clock, size: 20, color: AppColors.faint),
            const SizedBox(width: 10),
            Expanded(child: Text('مواعيدك المحفوظة تقدر تشوفها بدون إنترنت', style: ts(14, color: AppColors.body))),
          ],
        ),
      );
}

/// خطأ من السيرفر (يختلف عن انقطاع النت)
class ServerErrorCard extends StatelessWidget {
  const ServerErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => StatusCard(
        icon: CupertinoIcons.exclamationmark_circle,
        title: 'صار خطأ، حاول مرة ثانية',
        actions: [
          PillButton(
            label: 'إعادة المحاولة',
            icon: CupertinoIcons.arrow_clockwise,
            height: 60,
            fontSize: 17,
            bg: AppColors.ink,
            fg: AppColors.white,
            onTap: onRetry,
          ),
        ],
      );
}

/// تحديث إجباري: النسخة قديمة وما تشتغل مع النظام
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, this.closable = false});

  final bool closable;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: closable,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (closable)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 18, 14, 0),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 120,
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 10))],
                              ),
                              child: Text('ع', style: ts(56, weight: FontWeight.w600, color: AppColors.onAccent)),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Semantics(header: true, child: Text('فيه تحديث جديد', textAlign: TextAlign.center, style: ts(30))),
                          const SizedBox(height: 6),
                          Text(
                            'هذي النسخة من عيادتي ما عاد تشتغل، حدّث التطبيق عشان تكمل حجوزاتك',
                            textAlign: TextAlign.center,
                            style: ts(15, color: AppColors.body, height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BottomAction(
                  child: PillButton(
                    label: 'تحديث من App Store',
                    icon: CupertinoIcons.arrow_down_to_line,
                    height: 64,
                    bg: AppColors.ink,
                    fg: AppColors.white,
                    onTap: () => launchUrl(Uri.parse(appShareLink), mode: LaunchMode.externalApplication),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// صيانة: النظام متوقف مؤقتاً
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key, required this.backAt, this.closable = false});

  /// وقت الرجوع المتوقع
  final DateTime backAt;
  final bool closable;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: closable,
        child: StatusPage(
          closable: closable,
          card: StatusCard(
            icon: CupertinoIcons.gear_alt,
            iconBg: AppColors.lime,
            title: 'نسوي تحسينات على التطبيق',
            subtitle: 'نرجع لكم تقريباً الساعة ${fmtClock(backAt)}',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_alt, size: 20, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text('مواعيدك محفوظة وما تأثرت', style: ts(14, color: AppColors.body))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'اتصل بالعيادة',
                icon: CupertinoIcons.phone_fill,
                height: 60,
                fontSize: 17,
                bg: AppColors.bg,
                onTap: () => launchUrl(Uri.parse('tel:$clinicPhone')),
              ),
            ],
          ),
        ),
      );
}

// ─── التحميل ───

/// مستطيل رمادي يلمع مكان المحتوى لين يوصل (ويثبت مع "تقليل الحركة")
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 14});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = still ? 0.5 : _ctrl.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.6 + 3.2 * t - 0.6, 0),
                end: Alignment(-1.6 + 3.2 * t + 0.6, 0),
                colors: const [Color(0xFFE6E7EA), Color(0xFFF3F4F6), Color(0xFFE6E7EA)],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// بطاقة طبيب وهي تتحمل (نفس شكل البطاقة الحقيقية)
class DoctorCardSkeleton extends StatelessWidget {
  const DoctorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 330,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(46)),
        child: const Stack(
          children: [
            Positioned(left: -10, bottom: 0, child: Skeleton(width: 170, height: 230, radius: 90)),
            Padding(
              padding: EdgeInsets.fromLTRB(26, 30, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 30),
                  SizedBox(height: 10),
                  Skeleton(width: 110, height: 30),
                  SizedBox(height: 14),
                  Skeleton(width: 170, height: 16, radius: 8),
                  SizedBox(height: 22),
                  Skeleton(width: 120, height: 26),
                  SizedBox(height: 8),
                  Skeleton(width: 150, height: 16, radius: 8),
                  Spacer(),
                  Skeleton(height: 64, radius: 999),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── الدفع ───

enum PayPhase { processing, success, failure }

/// حركة الدفع: دائرة تلف ونبض ليموني، وتتحول لعلامة صح لو نجح أو تحمر وتهتز لو فشل
class PaymentRing extends StatefulWidget {
  const PaymentRing({super.key, required this.phase, this.size = 120});

  final PayPhase phase;
  final double size;

  @override
  State<PaymentRing> createState() => _PaymentRingState();
}

class _PaymentRingState extends State<PaymentRing> with TickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final _done = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(PaymentRing old) {
    super.didUpdateWidget(old);
    if (old.phase == widget.phase) return;
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.phase == PayPhase.processing) {
      _done.value = 0;
      return;
    }
    if (still) {
      _done.value = 1;
    } else {
      _done.forward(from: 0);
    }
    if (widget.phase == PayPhase.success) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      if (!still) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _done.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse, _done, _shake]),
        builder: (context, _) {
          final t = _shake.value;
          final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
          return Transform.translate(
            offset: Offset(dx, 0),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _RingPainter(
                phase: widget.phase,
                spin: still ? 0.12 : _spin.value,
                pulse: still ? 0.5 : Curves.easeInOut.transform(_pulse.value),
                done: Curves.easeOutCubic.transform(_done.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.phase, required this.spin, required this.pulse, required this.done});

  final PayPhase phase;
  final double spin;
  final double pulse;
  final double done;

  static const _failBg = Color(0xFFFBE3E1);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = r * 0.13;

    if (phase == PayPhase.processing || done < 1) {
      // نبض ليموني خفيف في النص
      final inner = r * (0.62 + 0.08 * pulse) * (phase == PayPhase.processing ? 1 : 1 - done);
      canvas.drawCircle(c, inner, Paint()..color = AppColors.lime.withAlpha(phase == PayPhase.processing ? 150 : 90));
      // المسار الأبيض والقوس الأسود اللي يلف
      final ring = Rect.fromCircle(center: c, radius: r - stroke / 2);
      canvas.drawCircle(c, r - stroke / 2, Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke);
      final sweep = phase == PayPhase.processing ? math.pi / 2 : math.pi / 2 + (2 * math.pi - math.pi / 2) * done;
      canvas.drawArc(
        ring,
        spin * 2 * math.pi - math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = phase == PayPhase.failure ? AppColors.red : AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
    if (phase == PayPhase.processing) return;

    // الدائرة تتعبّى (ليموني للنجاح، أحمر فاتح للفشل) والعلامة تنرسم
    final fill = phase == PayPhase.success ? AppColors.lime : _failBg;
    canvas.drawCircle(c, r * done, Paint()..color = fill);
    final mark = Path();
    if (phase == PayPhase.success) {
      mark
        ..moveTo(c.dx - r * 0.36, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.28)
        ..lineTo(c.dx + r * 0.38, c.dy - r * 0.24);
    } else {
      mark
        ..moveTo(c.dx - r * 0.28, c.dy - r * 0.28)
        ..lineTo(c.dx + r * 0.28, c.dy + r * 0.28)
        ..moveTo(c.dx + r * 0.28, c.dy - r * 0.28)
        ..lineTo(c.dx - r * 0.28, c.dy + r * 0.28);
    }
    final paint = Paint()
      ..color = phase == PayPhase.success ? AppColors.onAccent : AppColors.red
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = r * 0.11;
    // نرسم جزء من العلامة حسب التقدم
    final metrics = mark.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var left = total * ((done - 0.35) / 0.65).clamp(0.0, 1.0);
    for (final m in metrics) {
      if (left <= 0) break;
      canvas.drawPath(m.extractPath(0, math.min(left, m.length)), paint);
      left -= m.length;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.phase != phase || old.spin != spin || old.pulse != pulse || old.done != done;
}

/// صفحة الدفع وهو قيد التحقق (ويتحول لنجاح أو فشل)
class PaymentProgressView extends StatelessWidget {
  const PaymentProgressView({super.key, required this.phase, required this.amount, required this.methodText});

  final PayPhase phase;
  final double amount;
  final String methodText;

  @override
  Widget build(BuildContext context) {
    final title = switch (phase) {
      PayPhase.processing => 'جاري الدفع',
      PayPhase.success => 'تم الدفع',
      PayPhase.failure => 'ما تم الدفع',
    };
    return Semantics(
      liveRegion: true,
      label: '$title، ${money(amount)}',
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PaymentRing(phase: phase),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: motion(context, 200),
                child: Text(title, key: ValueKey(title), style: ts(30)),
              ),
              const SizedBox(height: 6),
              Text('${money(amount)} · $methodText', style: ts(15, color: AppColors.body)),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف في بطاقة تفاصيل الدفع
Widget receiptRow(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ts(15, color: AppColors.body))),
          Text(value, style: ts(15, weight: FontWeight.w600, color: color)),
        ],
      ),
    );

/// بطاقة بيضاء فيها صفوف
Widget receiptCard(List<Widget> rows) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(34)),
      child: Column(children: rows),
    );

/// تاريخ ووقت العملية: "7 نوفمبر 2026 · 4:58 م"
String fmtStamp(DateTime d) => '${fmtNum(d.day)} ${monthNames[d.month - 1]} ${fmtNum(d.year)} · ${fmtClock(d)}';

enum PaymentFailAction { retry, changeMethod }

/// فشل الدفع: صفحة كاملة، وزرين (حاول مرة ثانية / طريقة دفع ثانية)
class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key, required this.amount, required this.methodText});

  final double amount;
  final String methodText;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 30, 14, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: StateIcon(icon: CupertinoIcons.xmark, bg: Color(0xFFFBE3E1), fg: AppColors.red)),
                        const SizedBox(height: 18),
                        Semantics(header: true, child: Text('ما تم الدفع', textAlign: TextAlign.center, style: ts(32))),
                        const SizedBox(height: 20),
                        receiptCard([
                          receiptRow('المبلغ', money(amount)),
                          receiptRow('طريقة الدفع', methodText),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PillButton(
                      label: 'حاول مرة ثانية',
                      icon: CupertinoIcons.arrow_clockwise,
                      height: 64,
                      onTap: () => Navigator.of(context).pop(PaymentFailAction.retry),
                    ),
                    const SizedBox(height: 8),
                    PillButton(
                      label: 'طريقة دفع ثانية',
                      height: 56,
                      fontSize: 16,
                      weight: FontWeight.w400,
                      bg: AppColors.white,
                      onTap: () => Navigator.of(context).pop(PaymentFailAction.changeMethod),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── نوافذ التنبيه ───

/// أيقونة صغيرة في أعلى النافذة
Widget _sheetIcon(IconData icon, {Color bg = AppColors.bg}) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: StateIcon(icon: icon, size: 64, bg: bg),
    );

Widget _sheetTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(header: true, child: Text(text, style: ts(23, weight: FontWeight.w500))),
    );

Widget _sheetLine(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: ts(15, color: AppColors.body, height: 1.7)),
    );

Widget _sheetBody(List<Widget> children) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );

Widget _secondary(BuildContext context, String label, {VoidCallback? onTap}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PillButton(
        label: label,
        height: 52,
        fontSize: 16,
        weight: FontWeight.w400,
        bg: AppColors.bg,
        onTap: onTap ?? () => Navigator.of(context).pop(),
      ),
    );

/// الوقت انحجز قبل ما يأكد: يختار من أقرب الأوقات. يرجّع الوقت المختار
Future<int?> showSlotTakenSheet(BuildContext context, {required String doctorId, required int day, required int time}) {
  final picks = nearestFreeTimes(doctorId, day, time);
  var chosen = picks.isEmpty ? null : picks.first;
  return showGlassSheet<int>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => _sheetBody([
        _sheetIcon(CupertinoIcons.clock),
        _sheetTitle('هذا الوقت ما عاد متاح'),
        if (picks.isEmpty)
          _sheetLine('ما فيه أوقات ثانية في نفس اليوم')
        else ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in picks)
                Pressable(
                  onTap: () => setSheet(() => chosen = t),
                  selected: chosen == t,
                  semanticLabel: fmtTime(t),
                  child: AnimatedContainer(
                    duration: motion(ctx, 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: chosen == t ? AppColors.ink : AppColors.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(fmtTime(t), style: ts(16, weight: FontWeight.w500, color: chosen == t ? AppColors.white : AppColors.ink)),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (chosen != null)
          PillButton(label: 'احجز ${fmtTime(chosen!)}', height: 60, fontSize: 17, onTap: () => Navigator.of(ctx).pop(chosen)),
        _secondary(ctx, picks.isEmpty ? 'اختر يوم ثاني' : 'رجوع'),
      ]),
    ),
  );
}

/// أقرب 3 أوقات متاحة لنفس الطبيب في نفس اليوم (الأقرب للوقت المطلوب أول)
List<int> nearestFreeTimes(String doctorId, int day, int time) {
  final free = [
    for (var i = 0; i < slotTimes.length; i++)
      if (slotTimes[i] != time && !slotTaken(doctorId, day, i)) slotTimes[i],
  ]..sort((a, b) => (a - time).abs().compareTo((b - time).abs()));
  return (free.take(3).toList())..sort();
}

/// أقرب يوم ووقت متاح مع الطبيب من يوم معيّن وطالع
({int day, int time})? nearestOpenSlot(String doctorId, int fromDay) {
  for (var d = fromDay; d < fromDay + 14; d++) {
    if (DayInfo(d).closed) continue;
    for (var i = 0; i < slotTimes.length; i++) {
      if (!slotTaken(doctorId, d, i)) return (day: d, time: slotTimes[i]);
    }
  }
  return null;
}

/// إلغاء موعد: يتأكد من السياسة والمبلغ المدفوع قبل الإلغاء
Future<void> confirmCancelBooking(BuildContext context, Booking b) async {
  final s = AppScope.read(context);
  final left = bookingStart(b).difference(DateTime.now());
  if (left < cancelCutoff) {
    await showLateCancelSheet(context, b, left);
    return;
  }
  final order = s.orderFor(b);
  final ok = order != null && order.paidOnline
      ? await showPaidCancelSheet(context, b, order)
      : await showCancelAlert(context, b);
  if (ok && context.mounted) {
    HapticFeedback.mediumImpact();
    s.cancelBooking(b.id);
  }
}

/// تنبيه آبل الأصلي بزرين (تراجع / إجراء أحمر). يرجّع true لو اختار الإجراء
Future<bool> showNativeAlert(
  BuildContext context, {
  required String title,
  required String message,
  required String cancel,
  required String destructive,
}) async {
  final result = await CNAlert.show<String>(
    context: context,
    title: title,
    message: message,
    actions: [
      CNAlertAction(label: cancel, isCancel: true),
      CNAlertAction(label: destructive, value: 'ok', isDestructive: true),
    ],
  );
  return result?.value == 'ok';
}

/// "اليوم" أو "غداً" أو "يوم الأحد"
String dayPhrase(int day) => switch (day) {
      0 => 'اليوم',
      1 => 'غداً',
      _ => 'يوم ${DayInfo(day).label}',
    };

/// تنبيه آبل الأصلي لإلغاء موعد غير مدفوع
Future<bool> showCancelAlert(BuildContext context, Booking b) => showNativeAlert(
      context,
      title: 'هل تريد إلغاء الموعد؟',
      message: '${b.doctor.name} · ${b.day.full} · ${fmtTime(b.time)}',
      cancel: 'تراجع',
      destructive: 'إلغاء الموعد',
    );

/// إلغاء موعد مدفوع: كم دفع وكم يرجع له ومتى
Future<bool> showPaidCancelSheet(BuildContext context, Booking b, Order order) async {
  final result = await showGlassSheet<bool>(
    context,
    builder: (ctx) => _sheetBody([
      _sheetTitle('إلغاء الموعد؟'),
      _sheetLine('${b.title} مع ${b.doctor.name} · ${b.day.full} · ${fmtTime(b.time)}'),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            receiptRow('المدفوع', money(order.total)),
            receiptRow('يرجع لك $refundWindowText', money(order.total), color: AppColors.green),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PillButton(
        label: 'إلغاء الموعد',
        height: 60,
        fontSize: 17,
        bg: AppColors.red,
        fg: AppColors.onRed,
        onTap: () => Navigator.of(ctx).pop(true),
      ),
      _secondary(ctx, 'تراجع'),
    ]),
  );
  return result ?? false;
}

/// إلغاء متأخر: الإلغاء من التطبيق متاح قبل الموعد بمدة معيّنة
Future<void> showLateCancelSheet(BuildContext context, Booking b, Duration left) {
  return showGlassSheet<void>(
    context,
    builder: (ctx) => _sheetBody([
      _sheetIcon(CupertinoIcons.clock),
      _sheetTitle('الإلغاء متاح قبل الموعد ب${fmtRemaining(cancelCutoff)}'),
      if (left > Duration.zero) _sheetLine('باقي على موعدك ${fmtRemaining(left)}'),
      const SizedBox(height: 16),
      PillButton(
        label: 'اتصل ب${b.branch.name}',
        icon: CupertinoIcons.phone_fill,
        height: 60,
        fontSize: 17,
        bg: AppColors.ink,
        fg: AppColors.white,
        onTap: () {
          Navigator.of(ctx).pop();
          launchUrl(Uri.parse('tel:${b.branch.phone}'));
        },
      ),
      _secondary(ctx, 'رجوع'),
    ]),
  );
}

enum DuplicateChoice { continueNew, editExisting }

/// حجز مكرر: عنده موعد مع نفس الطبيب في نفس اليوم
Future<DuplicateChoice?> showDuplicateSheet(BuildContext context, {required Booking existing, required int newTime}) {
  return showGlassSheet<DuplicateChoice>(
    context,
    builder: (ctx) => _sheetBody([
      _sheetIcon(CupertinoIcons.calendar_badge_plus),
      _sheetTitle('عندك موعد مع ${existing.doctor.n1} نفس اليوم'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${existing.day.full} · ${fmtTime(existing.time)}', style: ts(16, weight: FontWeight.w600)),
            Text('${existing.title} · ${existing.branch.name}', style: ts(14, color: AppColors.body)),
          ],
        ),
      ),
      _sheetLine('تبي تحجز موعد ثاني الساعة ${fmtTime(newTime)} ولا تعدّل موعدك الحالي؟'),
      const SizedBox(height: 14),
      PillButton(
        label: 'أكمل الحجز الجديد',
        height: 60,
        fontSize: 17,
        onTap: () => Navigator.of(ctx).pop(DuplicateChoice.continueNew),
      ),
      _secondary(ctx, 'تعديل موعدي الحالي', onTap: () => Navigator.of(ctx).pop(DuplicateChoice.editExisting)),
    ]),
  );
}

/// التقويم مقفل (المستخدم رفض الوصول له)
Future<void> showCalendarBlockedSheet(BuildContext context) {
  return showGlassSheet<void>(
    context,
    builder: (ctx) => _sheetBody([
      _sheetIcon(CupertinoIcons.calendar),
      _sheetTitle('التقويم مقفل'),
      const SizedBox(height: 16),
      PillButton(
        label: 'تفعيل',
        height: 60,
        fontSize: 17,
        bg: AppColors.ink,
        fg: AppColors.white,
        onTap: () {
          Navigator.of(ctx).pop();
          openAppSettings();
        },
      ),
      _secondary(ctx, 'لاحقاً'),
    ]),
  );
}

// ─── تنبيهات داخل الصفحات ───

/// التنبيهات مقفلة: عنوان وزر تفعيل وزر إغلاق
class NotificationsBanner extends StatelessWidget {
  const NotificationsBanner({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
        ),
        child: Row(
          children: [
            const StateIcon(icon: CupertinoIcons.bell_slash, size: 40),
            const SizedBox(width: 10),
            Expanded(child: Text('التنبيهات مقفلة', style: ts(16, weight: FontWeight.w600))),
            const PillButton(
              label: 'تفعيل',
              height: 40,
              fontSize: 14,
              padding: 18,
              bg: AppColors.ink,
              fg: AppColors.white,
              onTap: openAppSettings,
            ),
            CircleButton(
              icon: CupertinoIcons.xmark,
              size: 40,
              iconSize: 16,
              bg: AppColors.white,
              semanticLabel: 'إغلاق',
              onTap: onClose,
            ),
          ],
        ),
      );
}

/// ما فيه أوقات متاحة في اليوم المختار: يقترح أقرب موعد
class NoSlotsCard extends StatelessWidget {
  const NoSlotsCard({super.key, required this.doctor, required this.day, required this.nearest, required this.onBook});

  final Doctor doctor;
  final int day;
  final ({int day, int time})? nearest;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final n = nearest;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: StateIcon(icon: CupertinoIcons.calendar_badge_minus, size: 84)),
          const SizedBox(height: 12),
          Text('ما فيه أوقات متاحة ${dayPhrase(day)}', textAlign: TextAlign.center, style: ts(21)),
          if (n != null) ...[
            const SizedBox(height: 4),
            Text('أقرب موعد متاح مع ${doctor.name}', textAlign: TextAlign.center, style: ts(14, color: AppColors.body)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
              child: Text(
                '${DayInfo(n.day).full} · ${fmtTime(n.time)}',
                textAlign: TextAlign.center,
                style: ts(17, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            PillButton(label: 'احجز أقرب موعد', height: 56, fontSize: 17, onTap: onBook),
          ],
        ],
      ),
    );
  }
}
