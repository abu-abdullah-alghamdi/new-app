import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';

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
            bottom: MediaQuery.paddingOf(context).bottom + navBarHeight + 8,
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
          // شريط التبويبات الأصلي من آبل (يتعامل مع منطقة الأمان والزجاج والحركة بنفسه)
          const Positioned(left: 0, right: 0, bottom: 0, child: GlassNavBar()),
        ],
      ),
    );
  }
}

/// المساحة السفلية اللي تخليها كل صفحة عشان الشريط ما يغطي المحتوى
const navBottomSpace = 120.0;

/// ارتفاع شريط آبل تقريباً (من فوق الشريط لأسفل الشاشة بدون منطقة الأمان)
const navBarHeight = 62.0;
const navBarBottom = 0.0;

/// ترتيب التبويبات في الشريط (من اليمين): الرئيسية، الأطباء، الخدمات، مواعيدي، حسابي
const _order = [0, 2, 4, 1, 3];

/// حجم أيقونات الشريط (مقاس تطبيقات آبل؛ الأكبر يثقل الخط ويضغط الأسماء)
const _iconSize = 18.0;

/// شريط التبويبات الأصلي من آبل (UITabBar):
/// على iOS 26 يطلع بزجاج آبل وحركتها الأصلية، وعلى الأقدم يرجع شريط Cupertino عادي
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final index = _order.indexOf(s.tab).clamp(0, _order.length - 1);
    return CNTabBar(
      currentIndex: index,
      onTap: (i) {
        final tab = _order[i];
        tab == 2 ? s.openDoctors() : s.setTab(tab);
      },
      tint: AppColors.ink,
      labelFontFamily: appFont,
      labelFontSize: 11,
      iconSize: _iconSize,
      items: [
        const CNTabBarItem(label: 'الرئيسية', icon: CNSymbol('house', size: _iconSize), activeIcon: CNSymbol('house.fill', size: _iconSize)),
        const CNTabBarItem(label: 'الأطباء', icon: CNSymbol('stethoscope', size: _iconSize), activeIcon: CNSymbol('stethoscope', size: _iconSize)),
        CNTabBarItem(
          label: 'الخدمات',
          icon: const CNSymbol('square.grid.2x2', size: _iconSize),
          activeIcon: const CNSymbol('square.grid.2x2.fill', size: _iconSize),
          // نقطة صغيرة إذا فيه شي في السلة
          badge: s.cartCount > 0 ? CNTabBarItem.dotBadge : null,
        ),
        const CNTabBarItem(label: 'مواعيدي', icon: CNSymbol('calendar', size: _iconSize), activeIcon: CNSymbol('calendar', size: _iconSize)),
        const CNTabBarItem(label: 'حسابي', icon: CNSymbol('person.crop.circle', size: _iconSize), activeIcon: CNSymbol('person.crop.circle.fill', size: _iconSize)),
      ],
    );
  }
}
