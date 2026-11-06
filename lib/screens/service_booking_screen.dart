import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'cart_screen.dart';
import 'confirm_screen.dart';
import 'services_tab.dart';

/// يفتح حجز الخدمة (من صفحة الخدمة أو من السلة)
void openServiceBooking(BuildContext context, List<OrderItem> items, {bool fromCart = false}) {
  Navigator.of(context).push(iosModal(ServiceBookingScreen(items: items, fromCart: fromCart)));
}

/// حجز خدمة: الفرع ← الطبيب ← اليوم ← الوقت
class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key, required this.items, this.fromCart = false});

  final List<OrderItem> items;

  /// true لو الخدمات جاية من السلة (تنفضى السلة بعد الدفع)
  final bool fromCart;

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  String? _branch;
  String? _doctor;
  int? _day;
  int? _time;

  List<Service> get _services => [for (final i in widget.items) i.service];

  @override
  void initState() {
    super.initState();
    final avail = branchesFor(_services);
    if (avail.isNotEmpty) _pickBranch(avail.first.id);
    _day = firstOpenDay();
  }

  void _pickBranch(String id) {
    _branch = id;
    final docs = doctorsFor(_services, id);
    if (!docs.any((d) => d.id == _doctor)) _doctor = docs.isNotEmpty ? docs.first.id : null;
    _time = null;
  }

  bool _taken(int index) => _doctor == null || _day == null || slotTaken(_doctor!, _day!, index);

  void _continue() {
    if (_branch == null || _doctor == null || _day == null || _time == null) return;
    Navigator.of(context).push(iosRoute(ConfirmScreen(
      doctor: doctorById(_doctor!),
      cat: _services.first.cat,
      day: _day!,
      time: _time!,
      branchId: _branch!,
      items: widget.items,
      fromCart: widget.fromCart,
    )));
  }

  Widget _px(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: child);

  Widget _title(String text) => _px(Padding(
        padding: const EdgeInsets.fromLTRB(6, 20, 6, 10),
        child: Semantics(header: true, child: Text(text, style: ts(20, weight: FontWeight.w500))),
      ));

  @override
  Widget build(BuildContext context) {
    final avail = branchesFor(_services);
    final docs = _branch == null ? const <Doctor>[] : doctorsFor(_services, _branch!);
    final subtotal = widget.items.fold(0, (a, b) => a + b.total);
    final ready = _branch != null && _doctor != null && _day != null && _time != null;
    final label = ready ? 'متابعة · ${DayInfo(_day!).label} ${fmtTime(_time!)}' : 'اختر الطبيب واليوم والوقت';

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
                      Expanded(child: Text('حجز الخدمة', textAlign: TextAlign.center, style: ts(18, weight: FontWeight.w500))),
                      const SizedBox(width: 58),
                    ],
                  )),
                  const SizedBox(height: 14),
                  // ملخص الخدمات
                  _px(Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
                    child: Column(
                      children: [
                        for (final it in widget.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                ServiceImage(service: it.service, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${it.service.name}${it.qty > 1 ? ' × ${ar(it.qty)}' : ''}',
                                    style: ts(16, weight: FontWeight.w600),
                                  ),
                                ),
                                Text(money(it.total), style: ts(15)),
                              ],
                            ),
                          ),
                        if (widget.items.length > 1) ...[
                          Divider(color: AppColors.bg, height: 14, thickness: 1.5),
                          amountRow('المجموع', money(subtotal), bold: true),
                        ],
                      ],
                    ),
                  )),
                  if (avail.isEmpty)
                    _px(Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(26)),
                      child: Text(
                        'الخدمات المختارة ما تتوفر مع طبيب واحد في نفس الفرع، احجز كل خدمة بموعد منفصل',
                        style: ts(15, color: AppColors.red, height: 1.7),
                      ),
                    ))
                  else ...[
                    _title('الفرع'),
                    _px(Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final b in avail)
                          FilterPill(label: b.name, selected: _branch == b.id, onTap: () => setState(() => _pickBranch(b.id))),
                      ],
                    )),
                    _title('الطبيب'),
                    for (final d in docs)
                      _px(Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DoctorChoice(
                          doctor: d,
                          selected: _doctor == d.id,
                          onTap: () => setState(() {
                            _doctor = d.id;
                            _time = null;
                          }),
                        ),
                      )),
                    _title('اليوم'),
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
                    _title('الوقت'),
                    _px(Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < slotTimes.length; i++)
                          TimePill(
                            text: fmtTime(slotTimes[i]),
                            selected: _time == slotTimes[i],
                            taken: _taken(i),
                            onTap: () => setState(() => _time = slotTimes[i]),
                          ),
                      ],
                    )),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: label,
                  icon: CupertinoIcons.calendar,
                  height: 66,
                  fontSize: 17,
                  enabled: ready,
                  onTap: _continue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// اختيار الطبيب (صورة، اسم، تخصص، تقييم)
class _DoctorChoice extends StatelessWidget {
  const _DoctorChoice({required this.doctor, required this.selected, required this.onTap});

  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = doctor;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '${d.name}، ${d.role}، التقييم ${d.ratingText}',
      child: AnimatedContainer(
        duration: motion(context, 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
              child: Image.asset(d.image, fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: ts(16, weight: FontWeight.w600)),
                  Text(d.role, style: ts(13, color: AppColors.body)),
                ],
              ),
            ),
            const Icon(Icons.star_rounded, size: 17, color: starColor),
            const SizedBox(width: 3),
            Text(d.ratingText, style: ts(14, weight: FontWeight.w600)),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: motion(context, 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? AppColors.lime : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 18, color: AppColors.onAccent) : null,
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
