import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data.dart';
import 'theme.dart';

/// يحوّل أي رقم عربي يكتبه المستخدم (٠١٢…) إلى إنجليزي (012…) أثناء الكتابة
class WesternDigits extends TextInputFormatter {
  const WesternDigits();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = en(newValue.text);
    if (text == newValue.text) return newValue;
    return newValue.copyWith(text: text);
  }
}

/// نمط الخط الموحد للتطبيق (IBM Plex Sans Arabic)
TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  TextDecoration? decoration,
}) {
  final c = color ?? AppColors.ink;
  return GoogleFonts.ibmPlexSansArabic(
    fontSize: size,
    fontWeight: weight,
    color: c,
    height: height,
    decoration: decoration,
    decorationColor: c,
  );
}

/// لون النص المناسب فوق خلفية معيّنة
Color _fgFor(Color bg) => bg == AppColors.lime ? AppColors.onAccent : AppColors.ink;

/// يصغّر العنصر شوي عند الضغط مثل أزرار iOS (إلا إذا "تقليل الحركة" مفعّل)
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;
  final bool? selected;

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
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: active,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down && !reduce ? 0.96 : 1,
          duration: motion(context, 120),
          child: AnimatedOpacity(
            opacity: _down && reduce ? 0.6 : 1,
            duration: Duration.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// زر كبسولة (ارتفاعه يكبر مع تكبير الخط)
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg,
    this.fg,
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
  final Color? bg;
  final Color? fg;
  final IconData? icon;
  final double height;
  final bool enabled;
  final double fontSize;
  final FontWeight weight;
  final BoxBorder? border;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final base = bg ?? AppColors.lime;
    final b = enabled ? base : AppColors.disabled;
    final f = enabled ? (fg ?? _fgFor(base)) : AppColors.disabledText;
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: motion(context, 250),
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
        decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(999), border: border),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: f, size: 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(label, textAlign: TextAlign.center, style: ts(fontSize, weight: weight, color: f), maxLines: 2),
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
    this.bg,
    this.fg,
    this.semanticLabel,
    this.border,
    this.enabled = true,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? bg;
  final Color? fg;
  final String? semanticLabel;
  final BoxBorder? border;
  final bool enabled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final base = bg ?? AppColors.white;
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      semanticLabel: semanticLabel,
      child: AnimatedContainer(
        duration: motion(context, 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled ? base : AppColors.disabled,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Icon(icon, color: enabled ? (fg ?? _fgFor(base)) : AppColors.disabledText, size: iconSize),
      ),
    );
  }
}

/// زر الرجوع (السهم يتبع اتجاه العربي تلقائياً) أو الإغلاق في النوافذ المنبثقة
class BackCircle extends StatelessWidget {
  const BackCircle({super.key, this.onTap, this.close = false});

  final VoidCallback? onTap;
  final bool close;

  @override
  Widget build(BuildContext context) => CircleButton(
        icon: close ? CupertinoIcons.xmark : CupertinoIcons.back,
        semanticLabel: close ? 'إغلاق' : 'رجوع',
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
      );
}

/// العنوان الكبير
class BigTitle extends StatelessWidget {
  const BigTitle(this.text, {super.key, this.size = 42});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Semantics(
          header: true,
          child: Text(text, style: ts(size, color: AppColors.title, height: 1.15)),
        ),
      );
}

/// بطاقة كبيرة وصورة الطبيب مقصوصة في الطرف الأيسر
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
    // مع تكبير الخط، نوسّع عمود النص ونصغّر الصورة عشان ما يتداخلون
    final scale = (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(1.0, 2.0);
    final tw = (textWidth * scale).clamp(textWidth, 300.0);
    final iw = scale > 1.35 ? imageWidth * 0.75 : imageWidth;
    final ih = scale > 1.35 ? imageHeight * 0.75 : imageHeight;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? cardShadow : null,
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -14,
            bottom: 0,
            width: iw,
            height: ih,
            child: ExcludeSemantics(
              child: Image.asset(image, fit: BoxFit.contain, alignment: Alignment.bottomLeft),
            ),
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
                    width: tw,
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
    required this.semanticLabel,
    this.closed = false,
    this.dot = false,
    this.onTap,
  });

  final String top;
  final String bottom;
  final bool selected;
  final bool closed;
  final bool dot;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final bg = selected ? AppColors.lime : (closed ? AppColors.closed : AppColors.white);
    final fg = selected ? AppColors.onAccent : (closed ? AppColors.closedText : AppColors.ink);
    return Pressable(
      onTap: onTap,
      enabled: !closed,
      selected: selected,
      semanticLabel: '$semanticLabel${closed ? '، مغلق' : ''}${dot ? '، فيه موعد' : ''}',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: AnimatedContainer(
          duration: motion(context, 250),
          width: 70 * s,
          height: 100 * s,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: pillShadow,
            border: selected && highContrast(context) ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(top, style: ts(21, weight: FontWeight.w500, color: fg)),
              const SizedBox(height: 2),
              Text(bottom, style: ts(13, color: fg)),
              if (dot) ...[
                const SizedBox(height: 4),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
              ],
            ],
          ),
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
        selected: selected,
        semanticLabel: label,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: AnimatedContainer(
            duration: motion(context, 250),
            height: 60 * uiScale(context),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.ink : AppColors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label, style: ts(16, color: selected ? AppColors.white : AppColors.ink)),
          ),
        ),
      );
}

/// صف أفقي يتمرر بعرض الشاشة (ارتفاعه يكبر شوي مع تكبير الخط)
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.height, required this.children, this.gap = 8});

  final double height;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height * uiScale(context),
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

/// مفتاح تشغيل وإيقاف
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
            duration: motion(context, 220),
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.ink : AppColors.switchOff,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: motion(context, 220),
              curve: Curves.easeOut,
              alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? AppColors.lime : const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
}

/// مربع اختيار
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: motion(context, 200),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: value ? AppColors.lime : AppColors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: value ? const Icon(Icons.check_rounded, size: 18, color: AppColors.onAccent) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
}

/// حقل إدخال كبسولة
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
        borderSide: BorderSide(color: AppColors.ink, width: 2),
      ),
    );

/// نافذة منبثقة من تحت بأسلوب iOS (نستخدمها للإشعارات والخيارات)
Future<void> showAppSheet(BuildContext context, {required String title, required List<Widget> children}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: ts(22, weight: FontWeight.w500))),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    ),
  );
}
