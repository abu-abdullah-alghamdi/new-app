import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'shell.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final next = s.upcoming.isNotEmpty ? s.upcoming.first : null;
    final greet = s.firstName.isNotEmpty ? '${s.firstName}!' : 'نوّرتنا!';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, navBottomSpace),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Pressable(
                  onTap: () => s.setTab(3),
                  semanticLabel: 'حسابي',
                  child: Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                    child: Text(s.initial, style: ts(22, weight: FontWeight.w600, color: AppColors.onAccent)),
                  ),
                ),
                const Spacer(),
                CircleButton(
                  icon: next != null ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
                  semanticLabel: 'الإشعارات',
                  onTap: () => _showNotifications(context, next),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('هلا،\n$greet', style: ts(38, height: 1.25)),
          ),
          const SizedBox(height: 14),
          DoctorPriceCard(doctor: doctors.first),
          const SizedBox(height: 14),
          HScroll(
            height: 236,
            gap: 10,
            children: [
              if (next != null)
                _MiniCard(
                  color: AppColors.lime,
                  title: 'موعدك\nالقادم',
                  body: '${next.serviceName} مع ${next.doctor.name}، ${next.day.full} الساعة ${fmtTime(next.time)}',
                  onArrow: () => s.setTab(1),
                  action: PillButton(
                    label: 'عرض الموعد',
                    height: 52,
                    fontSize: 15,
                    bg: Colors.transparent,
                    fg: AppColors.onAccent,
                    border: Border.all(color: const Color(0x1F000000), width: 1.5),
                    onTap: () => s.setTab(1),
                  ),
                ),
              _MiniCard(
                color: AppColors.white,
                title: 'خصم 30%\nعلى باقة الفحص',
                body: 'فحص شامل وتنظيف للأسنان، العرض لفترة محدودة.',
                action: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PillButton(label: 'احجز العرض', height: 52, fontSize: 15, onTap: () => s.openDoctors('dental')),
                ),
              ),
              _MiniCard(
                color: AppColors.white,
                title: 'تذكير\nعلى واتساب',
                body: 'نرسل لك تذكير قبل موعدك بيوم، وتأكد أو تعدّل بضغطة.',
                action: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: s.remindOnWhatsapp ? AppColors.green : AppColors.faint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s.remindOnWhatsapp ? 'مفعّل' : 'متوقف', style: ts(15, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final d in doctors.skip(1)) ...[
            const SizedBox(height: 14),
            DoctorPriceCard(doctor: d),
          ],
        ],
      ),
    );
  }
}

/// بطاقة طبيب كبيرة: الاسم، التخصص، أقرب موعد، السعر، وزر الحجز
class DoctorPriceCard extends StatelessWidget {
  const DoctorPriceCard({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    void open() => openBooking(context, doctor);
    return CutCard(
      image: doctor.image,
      imageWidth: 200,
      imageHeight: 286,
      textWidth: 180,
      bottom: Row(
        children: [
          Expanded(child: PillButton(label: 'احجز موعد', icon: CupertinoIcons.calendar, onTap: open)),
          const SizedBox(width: 6),
          CircleButton(
            icon: Icons.north_west_rounded,
            size: 64,
            bg: AppColors.lime,
            semanticLabel: 'ملف ${doctor.name}',
            onTap: open,
          ),
        ],
      ),
      children: [
        Text('${doctor.n1}\n${doctor.n2}', style: ts(32, height: 1.2)),
        const SizedBox(height: 6),
        Text(doctor.role, style: ts(15, color: AppColors.body)),
        const SizedBox(height: 18),
        Text(doctor.nextFull, style: ts(15, color: AppColors.body)),
        const SizedBox(height: 4),
        Text(doctor.price, style: ts(28)),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.color, required this.title, required this.body, required this.action, this.onArrow});

  final Color color;
  final String title;
  final String body;
  final Widget action;
  final VoidCallback? onArrow;

  @override
  Widget build(BuildContext context) {
    // فوق الليموني النص دايماً أسود (حتى في الوضع الداكن)
    final onLime = color == AppColors.lime;
    final fg = onLime ? AppColors.onAccent : AppColors.ink;
    final fgBody = onLime ? const Color(0xFF333333) : AppColors.body;
    // البطاقة عرضها ثابت، فنحد تكبير الخط فيها عشان ما يطلع النص برا
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
      width: 286,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(42)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ts(23, height: 1.25, color: fg)),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsetsDirectional.only(end: onArrow != null ? 40 : 0),
                child: Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: ts(14, color: fgBody, height: 1.5)),
              ),
              const Spacer(),
              action,
            ],
          ),
          if (onArrow != null)
            PositionedDirectional(
              end: -8,
              top: -12,
              child: CircleButton(
                icon: Icons.north_west_rounded,
                size: 62,
                bg: Colors.transparent,
                fg: fg,
                border: Border.all(color: const Color(0x1F000000), width: 1.5),
                semanticLabel: 'عرض مواعيدي',
                onTap: onArrow,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// قائمة الإشعارات (تذكير بالموعد القادم)
void _showNotifications(BuildContext context, Booking? next) {
  showAppSheet(
    context,
    title: 'الإشعارات',
    children: [
      if (next == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('ما عندك إشعارات جديدة.', textAlign: TextAlign.center, style: ts(16, color: AppColors.body)),
        )
      else
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.bell_fill, size: 20, color: AppColors.onAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تذكير بموعدك', style: ts(16, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${next.serviceName} مع ${next.doctor.name}، ${next.day.full} الساعة ${fmtTime(next.time)}',
                        style: ts(14, color: AppColors.body, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
    ],
  );
}
