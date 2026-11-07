import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../native.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'confirm_screen.dart';
import 'done_screen.dart';

/// يفتح الحجز كنافذة كاملة من تحت (مهمة مؤقتة تغطي الشريط السفلي، مع زر إغلاق)
void openBooking(BuildContext context, Doctor doctor, {String? cat, Booking? editing, int? day}) {
  Navigator.of(context).push(iosModal(BookingScreen(doctor: doctor, cat: cat, editing: editing, initialDay: day)));
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.doctor, this.cat, this.editing, this.initialDay});

  final Doctor doctor;
  final String? cat;
  final Booking? editing;
  final int? initialDay;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int? _day;
  int? _time;
  late String _branch;
  bool _more = false;

  Doctor get d => widget.doctor;
  Booking? get editing => widget.editing;
  String get cat => (widget.cat != null && d.cats.contains(widget.cat)) ? widget.cat! : d.cats.first;

  @override
  void initState() {
    super.initState();
    final mine = branchesOf(d.id);
    _branch = editing?.branchId ?? (mine.isNotEmpty ? mine.first.id : branches.first.id);
    if (editing != null) {
      _day = editing!.dayIndex;
      _time = editing!.time;
    } else {
      _day = widget.initialDay ?? d.nextDay;
    }
  }

  bool _taken(int index) {
    if (_day == null) return true;
    final t = slotTimes[index];
    final isOriginal = editing != null && editing!.dayIndex == _day && editing!.time == t && editing!.doctorId == d.id;
    return !isOriginal && slotTaken(d.id, _day!, index);
  }

  void _continue() {
    if (_day == null || _time == null) return;
    final s = AppScope.read(context);
    if (editing != null) {
      final b = s.updateBooking(editing!.id, doctorId: d.id, cat: cat, day: _day!, time: _time!, branchId: _branch);
      Navigator.of(context).pushReplacement(iosRoute(DoneScreen(booking: b, edited: true)));
    } else {
      Navigator.of(context).push(iosRoute(ConfirmScreen(doctor: d, cat: cat, day: _day!, time: _time!, branchId: _branch)));
    }
  }

  Widget _px(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: child);

  @override
  Widget build(BuildContext context) {
    final indexes = List.generate(slotTimes.length, (i) => i);
    final freeCount = indexes.where((i) => !_taken(i)).length;
    final canBook = _day != null && _time != null;
    final label = !canBook
        ? (_day == null ? 'اختر اليوم والوقت' : 'اختر الوقت')
        : '${editing != null ? 'حفظ: ' : 'احجز '}${DayInfo(_day!).label} ${fmtTime(_time!)}';
    final about = _more || d.about.length <= 95 ? d.about : '${d.about.substring(0, 95)}…';
    final s = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
                children: [
                  _px(Row(
                    children: [
                      const BackCircle(close: true),
                      Expanded(
                        child: Text(
                          editing != null ? 'إعادة جدولة' : 'حجز موعد',
                          textAlign: TextAlign.center,
                          style: ts(18, weight: FontWeight.w500),
                        ),
                      ),
                      // مشاركة الطبيب بقائمة آبل الأصلية
                      Builder(
                        builder: (ctx) => CircleButton(
                          icon: CupertinoIcons.share,
                          semanticLabel: 'مشاركة الطبيب',
                          onTap: () => shareText(ctx, shareDoctorText(d)),
                        ),
                      ),
                    ],
                  )),
                  if (editing != null) ...[
                    const SizedBox(height: 14),
                    _px(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        'موعدك الحالي: ${editing!.day.full} · ${fmtTime(editing!.time)}',
                        textAlign: TextAlign.center,
                        style: ts(14, color: AppColors.white),
                      ),
                    )),
                  ],
                  const SizedBox(height: 14),
                  _px(CutCard(
                    image: d.image,
                    corner: FavButton(
                      active: s.favDoctors.contains(d.id),
                      name: d.name,
                      onTap: () => s.toggleFavDoctor(d.id),
                    ),
                    imageWidth: 166,
                    imageHeight: 222,
                    textWidth: 185,
                    padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
                    children: [
                      Text('${d.n1}\n${d.n2}', style: ts(30, height: 1.2)),
                      const SizedBox(height: 6),
                      Text(d.role, style: ts(15, color: AppColors.body)),
                      const SizedBox(height: 10),
                      _RatingLine(doctor: d),
                      const SizedBox(height: 12),
                      Text('${d.years} · ${d.durationText}', style: ts(15, color: AppColors.body)),
                      const SizedBox(height: 4),
                      Text(d.price, style: ts(26)),
                    ],
                  )),
                  const SizedBox(height: 10),
                  _px(_DoctorStats(doctor: d)),
                  const SizedBox(height: 10),
                  _px(Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('عن الطبيب', style: ts(20, weight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        AnimatedSize(
                          duration: motion(context, 250),
                          alignment: Alignment.topCenter,
                          child: Text(about, style: ts(14, color: AppColors.body, height: 1.85)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _more = !_more),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(_more ? 'عرض أقل' : 'اقرأ المزيد', style: ts(15, decoration: TextDecoration.underline)),
                          ),
                        ),
                      ],
                    ),
                  )),
                  // الفروع اللي يداوم فيها الطبيب
                  const SizedBox(height: 18),
                  _px(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('يداوم في', style: ts(20, weight: FontWeight.w500)),
                  )),
                  const SizedBox(height: 10),
                  _px(Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in branchesOf(d.id))
                        FilterPill(label: b.name, selected: _branch == b.id, onTap: () => setState(() => _branch = b.id)),
                    ],
                  )),
                  const SizedBox(height: 18),
                  _px(BigTitle('${monthNames[appToday.month - 1]} ${ar(appToday.year)}', size: 30)),
                  const SizedBox(height: 12),
                  HScroll(
                    height: 106,
                    children: [
                      for (var i = 0; i < 14; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: DayPill(
                            top: DayInfo(i).dayNum,
                            bottom: DayInfo(i).closed ? 'مغلق' : DayInfo(i).short,
                            semanticLabel: DayInfo(i).full,
                            closed: DayInfo(i).closed,
                            selected: _day == i,
                            onTap: () => setState(() {
                              _day = i;
                              _time = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _px(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Text('الأوقات المتاحة', style: ts(20, weight: FontWeight.w500)),
                        const Spacer(),
                        if (_day != null) Text('${ar(freeCount)} أوقات', style: ts(14, color: AppColors.body)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  _px(Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in indexes) TimePill(
                        text: fmtTime(slotTimes[i]),
                        selected: _time == slotTimes[i],
                        taken: _taken(i),
                        onTap: () => setState(() => _time = slotTimes[i]),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: label,
                      icon: CupertinoIcons.calendar,
                      height: 66,
                      fontSize: 17,
                      enabled: canBook,
                      onTap: _continue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleButton(
                    icon: Icons.north_west_rounded,
                    size: 66,
                    bg: AppColors.lime,
                    enabled: canBook,
                    semanticLabel: 'متابعة',
                    onTap: _continue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimePill extends StatelessWidget {
  const TimePill({super.key, required this.text, required this.selected, required this.taken, required this.onTap});

  final String text;
  final bool selected;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.ink : (taken ? AppColors.closed : AppColors.white);
    final fg = selected ? AppColors.white : (taken ? AppColors.closedText : AppColors.ink);
    return Pressable(
      onTap: onTap,
      enabled: !taken,
      selected: selected,
      semanticLabel: '$text${taken ? '، محجوز' : ''}',
      child: AnimatedContainer(
        duration: motion(context, 250),
        constraints: const BoxConstraints(minWidth: 104),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: pillShadow),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: ts(16, weight: FontWeight.w500, color: fg, decoration: taken ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }
}

/// النجمة والتقييم وعدد التقييمات تحت اسم الطبيب
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'التقييم ${doctor.ratingText} من 5، ${ar(doctor.reviews)} تقييم',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFFC107)),
            const SizedBox(width: 4),
            Text(doctor.ratingText, style: ts(16, weight: FontWeight.w600)),
            const SizedBox(width: 4),
            Flexible(child: Text('(${ar(doctor.reviews)} تقييم)', style: ts(14, color: AppColors.body))),
          ],
        ),
      ),
    );
  }
}

/// صف الأرقام: المرضى، سنوات الخبرة، التقييم، التقييمات
class _DoctorStats extends StatelessWidget {
  const _DoctorStats({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_rounded, '${ar(doctor.patients)}+', 'المرضى', '${ar(doctor.patients)} مريض وأكثر'),
      (Icons.verified_rounded, '${ar(doctor.yearsCount)}+', 'سنوات الخبرة', '${ar(doctor.yearsCount)} سنوات خبرة وأكثر'),
      (Icons.star_rounded, doctor.ratingText, 'التقييم', 'التقييم ${doctor.ratingText}'),
      (Icons.chat_bubble_rounded, '${ar(doctor.reviews)}+', 'التقييمات', '${ar(doctor.reviews)} تقييم وأكثر'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40),
        border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, value, label, spoken) in items)
            Expanded(
              child: Semantics(
                label: spoken,
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                        child: Icon(icon, size: 28, color: AppColors.onAccent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        value,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: ts(20, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: ts(13, color: AppColors.body, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
