import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../native.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'shell.dart';

class DoctorsTab extends StatefulWidget {
  const DoctorsTab({super.key});

  @override
  State<DoctorsTab> createState() => _DoctorsTabState();
}

class _DoctorsTabState extends State<DoctorsTab> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = _q.text.trim();
    final list = doctors
        .where((d) => s.doctorCat == null || d.cats.contains(s.doctorCat))
        .where((d) => q.isEmpty || '${d.name} ${d.role}'.contains(q))
        .toList();

    // العنوان الكبير يتعامل مع الساعة فوق، والـ SafeArea للأطراف بس
    return SafeArea(
      top: false,
      bottom: false,
      child: LargeTitleScroll(
        title: 'الأطباء',
        bottomSpace: navBottomSpace,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _q,
              style: ts(16),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: pillInput('اسم الطبيب أو التخصص').copyWith(
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 20, end: 8),
                  child: Icon(CupertinoIcons.search, color: AppColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          HScroll(
            height: 60,
            children: [
              for (final f in categoryFilters)
                FilterPill(label: f.label, selected: s.doctorCat == f.id, onTap: () => s.setDoctorCat(f.id)),
            ],
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(40)),
                child: Text('ما لقينا نتيجة، جرّب اسم أو تخصص ثاني', textAlign: TextAlign.center, style: ts(15, color: AppColors.body)),
              ),
            ),
          for (final d in list)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              // الضغط المطوّل: معاينة وقائمة سريعة
              child: PeekMenu(
                actions: [
                  PeekAction('احجز موعد', CupertinoIcons.calendar, () => openBooking(context, d, cat: s.doctorCat)),
                  PeekAction(
                    s.favDoctors.contains(d.id) ? 'إزالة من المفضلة' : 'أضف للمفضلة',
                    s.favDoctors.contains(d.id) ? CupertinoIcons.heart_slash : CupertinoIcons.heart,
                    () => s.toggleFavDoctor(d.id),
                  ),
                  PeekAction('مشاركة', CupertinoIcons.share, () => shareText(context, shareDoctorText(d))),
                ],
                child: CutCard(
                  image: d.image,
                  textWidth: 180,
                  corner: FavButton(
                    active: s.favDoctors.contains(d.id),
                    name: d.name,
                    onTap: () => s.toggleFavDoctor(d.id),
                  ),
                  bottom: PillButton(label: 'احجز موعد', onTap: () => openBooking(context, d, cat: s.doctorCat)),
                  children: [
                    Text('${d.n1}\n${d.n2}', style: ts(32, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(d.role, style: ts(15, color: AppColors.body)),
                    const SizedBox(height: 14),
                    Text(d.availText, style: ts(26, color: AppColors.green)),
                    Text('زيارة في العيادة · ${d.durationText}', style: ts(15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
