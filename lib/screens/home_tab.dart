import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'favorites_screen.dart';
import 'service_screen.dart';
import 'services_tab.dart';
import 'shell.dart';

/// الصفحة الرئيسية:
/// الترحيب ← الموعد القادم (لو موجود) ← البانرات (الحجز + العرض) ← الأكثر طلباً ← أطباؤنا
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final next = s.upcoming.isNotEmpty ? s.upcoming.first : null;
    final greet = s.firstName.isNotEmpty ? '${s.firstName}!' : 'نوّرتنا!';

    // المحتوى يمر تحت الساعة والبطارية وهو ينزل (بدون حد يفصلهم)
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 22, 0, navBottomSpace),
        children: [
          px(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('هلا،\n$greet', style: ts(38, height: 1.25))),
                // المفضلة: قلب أسود ثابت (ما يتغير ولا عليه رقم)
                CircleButton(
                  icon: CupertinoIcons.heart,
                  semanticLabel: 'المفضلة',
                  onTap: () => Navigator.of(context).push(iosRoute(const FavoritesScreen())),
                ),
              ],
            ),
          )),
          if (next != null) ...[
            const SizedBox(height: 16),
            px(_NextAppointmentPill(booking: next)),
          ],
          const SizedBox(height: 16),
          const _BannerCarousel(),
          _SectionHeader(title: 'الأكثر طلباً', onAll: () => s.openServices()),
          HScroll(
            height: 268,
            gap: 10,
            children: [for (final sv in popularServices) _MiniServiceCard(service: sv)],
          ),
          _SectionHeader(title: 'أطباؤنا', onAll: () => s.openDoctors()),
          HScroll(
            height: 232,
            gap: 10,
            children: [for (final d in doctors) _MiniDoctorCard(doctor: d)],
          ),
        ],
      ),
    );
  }
}

