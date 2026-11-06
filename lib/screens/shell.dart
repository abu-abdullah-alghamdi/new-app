import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account_tab.dart';
import 'appointments_tab.dart';
import 'doctors_tab.dart';
import 'home_tab.dart';
import 'services_tab.dart';

/// الهيكل الرئيسي: التبويبات + الشريط الزجاجي العائم
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final bg = AppColors.bg;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: s.tab,
              children: [
                // كل تبويب يعيد رسم نفسه بس وهو ظاهر، والمخفي توقف حركاته
                for (final (i, tab) in const <Widget>[HomeTab(), AppointmentsTab(), DoctorsTab(), AccountTab(), ServicesTab()].indexed)
                  TabScope(
                    state: s,
                    active: s.tab == i,
                    version: s.version,
                    child: TickerMode(enabled: s.tab == i, child: RepaintBoundary(child: tab)),
                  ),
              ],
            ),
          ),
          // تلاشي المحتوى تحت شريط الحالة وتحت الشريط العائم (scroll edge effect)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg.withAlpha(225), bg.withAlpha(150), bg.withAlpha(0)],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [bg.withAlpha(235), bg.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
          // شريط "عرض السلة" فوق الشريط العائم في صفحة الخدمات (يطلع بعد أول إضافة)
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 86),
                child: AnimatedSwitcher(
                  duration: motion(context, 250),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: s.tab == 4 && s.cartCount > 0
                      ? CartBar(key: const ValueKey('cart-bar'), count: s.cartCount, subtotal: s.cartSubtotal)
                      : const SizedBox(key: ValueKey('no-bar'), width: double.infinity),
                ),
              ),
            ),
          ),
          const Positioned(left: 16, right: 16, bottom: 0, child: SafeArea(top: false, child: GlassNavBar())),
        ],
      ),
    );
  }
}

/// المساحة السفلية اللي تخليها كل صفحة عشان الشريط العائم ما يغطي المحتوى
const navBottomSpace = 130.0;

class _Glass extends StatelessWidget {
  const _Glass({required this.child, required this.radius});

  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    // مع "زيادة التباين" نستخدم خلفية معتمة وحد واضح بدل الزجاج الشفاف
    final solid = highContrast(context);
    final box = Container(
      decoration: BoxDecoration(
        color: solid ? AppColors.white : AppColors.glassFill,
        borderRadius: radius,
        border: Border.all(color: solid ? AppColors.ink : AppColors.glassBorder, width: solid ? 1.5 : 1),
      ),
      child: child,
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: solid ? box : BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: RepaintBoundary(child: box)),
      ),
    );
  }
}

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    Widget tab(int i, String label, Widget Function(Color c, bool active) icon) {
      final active = s.tab == i;
      final c = active ? AppColors.ink : AppColors.glassLabel;
      return Expanded(
        child: Pressable(
          onTap: () => i == 2 ? s.openDoctors() : s.setTab(i),
          semanticLabel: i == 4 && s.cartCount > 0 ? '$label، في السلة ${ar(s.cartCount)}' : label,
          selected: active,
          // الخلفية البيضاء للتبويب المختار صارت كبسولة وحدة تنزلق (تحت)، هنا الأيقونة والاسم بس
          child: SizedBox(
            height: 56,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: c),
              duration: motion(context, 220),
              builder: (context, col, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(col ?? c, active),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, style: ts(11, weight: FontWeight.w600, color: col ?? c)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ترتيب التبويبات في الشريط (من اليمين) ومكان الكبسولة المنزلقة
    const order = [0, 2, 4, 1, 3];
    final slot = order.indexOf(s.tab).clamp(0, order.length - 1).toDouble();

    // أسماء الشريط ما تكبر مع تكبير الخط (مثل شريط آبل)، وتبقى 11 كحد أدنى
    // كل الأزرار داخل كبسولة زجاجية وحدة (من اليمين): الرئيسية، الأطباء، الخدمات، مواعيدي، حسابي
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _Glass(
          radius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth / order.length;
                return Stack(
                  children: [
                    // الكبسولة البيضاء: تنزلق من التبويب القديم للجديد (فورية مع "تقليل الحركة")
                    AnimatedPositionedDirectional(
                      duration: motion(context, 320),
                      curve: Curves.easeOutCubic,
                      start: slot * w,
                      top: 0,
                      bottom: 0,
                      width: w,
                      child: const _ActivePill(),
                    ),
                    Row(
              children: [
                tab(0, 'الرئيسية', (c, a) => Icon(a ? Icons.home_rounded : Icons.home_outlined, size: 23, color: c)),
                tab(2, 'الأطباء', (c, a) => Icon(a ? Icons.medical_services_rounded : Icons.medical_services_outlined, size: 23, color: c)),
                tab(4, 'الخدمات', (c, a) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(a ? Icons.grid_view_rounded : Icons.grid_view_outlined, size: 23, color: c),
                        // نقطة صغيرة إذا فيه شي في السلة
                        if (s.cartCount > 0)
                          PositionedDirectional(
                            top: -3,
                            end: -5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.ink, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    )),
                tab(1, 'مواعيدي', (c, a) => Icon(a ? Icons.calendar_month_rounded : Icons.calendar_month_outlined, size: 23, color: c)),
                tab(3, 'حسابي', (c, a) => Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                      child: Text(s.initial, style: ts(12, weight: FontWeight.w700, color: AppColors.onAccent)),
                    )),
              ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// الكبسولة البيضاء خلف التبويب المختار
class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glassActive,
          borderRadius: BorderRadius.circular(999),
          border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
      );
}
