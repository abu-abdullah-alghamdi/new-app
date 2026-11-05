import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

/// نمط الخط الموحد للتطبيق (IBM Plex Sans Arabic)
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  TextDecoration? decoration,
}) =>
    GoogleFonts.ibmPlexSansArabic(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: color,
    );

/// يصغّر العنصر شوي عند الضغط مثل أزرار iOS
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.enabled = true, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    return Semantics(
      button: true,
      enabled: active,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

/// زر كبسولة
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = AppColors.lime,
    this.fg = AppColors.ink,
    this.icon,
    this.height = 64,
    this.enabled = true,
    this.fontSize = 18,
    this.weight = FontWeight.w500,
    this.border,
    this.padding = 24,
  });

  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double height;
  final bool enabled;
  final double fontSize;
  final FontWeight weight;
  final BoxBorder? border;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final b = enabled ? bg : AppColors.disabled;
    final f = enabled ? fg : AppColors.disabledText;
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(999), border: border),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: f, size: 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(label, style: ts(fontSize, weight: weight, color: f), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر دائري
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 58,
    this.bg = AppColors.white,
    this.fg = AppColors.ink,
    this.semanticLabel,
    this.border,
    this.enabled = true,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color bg;
  final Color fg;
  final String? semanticLabel;
  final BoxBorder? border;
  final bool enabled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      semanticLabel: semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled ? bg : AppColors.disabled,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Icon(icon, color: enabled ? fg : AppColors.disabledText, size: iconSize),
      ),
    );
  }
}

/// زر الرجوع (السهم يتبع اتجاه العربي تلقائياً)
class BackCircle extends StatelessWidget {
  const BackCircle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CircleButton(
        icon: CupertinoIcons.back,
        semanticLabel: 'رجوع',
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
      );
}

/// العنوان الكبير على سطرين
class BigTitle extends StatelessWidget {
  const BigTitle(this.text, {super.key, this.size = 42});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(text, style: ts(size, color: AppColors.title, height: 1.15)),
      );
}

/// بطاقة بيضاء كبيرة وصورة الطبيب مقصوصة في الطرف الأيسر
class CutCard extends StatelessWidget {
  const CutCard({
    super.key,
    required this.image,
    required this.children,
    this.bottom,
    this.imageWidth = 196,
    this.imageHeight = 272,
    this.textWidth = 185,
    this.padding = const EdgeInsets.fromLTRB(26, 30, 26, 22),
    this.radius = 46,
    this.shadow = true,
  });

  final String image;
  final List<Widget> children;
  final Widget? bottom;
  final double imageWidth;
  final double imageHeight;
  final double textWidth;
  final EdgeInsets padding;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? cardShadow : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -14,
            bottom: 0,
            width: imageWidth,
            height: imageHeight,
            child: Image.asset(image, fit: BoxFit.contain, alignment: Alignment.bottomLeft),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: textWidth,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                  ),
                ),
                if (bottom != null) ...[const SizedBox(height: 26), bottom!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// كبسولة يوم طويلة (رقم اليوم واسمه)
class DayPill extends StatelessWidget {
  const DayPill({
    super.key,
    required this.top,
    required this.bottom,
    required this.selected,
    this.closed = false,
    this.dot = false,
    this.onTap,
  });

  final String top;
  final String bottom;
  final bool selected;
  final bool closed;
  final bool dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.lime : (closed ? AppColors.closed : AppColors.white);
    final fg = closed ? AppColors.faint : AppColors.ink;
    return Pressable(
      onTap: onTap,
      enabled: !closed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 70,
        height: 100,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: pillShadow),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(top, style: ts(21, weight: FontWeight.w500, color: fg)),
            const SizedBox(height: 2),
            Text(bottom, style: ts(13, color: fg)),
            if (dot) ...[
              const SizedBox(height: 4),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}

/// كبسولة فلتر (الكل / أسنان ...)
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: ts(16, color: selected ? AppColors.white : AppColors.ink)),
        ),
      );
}

/// صف أفقي يتمرر يميناً ويساراً بعرض الشاشة
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.height, required this.children, this.gap = 8});

  final double height;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          clipBehavior: Clip.none,
          itemCount: children.length,
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (_, i) => children[i],
        ),
      );
}

/// مفتاح تشغيل وإيقاف بنفس ألوان التطبيق
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        child: GestureDetector(
          onTap: onChanged,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.ink : const Color(0xFFD5D8DE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: value ? AppColors.lime : AppColors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      );
}

/// مربع اختيار دائري الحواف
class AppCheck extends StatelessWidget {
  const AppCheck({super.key, required this.value, required this.onChanged, required this.child});

  final bool value;
  final VoidCallback onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        checked: value,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: value ? AppColors.ink : AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: value ? const Icon(Icons.check_rounded, size: 16, color: AppColors.lime) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
}

/// حقل إدخال كبسولة أبيض
InputDecoration pillInput(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: ts(16, color: AppColors.faint),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
      ),
    );
