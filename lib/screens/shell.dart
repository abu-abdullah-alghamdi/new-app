import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account_tab.dart';
import 'appointments_tab.dart';
import 'doctors_tab.dart';
import 'home_tab.dart';

/// الهيكل الرئيسي: أربع تبويبات + الشريط الزجاجي العائم
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: s.tab,
              children: const [HomeTab(), AppointmentsTab(), DoctorsTab(), AccountTab()],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x8CFAFAFC),
              borderRadius: radius,
              border: Border.all(color: const Color(0xB3FFFFFF)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget tab(int i, String label, IconData on, IconData off) {
      final active = s.tab == i;
      return Pressable(
        onTap: () => s.setTab(i),
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 82,
          height: 56,
          decoration: BoxDecoration(
            color: active ? const Color(0xEBFFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2))] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? on : off, size: 23, color: active ? AppColors.ink : const Color(0xFF4D4D4D)),
              const SizedBox(height: 2),
              Text(label, style: ts(10.5, weight: FontWeight.w600, color: active ? AppColors.ink : const Color(0xFF4D4D4D))),
            ],
          ),
        ),
      );
    }

    final accountActive = s.tab == 3;
    return Padding(
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
                  tab(0, 'الرئيسية', Icons.home_rounded, Icons.home_outlined),
                  const SizedBox(width: 2),
                  tab(1, 'مواعيدي', Icons.calendar_month_rounded, Icons.calendar_month_outlined),
                  const SizedBox(width: 2),
                  tab(2, 'الأطباء', Icons.person_search_rounded, Icons.person_search_outlined),
                ],
              ),
            ),
          ),
          const Spacer(),
          Pressable(
            onTap: () => s.setTab(3),
            semanticLabel: 'حسابي',
            child: _Glass(
              radius: BorderRadius.circular(999),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accountActive ? const Color(0xEBFFFFFF) : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: accountActive
                          ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                          child: Text(s.initial, style: ts(13, weight: FontWeight.w700)),
                        ),
                        Text('حسابي', style: ts(10, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
