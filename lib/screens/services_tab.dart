import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../main.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart_screen.dart';
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
      maxScaleFactor: 1.3,
      child: Pressable(
        onTap: () => Navigator.of(context).push(iosRoute(const CartScreen())),
        semanticLabel: 'عرض السلة، ${ar(count)} عناصر، المجموع ${money(subtotal)}',
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
                child: Text(ar(count), style: ts(18, weight: FontWeight.w700, color: AppColors.onAccent)),
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
    // المحتوى يمر تحت الساعة والبطارية وهو ينزل (بدون حد يفصلهم)
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        // لما يطلع شريط "عرض السلة" نزيد المسافة تحت عشان ما يغطي آخر خدمة
        padding: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 30, 14, navBottomSpace + (s.cartCount > 0 ? cartBarSpace : 0)),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: BigTitle('الخدمات')),
              CartButton(count: s.cartCount),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 14),
            child: Text('اختر الخدمة وأضفها للسلة، وبعدها اختر الفرع وطريقة الدفع.', style: ts(15, color: AppColors.body, height: 1.7)),
          ),
          for (final sv in services) ...[
            ServiceCard(service: sv),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// زر السلة وعليه عدد العناصر
class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).push(iosRoute(const CartScreen())),
      semanticLabel: count == 0 ? 'السلة، فاضية' : 'السلة، ${ar(count)} عناصر',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            child: Icon(CupertinoIcons.bag, size: 25, color: AppColors.ink),
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
                child: Text(ar(count), style: ts(12, weight: FontWeight.w700, color: AppColors.white)),
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
          Flexible(child: Text('(${ar(reviews)} تقييم)', style: ts(13, color: AppColors.body))),
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

class _ServiceCardState extends State<ServiceCard> {
  bool _added = false;

  void _add() {
    AppScope.read(context).addToCart(widget.service.id);
    HapticFeedback.lightImpact();
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _added = false);
    });
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceImage(service: sv, size: 96),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                        label: 'التقييم ${sv.ratingText} من 5، ${ar(sv.reviews)} تقييم',
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
                    Expanded(child: Text(sv.priceText, style: ts(19, weight: FontWeight.w600))),
                    // زر الإضافة للسلة: مربع فيه + (يتحول لعلامة صح لحظة بعد الإضافة)
                    Pressable(
                      onTap: _add,
                      semanticLabel: _added ? 'انضافت ${sv.name} للسلة' : 'إضافة ${sv.name} إلى السلة',
                      child: AnimatedContainer(
                        duration: motion(context, 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _added ? AppColors.ink : AppColors.lime,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AnimatedSwitcher(
                          duration: motion(context, 180),
                          child: Icon(
                            _added ? Icons.check_rounded : Icons.add_rounded,
                            key: ValueKey(_added),
                            size: 28,
                            color: _added ? AppColors.white : AppColors.onAccent,
                          ),
                        ),
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
