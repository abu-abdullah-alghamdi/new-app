import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../main.dart';
import '../native.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart_screen.dart';
import 'service_booking_screen.dart';
import 'service_screen.dart';
import 'shell.dart';

const starColor = Color(0xFFFFB800);

/// المسافة اللي ياخذها شريط "عرض السلة" فوق الشريط العائم
const cartBarSpace = 74.0;

/// شريط "عرض السلة": عدد العناصر في مربع، وكلمة عرض السلة، والمجموع
class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.count, required this.subtotal});

  final int count;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Pressable(
        onTap: () => Navigator.of(context).push(iosRoute(const CartScreen())),
        semanticLabel: 'عرض السلة، ${fmtNum(count)} عناصر، المجموع ${money(subtotal)}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 22, 10),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(14)),
                child: Text(fmtNum(count), style: ts(18, weight: FontWeight.w700, color: AppColors.onAccent)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('عرض السلة', style: ts(17, weight: FontWeight.w600, color: AppColors.white))),
              Text(money(subtotal), style: ts(17, weight: FontWeight.w600, color: AppColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحة الخدمات: قائمة الخدمات وزر السلة
class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = servicesIn(s.serviceCatFilter);
    // العنوان الكبير يتعامل مع الساعة فوق، والـ SafeArea للأطراف بس
    return SafeArea(
      top: false,
      bottom: false,
      child: LargeTitleScroll(
        title: 'الخدمات',
        trailing: CartButton(count: s.cartCount, size: 40),
        // لما يطلع شريط "عرض السلة" نزيد المسافة تحت عشان ما يغطي آخر خدمة
        bottomSpace: navBottomSpace + (s.cartCount > 0 ? cartBarSpace * uiScale(context).clamp(1.0, 1.6) : 0),
        children: [
          px(Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Text('اختر الخدمة وأضفها للسلة، وبعدها اختر الفرع وطريقة الدفع', style: ts(15, color: AppColors.body, height: 1.7)),
          )),
          // فلترة حسب التخصص
          HScroll(
            height: 60,
            children: [
              for (final f in categoryFilters)
                FilterPill(label: f.label, selected: s.serviceCatFilter == f.id, onTap: () => s.setServiceCat(f.id)),
            ],
          ),
          const SizedBox(height: 8),
          for (final sv in list) ...[
            px(PeekMenu(
              actions: [
                PeekAction('احجز الخدمة', CupertinoIcons.calendar, () => openServiceBooking(context, [OrderItem(sv, 1)])),
                PeekAction('أضف إلى السلة', CupertinoIcons.bag_badge_plus, () {
                  s.addToCart(sv.id);
                  HapticFeedback.lightImpact();
                }),
                PeekAction(
                  s.favServices.contains(sv.id) ? 'إزالة من المفضلة' : 'أضف للمفضلة',
                  s.favServices.contains(sv.id) ? CupertinoIcons.heart_slash : CupertinoIcons.heart,
                  () => s.toggleFavService(sv.id),
                ),
                PeekAction('مشاركة', CupertinoIcons.share, () => shareText(context, shareServiceText(sv))),
              ],
              child: ServiceCard(service: sv),
            )),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// زر السلة مع عدد العناصر
class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.count, this.size = 58});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).push(iosRoute(const CartScreen())),
      semanticLabel: count == 0 ? 'السلة، فاضية' : 'السلة، ${fmtNum(count)} عناصر',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.bag, size: size * 0.43, color: AppColors.ink),
          ),
          if (count > 0)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
                child: Text(fmtNum(count), style: ts(12, weight: FontWeight.w700, color: AppColors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// نجمة + التقييم + عدد التقييمات
class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.rating, required this.reviews});

  final String rating;
  final int reviews;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 19, color: starColor),
          const SizedBox(width: 3),
          Text(rating, style: ts(14, weight: FontWeight.w600)),
          const SizedBox(width: 4),
          Flexible(child: Text('(${fmtNum(reviews)} تقييم)', style: ts(13, color: AppColors.body))),
        ],
      );
}

/// بطاقة الخدمة: الصورة، الاسم، التوفر، التقييم، السعر، وزر الإضافة
class ServiceCard extends StatefulWidget {
  const ServiceCard({super.key, required this.service});

  final Service service;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> with AddedFlash {
  void _add() {
    AppScope.read(context).addToCart(widget.service.id);
    flashAdded(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    final sv = widget.service;
    final s = AppScope.of(context);
    void open() => Navigator.of(context).push(iosRoute(ServiceScreen(service: sv)));
    // الضغط على البطاقة يفتح صفحة الخدمة (زر + والقلب لهم ضغطتهم الخاصة)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: open,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
      ),
      // مع الخط الكبير جداً البطاقة ترتب نفسها عمودي بدل ما يتقص الكلام
      child: _ServiceCardLayout(
        stacked: MediaQuery.textScalerOf(context).scale(10) > 15,
        image: ServiceImage(service: sv, size: 96),
        body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        hint: 'عرض تفاصيل الخدمة',
                        onTap: open,
                        child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sv.name, style: ts(18, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(CupertinoIcons.location_solid, size: 14, color: sv.allBranches ? AppColors.green : AppColors.faint),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sv.availabilityText,
                              style: ts(13, color: sv.allBranches ? AppColors.green : AppColors.body, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        label: 'التقييم ${sv.ratingText} من 5، ${fmtNum(sv.reviews)} تقييم',
                        child: ExcludeSemantics(child: RatingRow(rating: sv.ratingText, reviews: sv.reviews)),
                      ),
                    ],
                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FavButton(
                      active: s.favServices.contains(sv.id),
                      name: sv.name,
                      size: 44,
                      bg: AppColors.bg,
                      onTap: () => s.toggleFavService(sv.id),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(sv.priceText, style: ts(19, weight: FontWeight.w600)),
                          if (sv.onOffer)
                            Text(sv.oldPriceText, style: ts(13, color: AppColors.faint, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ),
                    // زر الإضافة للسلة: مربع فيه + (يتحول لعلامة صح لحظة بعد الإضافة)
                    Pressable(
                      onTap: _add,
                      semanticLabel: added ? 'انضافت ${sv.name} للسلة' : 'إضافة ${sv.name} إلى السلة',
                      child: AnimatedContainer(
                        duration: motion(context, 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: added ? AppColors.ink : AppColors.lime,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AnimatedSwitcher(
                          duration: motion(context, 180),
                          child: Icon(
                            added ? Icons.check_rounded : Icons.add_rounded,
                            key: ValueKey(added),
                            size: 28,
                            color: added ? AppColors.white : AppColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
      ),
    );
  }
}

class _ServiceCardLayout extends StatelessWidget {
  const _ServiceCardLayout({required this.stacked, required this.image, required this.body});

  final bool stacked;
  final Widget image;
  final Widget body;

  @override
  Widget build(BuildContext context) => stacked
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [image, const SizedBox(height: 12), body],
        )
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [image, const SizedBox(width: 14), Expanded(child: body)],
        );
}
