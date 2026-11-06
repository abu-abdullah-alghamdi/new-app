import 'package:flutter/material.dart';

import '../data.dart';
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
  String? _cancelId;

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
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 30, 0, navBottomSpace),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: BigTitle('${monthNames[appToday.month - 1]}\n${ar(appToday.year)}'),
          ),
          const SizedBox(height: 14),
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
                    onTap: () => setState(() {
                      _day = _day == i ? null : i;
                      _cancelId = null;
                    }),
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
                  onTap: () => setState(() {
                    _filter = f.$1;
                    _cancelId = null;
                  }),
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
                    Text('ما فيه مواعيد هنا', style: ts(22)),
                    const SizedBox(height: 8),
                    Text('غيّر اليوم أو الفلتر، أو احجز موعد جديد.', textAlign: TextAlign.center, style: ts(14, color: AppColors.body)),
                    const SizedBox(height: 14),
                    PillButton(label: 'احجز موعد', height: 60, fontSize: 17, onTap: () => s.openDoctors()),
                  ],
                ),
              ),
            ),
          for (final b in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _AppointmentCard(
                booking: b,
                confirmingCancel: _cancelId == b.id,
                onAskCancel: () => setState(() => _cancelId = b.id),
                onKeep: () => setState(() => _cancelId = null),
                onCancel: () {
                  setState(() => _cancelId = null);
                  s.cancelBooking(b.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.booking,
    required this.confirmingCancel,
    required this.onAskCancel,
    required this.onKeep,
    required this.onCancel,
  });

  final Booking booking;
  final bool confirmingCancel;
  final VoidCallback onAskCancel;
  final VoidCallback onKeep;
  final VoidCallback onCancel;

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
    } else if (confirmingCancel) {
      bottom = Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('متأكد تبي تلغي الموعد؟', textAlign: TextAlign.center, style: ts(16, color: AppColors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: PillButton(label: 'تراجع', height: 60, fontSize: 16, bg: AppColors.ink, fg: AppColors.white, onTap: onKeep)),
                const SizedBox(width: 6),
                Expanded(child: PillButton(label: 'نعم، ألغِه', height: 60, fontSize: 16, bg: AppColors.bg, fg: AppColors.red, onTap: onCancel)),
              ],
            ),
          ],
        ),
      );
    } else {
      bottom = Row(
        children: [
          Expanded(child: PillButton(label: 'إعادة جدولة', onTap: () => openBooking(context, d, cat: b.cat, editing: b))),
          const SizedBox(width: 6),
          PillButton(
            label: 'إلغاء',
            bg: AppColors.bg,
            fg: AppColors.red,
            fontSize: 16,
            padding: 22,
            onTap: onAskCancel,
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
        Text('زيارة في العيادة', style: ts(15)),
        Text(b.day.full, style: ts(15, weight: FontWeight.w500)),
        Text(b.range, style: ts(15)),
      ],
    );
  }
}
