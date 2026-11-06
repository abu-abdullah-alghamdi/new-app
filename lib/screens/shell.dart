import 'dart:math' as math;
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
          // شريط "عرض السلة" فوق الشريط العائم في صفحة الخدمات (يطلع بعد أول إضافة)
          Positioned(
            left: 16,
            right: 16,
            bottom: navBarBottom + navBarHeight + 10,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.zero,
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
          // الشريط العائم: نازل قريب من حافة الشاشة، والمحتوى يمر تحته بدون تدرج
          const Positioned(left: 24, right: 24, bottom: navBarBottom, child: GlassNavBar()),
        ],
      ),
    );
  }
}

/// المساحة السفلية اللي تخليها كل صفحة عشان الشريط العائم ما يغطي المحتوى
const navBottomSpace = 120.0;

/// ارتفاع الشريط العائم وبعده عن أسفل الشاشة
const navBarHeight = 57.0;
const navBarBottom = 15.0;

/// تشبيع الألوان وإضاءتها (للزجاج: الألوان اللي تحته تطلع حية)
ColorFilter _boost(double sat, double bright) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final sr = (1 - sat) * lr, sg = (1 - sat) * lg, sb = (1 - sat) * lb;
  return ColorFilter.matrix(<double>[
    (sr + sat) * bright, sg * bright, sb * bright, 0, 0, //
    sr * bright, (sg + sat) * bright, sb * bright, 0, 0, //
    sr * bright, sg * bright, (sb + sat) * bright, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

/// زجاج شفاف مثل تطبيقات آبل: ضبابية خفيفة جداً، ألوان مشبّعة، وحد أبيض رفيع
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
        border: Border.all(color: solid ? AppColors.ink : AppColors.glassBorder, width: solid ? 1.5 : 0.75),
      ),
      // حافة داخلية رفيعة جداً تعطي إحساس الانكسار
      foregroundDecoration: solid
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: const Color(0x2EFFFFFF), width: 1.5),
            ),
      child: child,
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x21000000), blurRadius: 22, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: solid
            ? box
            : BackdropFilter(
                filter: ImageFilter.compose(outer: _boost(1.9, 1.04), inner: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5)),
                child: RepaintBoundary(child: box),
              ),
      ),
    );
  }
}

/// ترتيب التبويبات في الشريط (من اليمين): الرئيسية، الأطباء، الخدمات، مواعيدي، حسابي
const _order = [0, 2, 4, 1, 3];

class GlassNavBar extends StatefulWidget {
  const GlassNavBar({super.key});

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  // فقاعة الزجاج اللي تنزلق بين التبويبات لحظة الضغط
  late final AnimationController _lens = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  double _from = 0;
  double _to = 0;

  @override
  void dispose() {
    _lens.dispose();
    super.dispose();
  }

  void _go(AppState s, int tab) {
    final from = _order.indexOf(s.tab).toDouble();
    final to = _order.indexOf(tab).toDouble();
    if (from != to && from >= 0 && !MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _from = from;
        _to = to;
      });
      _lens.forward(from: 0);
    }
    tab == 2 ? s.openDoctors() : s.setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    Widget tab(int i, String label, Widget Function(Color c, bool active) icon) {
      final active = s.tab == i;
      final c = active ? AppColors.ink : AppColors.glassLabel;
      return Expanded(
        child: Pressable(
          onTap: () => _go(s, i),
          semanticLabel: i == 4 && s.cartCount > 0 ? '$label، في السلة ${ar(s.cartCount)}' : label,
          selected: active,
          child: SizedBox(
            height: navBarHeight - 8,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: c),
              duration: motion(context, 220),
              builder: (context, col, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(col ?? c, active),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, style: ts(11, weight: active ? FontWeight.w700 : FontWeight.w500, color: col ?? c)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final slot = _order.indexOf(s.tab).clamp(0, _order.length - 1).toDouble();
    const padH = 9.0;

    // أسماء الشريط ما تكبر مع تكبير الخط (مثل شريط آبل)، وتبقى 11 كحد أدنى
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        height: navBarHeight,
        child: LayoutBuilder(
          builder: (context, outer) {
            final w = (outer.maxWidth - padH * 2) / _order.length;
            return AnimatedBuilder(
              animation: _lens,
              builder: (context, _) {
                final running = _lens.isAnimating;
                final t = Curves.easeInOutCubic.transform(_lens.value);
                // الكبسولة تختفي وقت ما تنزلق الفقاعة، وترجع لما توصل
                final pillOpacity = running ? (t > 0.85 ? (t - 0.85) / 0.15 : 0.0) : 1.0;
                final lensOpacity = running ? (t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1.0)) : 0.0;
                final pos = _from + (_to - _from) * t;
                final stretch = 1 + 0.18 * math.sin(math.pi * t);
                const lensW = 84.0, lensH = 80.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Glass(
                      radius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: padH, vertical: 4),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // الكبسولة الشفافة خلف الزر المختار (أعرض من الزر شوي)
                            AnimatedPositionedDirectional(
                              duration: motion(context, 320),
                              curve: Curves.easeOutCubic,
                              start: slot * w - 4,
                              top: 0,
                              bottom: 0,
                              width: w + 8,
                              child: Opacity(opacity: pillOpacity, child: const _ActivePill()),
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
                                      decoration: BoxDecoration(
                                        color: AppColors.lime,
                                        shape: BoxShape.circle,
                                        border: a ? Border.all(color: AppColors.ink, width: 1.5) : null,
                                      ),
                                      child: Text(s.initial, style: ts(12, weight: FontWeight.w700, color: AppColors.onAccent)),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // فقاعة الزجاج: أكبر من الشريط، تنزلق وتتمدد شوي ثم تختفي
                    if (lensOpacity > 0)
                      PositionedDirectional(
                        start: padH + pos * w + w / 2 - lensW / 2,
                        top: (navBarHeight - lensH) / 2,
                        width: lensW,
                        height: lensH,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: lensOpacity,
                            child: Transform.scale(scaleX: stretch, scaleY: 1 - (stretch - 1) * 0.4, child: const _Lens()),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// الكبسولة خلف التبويب المختار: زجاج أبيض شفاف بحد لامع
class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glassActive,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: highContrast(context) ? AppColors.ink : const Color(0xD9FFFFFF),
            width: highContrast(context) ? 1.5 : 1,
          ),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
      );
}

/// فقاعة الزجاج وقت الانتقال
class _Lens extends StatelessWidget {
  const _Lens();

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(999);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.compose(outer: _boost(1.6, 1.08), inner: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: const RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.0,
                colors: [Color(0x8CFFFFFF), Color(0x1FFFFFFF), Color(0x47FFFFFF)],
                stops: [0, 0.6, 1],
              ),
              border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
