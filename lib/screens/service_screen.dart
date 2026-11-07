import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../native.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'service_booking_screen.dart';
import 'services_tab.dart';

/// صفحة الخدمة: الصورة، الاسم، التوفر، التقييم، النبذة، التقييمات، والكمية وزر الإضافة
class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.service});

  final Service service;

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> with AddedFlash {
  int _qty = 1;
  bool _more = false;

  Service get sv => widget.service;

  void _add() {
    AppScope.read(context).addToCart(sv.id, qty: _qty);
    flashAdded(const Duration(milliseconds: 1200), onReset: () => _qty = 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final about = _more || sv.about.length <= 120 ? sv.about : '${sv.about.substring(0, 120)}…';
    final reviews = sv.reviewList;

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
                      const Spacer(),
                      // قائمة المشاركة الأصلية من آبل
                      Builder(
                        builder: (ctx) => CircleButton(
                          icon: CupertinoIcons.share,
                          semanticLabel: 'مشاركة الخدمة',
                          onTap: () => shareText(ctx, shareServiceText(sv)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FavButton(
                        active: s.favServices.contains(sv.id),
                        name: sv.name,
                        size: 58,
                        onTap: () => s.toggleFavService(sv.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // صورة الخدمة (أيقونة لين توصل الصور الحقيقية)
                  ExcludeSemantics(
                    child: Container(
                      height: 230,
                      decoration: BoxDecoration(color: sv.tint, borderRadius: BorderRadius.circular(44)),
                      child: Icon(sv.icon, size: 110, color: const Color(0xFF000000)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(sv.name, style: ts(32, height: 1.2))),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(CupertinoIcons.location_solid, size: 16, color: sv.allBranches ? AppColors.green : AppColors.faint),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sv.availabilityText,
                                style: ts(15, color: sv.allBranches ? AppColors.green : AppColors.body, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Semantics(
                              label: 'التقييم ${sv.ratingText} من 5، ${fmtNum(sv.reviews)} تقييم',
                              child: ExcludeSemantics(child: RatingRow(rating: sv.ratingText, reviews: sv.reviews)),
                            ),
                            const Spacer(),
                            if (sv.onOffer) ...[
                              Text(sv.oldPriceText, style: ts(16, color: AppColors.faint, decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 8),
                            ],
                            Text(sv.priceText, style: ts(26, weight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // النبذة
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(36)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text('عن الخدمة', style: ts(20, weight: FontWeight.w500))),
                        const SizedBox(height: 6),
                        AnimatedSize(
                          duration: motion(context, 250),
                          alignment: Alignment.topCenter,
                          child: Text(about, style: ts(15, color: AppColors.body, height: 1.85)),
                        ),
                        if (sv.about.length > 120)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _more = !_more),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_more ? 'عرض أقل' : 'اقرأ المزيد', style: ts(15, decoration: TextDecoration.underline)),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // التقييمات
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(header: true, child: Text('التقييمات', style: ts(22, weight: FontWeight.w500))),
                        ),
                        const Icon(Icons.star_rounded, size: 22, color: starColor),
                        const SizedBox(width: 4),
                        Text(sv.ratingText, style: ts(18, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28)),
                      child: Text('لا توجد تقييمات بعد', textAlign: TextAlign.center, style: ts(15, color: AppColors.body)),
                    )
                  else
                    for (final r in reviews) ...[
                      ReviewCard(review: r),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
            // شريط "عرض السلة" يطلع بعد الإضافة
            if (s.cartCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: CartBar(count: s.cartCount, subtotal: s.cartSubtotal),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الأساسي: احجز الخدمة (الفرع ← الطبيب ← اليوم ← الوقت ← الدفع)
                  PillButton(
                    label: 'احجز الخدمة · ${money(sv.finalPrice * _qty)}',
                    icon: CupertinoIcons.calendar,
                    height: 62,
                    fontSize: 17,
                    onTap: () => openServiceBooking(context, [OrderItem(sv, _qty)]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                children: [
                  // الكمية
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleButton(
                          icon: CupertinoIcons.minus,
                          size: 48,
                          iconSize: 18,
                          bg: AppColors.bg,
                          enabled: _qty > 1,
                          semanticLabel: 'إنقاص الكمية',
                          onTap: () => setState(() => _qty--),
                        ),
                        SizedBox(
                          width: 36,
                          child: Semantics(
                            label: 'الكمية ${fmtNum(_qty)}',
                            liveRegion: true,
                            child: ExcludeSemantics(
                              child: Text(fmtNum(_qty), textAlign: TextAlign.center, style: ts(19, weight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        CircleButton(
                          icon: CupertinoIcons.plus,
                          size: 48,
                          iconSize: 18,
                          bg: AppColors.bg,
                          enabled: _qty < maxQty,
                          semanticLabel: 'زيادة الكمية',
                          onTap: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // الثانوي: السلة (للي يبي يحجز أكثر من خدمة في نفس الزيارة)
                    child: PillButton(
                      label: added ? 'تمت الإضافة' : 'أضف إلى السلة',
                      icon: added ? Icons.check_rounded : CupertinoIcons.bag_badge_plus,
                      height: 60,
                      fontSize: 16,
                      padding: 16,
                      bg: added ? AppColors.ink : AppColors.white,
                      fg: added ? AppColors.white : AppColors.ink,
                      onTap: added ? null : _add,
                    ),
                  ),
                ],
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

/// تقييم مستخدم: الاسم (أو مستخدم مجهول)، النجوم، التاريخ، التعليق
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Semantics(
      label: '${r.displayName}، ${fmtNum(r.stars)} من 5 نجوم، ${agoText(r.daysAgo)}. ${r.text}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r.anonymous ? AppColors.bg : AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: r.anonymous
                        ? const Icon(CupertinoIcons.person_fill, size: 20, color: AppColors.faint)
                        : Text(r.name!.characters.first, style: ts(17, weight: FontWeight.w600, color: AppColors.onAccent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.displayName, style: ts(16, weight: FontWeight.w600)),
                        Text(agoText(r.daysAgo), style: ts(13, color: AppColors.faint)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: i < r.stars ? starColor : AppColors.faint,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.text, style: ts(15, color: AppColors.body, height: 1.7)),
            ],
          ),
        ),
      ),
    );
  }
}