/// عنوان قسم و"عرض الكل"
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAll});

  final String title;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 10, 6),
        child: Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(title, style: ts(22, weight: FontWeight.w500)))),
            Semantics(
              button: true,
              label: 'عرض كل $title',
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Text('عرض الكل', style: ts(15, decoration: TextDecoration.underline)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// شريط الموعد القادم: صورة الطبيب، "موعدك القادم مع ..."، ودائرة فيها سهم
class _NextAppointmentPill extends StatelessWidget {
  const _NextAppointmentPill({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    final d = booking.doctor;
    return Pressable(
      onTap: () => s.setTab(1),
      semanticLabel: 'موعدك القادم مع ${d.name}، ${booking.day.full} الساعة ${fmtTime(booking.time)}، ${booking.branch.name}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
        ),
        child: Row(
          children: [
            DoctorAvatar(doctor: d, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'موعدك القادم مع '),
                      TextSpan(text: d.name, style: ts(15, weight: FontWeight.w600)),
                    ]),
                    style: ts(15),
                  ),
                  // اليوم والوقت والفرع في نظرة وحدة
                  Text(
                    '${booking.day.full} · ${fmtTime(booking.time)} · ${booking.branch.name}',
                    style: ts(13, color: AppColors.body),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
              child: Icon(CupertinoIcons.forward, size: 18, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// البانرات: الحجز + العرض. تتبدل لحالها كل 5 ثواني أو بالسحب
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _ctrl = PageController();
  Timer? _timer;
  int _index = 0;
  bool _visible = true;
  static const _count = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restart();
  }

  /// يبدأ التبديل التلقائي من جديد (ويوقف مع "تقليل الحركة")
  void _restart() {
    _timer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      // ما يتبدل إذا التبويب مو ظاهر
      if (!_visible) return;
      final next = (_index + 1) % _count;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _visible = TickerMode.of(context);
    final h = 262 * uiScale(context);
    return Column(
      children: [
        SizedBox(
          height: h,
          child: NotificationListener<ScrollStartNotification>(
            // لو المستخدم سحب بنفسه، نعيد عدّاد التبديل التلقائي
            onNotification: (n) {
              if (n.dragDetails != null) _restart();
              return false;
            },
            child: PageView(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: _BookBanner()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: _OfferBanner()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'بانر ${_index + 1} من $_count',
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: motion(context, 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.ink : AppColors.disabled,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// بانر "احجز موعدك بثواني"
class _BookBanner extends StatelessWidget {
  const _BookBanner();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(42),
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 2) : null,
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: 0,
            bottom: 0,
            top: 56,
            child: ExcludeSemantics(
              child: Image.asset('assets/doctors/reem.png', fit: BoxFit.contain, alignment: Alignment.bottomLeft),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: FractionallySizedBox(
              widthFactor: 0.56,
              alignment: AlignmentDirectional.topStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text('احجز موعدك\nبثواني', style: ts(32, height: 1.2, color: AppColors.onAccent))),
                  const SizedBox(height: 8),
                  Text(
                    'اختر التخصص والطبيب والوقت اللي يناسبك',
                    style: ts(15, height: 1.6, color: const Color(0xB8000000)),
                  ),
                  const Spacer(),
                  PillButton(
                    label: 'احجز الآن',
                    height: 50,
                    fontSize: 15,
                    bg: AppColors.onAccent,
                    fg: const Color(0xFFFFFFFF),
                    onTap: () => s.openDoctors(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بانر العرض (يفتح صفحة الخدمة نفسها)
class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) {
    final sv = offerService;
    void open() => Navigator.of(context).push(iosRoute(ServiceScreen(service: sv)));
    return GestureDetector(
      onTap: open,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(42)),
        padding: const EdgeInsets.fromLTRB(24, 26, 22, 22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0x29E3FF3A), borderRadius: BorderRadius.circular(999)),
                    child: Text('عرض لفترة محدودة', style: ts(13, weight: FontWeight.w600, color: AppColors.lime)),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('خصم ${fmtNum(sv.discount)}%', style: ts(40, weight: FontWeight.w600, height: 1.1, color: AppColors.lime)),
                  ),
                  const SizedBox(height: 4),
                  Text(sv.name, style: ts(20, color: const Color(0xFFFFFFFF))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(sv.oldPriceText, style: ts(14, color: const Color(0xFFAEAEB2), decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      Text(sv.priceText, style: ts(14, color: const Color(0xFFE5E5EA))),
                    ],
                  ),
                  const Spacer(),
                  PillButton(label: 'عرض الخدمة', height: 48, fontSize: 15, onTap: open),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ServiceImage(service: sv, size: 112),
          ],
        ),
      ),
    );
  }
}

/// بطاقة خدمة صغيرة (الأكثر طلباً)
class _MiniServiceCard extends StatefulWidget {
  const _MiniServiceCard({required this.service});

  final Service service;

  @override
  State<_MiniServiceCard> createState() => _MiniServiceCardState();
}

class _MiniServiceCardState extends State<_MiniServiceCard> with AddedFlash {
  void _add() {
    AppScope.read(context).addToCart(widget.service.id);
    flashAdded(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    final sv = widget.service;
    void open() => Navigator.of(context).push(iosRoute(ServiceScreen(service: sv)));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: open,
      child: Container(
        width: 172,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                height: 108,
                width: double.infinity,
                decoration: BoxDecoration(color: sv.tint, borderRadius: BorderRadius.circular(22)),
                child: Icon(sv.icon, size: 46, color: const Color(0xFF000000)),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                hint: 'عرض تفاصيل الخدمة',
                onTap: open,
                child: MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sv.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        RatingRow(rating: sv.ratingText, reviews: sv.reviews),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(child: Text(sv.priceText, style: ts(16, weight: FontWeight.w600))),
                  Pressable(
                    onTap: _add,
                    semanticLabel: added ? 'انضافت ${sv.name} للسلة' : 'إضافة ${sv.name} إلى السلة',
                    child: AnimatedContainer(
                      duration: motion(context, 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: added ? AppColors.ink : AppColors.lime,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        added ? Icons.check_rounded : Icons.add_rounded,
                        size: 24,
                        color: added ? AppColors.white : AppColors.onAccent,
                      ),
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

/// بطاقة طبيب صغيرة (أطباؤنا)
class _MiniDoctorCard extends StatelessWidget {
  const _MiniDoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final d = doctor;
    return Pressable(
      onTap: () => openBooking(context, d),
      semanticLabel: '${d.name}، ${d.role}، التقييم ${d.ratingText}',
      child: Container(
        width: 152,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          children: [
            DoctorAvatar(doctor: d, size: 100),
            const SizedBox(height: 10),
            Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: ts(15, weight: FontWeight.w600)),
            Text(d.role, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: ts(13, color: AppColors.body)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 17, color: starColor),
                const SizedBox(width: 3),
                Text(d.ratingText, style: ts(13, weight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
