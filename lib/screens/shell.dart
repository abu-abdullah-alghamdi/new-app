import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account_tab.dart';
import 'appointments_tab.dart';
import 'doctors_tab.dart';
import 'home_tab.dart';

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
              children: const [HomeTab(), AppointmentsTab(), DoctorsTab(), AccountTab()],
            ),
          ),
          // تلاشي المحتوى تحت شريط الحالة وتحت الشريط العائم (scroll edge effect)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 8,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg, bg.withAlpha(0)],
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
        boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: solid ? box : BackdropFilter(filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26), child: box),
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
      return Pressable(
        onTap: () => s.setTab(i),
        semanticLabel: label,
        selected: active,
        child: AnimatedContainer(
          duration: motion(context, 250),
          curve: Curves.easeOut,
          width: 84,
          height: 56,
          decoration: BoxDecoration(
            color: active ? AppColors.glassActive : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2))] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon(c, active),
              const SizedBox(height: 2),
              Text(label, style: ts(11, weight: FontWeight.w600, color: c)),
            ],
          ),
        ),
      );
    }

    // أسماء الشريط ما تكبر مع تكبير الخط (مثل شريط آبل)، وتبقى 11 كحد أدنى
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _Glass(
              radius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tab(0, 'الرئيسية', (c, a) => Icon(a ? Icons.home_rounded : Icons.home_outlined, size: 23, color: c)),
                    const SizedBox(width: 2),
                    tab(1, 'مواعيدي', (c, a) => Icon(a ? Icons.calendar_month_rounded : Icons.calendar_month_outlined, size: 23, color: c)),
                    const SizedBox(width: 2),
                    tab(3, 'حسابي', (c, a) => Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                          child: Text(s.initial, style: ts(12, weight: FontWeight.w700, color: AppColors.onAccent)),
                        )),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // زر البحث المنفصل في الطرف (مكانه المعتمد عند آبل)
            Pressable(
              onTap: () => s.openDoctors(),
              semanticLabel: 'البحث عن طبيب',
              selected: s.tab == 2,
              child: _Glass(
                radius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: AnimatedContainer(
                      duration: motion(context, 250),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: s.tab == 2 ? AppColors.glassActive : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.search, size: 24, color: s.tab == 2 ? AppColors.ink : AppColors.glassLabel),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
