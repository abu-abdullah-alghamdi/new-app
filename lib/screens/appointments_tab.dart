import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'shell.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  String _filter = 'all';
  int? _day;

  /// السحب لتحت للتحديث (لما يتربط النظام يجيب المواعيد من السيرفر)
  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.sorted
        .where((b) => _filter == 'all' || (_filter == 'upcoming' ? !b.completed : b.completed))
        .where((b) => _day == null || b.dayIndex == _day)
        .toList();

    // المحتوى يمر تحت الساعة والبطارية وهو ينزل (بدون حد يفصلهم)
    return SafeArea(
      top: false,
      bottom: false,
      child: LargeTitleScroll(
        title: 'مواعيدي',
        onRefresh: _refresh,
        bottomSpace: navBottomSpace,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('${monthNames[appToday.month - 1]} ${ar(appToday.year)}', style: ts(17, weight: FontWeight.w500, color: AppColors.body)),
          ),
          HScroll(
            height: 106,
            children: [
              for (var i = -3; i < 14; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: DayPill(
                    top: DayInfo(i).dayNum,
                    bottom: DayInfo(i).short,
                    semanticLabel: DayInfo(i).full,
                    selected: _day == i,
                    dot: s.bookings.any((b) => b.dayIndex == i),
                    onTap: () => setState(() => _day = _day == i ? null : i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          HScroll(
            height: 60,
            children: [
              for (final f in const [('all', 'الكل'), ('upcoming', 'القادمة'), ('completed', 'المكتملة')])
                FilterPill(
                  label: f.$2,
                  selected: _filter == f.$1,
                  onTap: () => setState(() => _filter = f.$1),
                ),
            ],
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(46)),
                child: Column(
                  children: [
                    Text('لا توجد مواعيد هنا', style: ts(22)),
                    const SizedBox(height: 8),
                    Text('غيّر اليوم أو الفلتر، أو احجز موعد جديد', textAlign: TextAlign.center, style: ts(14, color: AppColors.body)),
                    const SizedBox(height: 14),
                    PillButton(label: 'احجز موعد', height: 60, fontSize: 17, onTap: () => s.openDoctors()),
                  ],
                ),
              ),
            ),
          for (final b in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: b.completed
                  ? _AppointmentCard(booking: b)
                  // اسحب البطاقة: تعديل أو إلغاء (مثل البريد والرسائل)
                  : Slidable(
                      key: ValueKey(b.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.46,
                        children: [
                          _SwipeAction(
                            label: 'تعديل',
                            icon: CupertinoIcons.calendar,
                            color: const Color(0xFF8E8E93),
                            onTap: () => openBooking(context, b.doctor, cat: b.cat, editing: b),
                          ),
                          _SwipeAction(
                            label: 'إلغاء',
                            icon: CupertinoIcons.trash,
                            color: AppColors.red,
                            onTap: () => confirmCancelBooking(context, b),
                          ),
                        ],
                      ),
                      child: _AppointmentCard(booking: b),
                    ),
            ),
        ],
      ),
    );
  }
}

/// تأكيد إلغاء الموعد بتنبيه آبل الأصلي
Future<void> confirmCancelBooking(BuildContext context, Booking b) async {
  final s = AppScope.read(context);
  final result = await CNAlert.show<String>(
    context: context,
    title: 'هل تريد إلغاء الموعد؟',
    message: '${b.doctor.name} · ${b.day.full} · ${fmtTime(b.time)}',
    actions: const [
      CNAlertAction(label: 'تراجع', isCancel: true),
      CNAlertAction(label: 'إلغاء الموعد', value: 'cancel', isDestructive: true),
    ],
  );
  if (result?.value == 'cancel') {
    HapticFeedback.mediumImpact();
    s.cancelBooking(b.id);
  }
}

/// زر يطلع لما تسحب بطاقة الموعد
class _SwipeAction extends StatelessWidget {
  const _SwipeAction({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomSlidableAction(
        onPressed: (_) => onTap(),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(40)),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.white),
              const SizedBox(height: 6),
              Text(label, style: ts(15, weight: FontWeight.w500, color: AppColors.white)),
            ],
          ),
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final d = b.doctor;
    Widget bottom;
    if (b.completed) {
      bottom = PillButton(
        label: 'احجز مرة ثانية',
        onTap: () => openBooking(context, d, cat: b.cat, day: firstOpenDay()),
      );
    } else {
      bottom = Row(
        children: [
          // الاتجاهات للفرع (خرائط آبل)
          CircleButton(
            icon: CupertinoIcons.location_fill,
            size: 58,
            bg: AppColors.ink,
            fg: AppColors.white,
            semanticLabel: 'الاتجاهات إلى ${b.branch.name}',
            onTap: () => launchUrl(b.branch.mapsUri, mode: LaunchMode.externalApplication),
          ),
          const SizedBox(width: 6),
          Expanded(child: PillButton(label: 'إعادة جدولة', onTap: () => openBooking(context, d, cat: b.cat, editing: b))),
          const SizedBox(width: 6),
          PillButton(
            label: 'إلغاء',
            bg: AppColors.bg,
            fg: AppColors.red,
            fontSize: 16,
            padding: 22,
            onTap: () => confirmCancelBooking(context, b),
          ),
        ],
      );
    }

    return CutCard(
      image: d.image,
      imageHeight: 276,
      bottom: bottom,
      children: [
        Text('${d.n1}\n${d.n2}', style: ts(32, height: 1.2)),
        const SizedBox(height: 4),
        Text(d.role, style: ts(15, color: AppColors.body)),
        const SizedBox(height: 12),
        Text(b.completed ? 'مكتمل' : 'قادم', style: ts(28, color: b.completed ? AppColors.green : AppColors.blue)),
        Text(b.title, style: ts(15)),
        Text(b.day.full, style: ts(15, weight: FontWeight.w500)),
        Text(b.range, style: ts(15)),
        const SizedBox(height: 4),
        Text(b.branch.name, style: ts(15, weight: FontWeight.w600)),
      ],
    );
  }
}
