import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../services_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'services_tab.dart';

/// المفضلة: الأطباء والخدمات (تفتح من قلب الصفحة الرئيسية)
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _tab = 0; // 0 الأطباء، 1 الخدمات

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final docs = doctors.where((d) => s.favDoctors.contains(d.id)).toList();
    final svs = services.where((x) => s.favServices.contains(x.id)).toList();

    Widget seg(int i, String label) => Expanded(
          child: Pressable(
            onTap: () => setState(() => _tab = i),
            selected: _tab == i,
            semanticLabel: label,
            child: AnimatedContainer(
              duration: motion(context, 200),
              constraints: const BoxConstraints(minHeight: 54),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tab == i ? AppColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: ts(16, weight: FontWeight.w500, color: _tab == i ? AppColors.white : AppColors.ink),
              ),
            ),
          ),
        );

    Widget empty(String text, String button, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Icon(CupertinoIcons.heart, size: 40, color: AppColors.faint),
              ),
              const SizedBox(height: 16),
              Text('ما أضفت شيئاً للمفضلة حتى الآن', style: ts(21)),
              const SizedBox(height: 6),
              Text(text, textAlign: TextAlign.center, style: ts(15, color: AppColors.body, height: 1.6)),
              const SizedBox(height: 20),
              PillButton(label: button, height: 56, fontSize: 16, onTap: onTap),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
            const SizedBox(height: 18),
            const BigTitle('المفضلة', size: 40),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  seg(0, 'الأطباء'),
                  const SizedBox(width: 4),
                  seg(1, 'الخدمات'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_tab == 0)
              ...(docs.isEmpty
                  ? <Widget>[
                      empty('اضغط القلب على أي طبيب ليظهر هنا', 'تصفح الأطباء', () {
                        Navigator.of(context).pop();
                        s.openDoctors();
                      }),
                    ]
                  : <Widget>[
                      for (final d in docs) ...[_DoctorFavCard(doctor: d), const SizedBox(height: 10)],
                    ])
            else
              ...(svs.isEmpty
                  ? <Widget>[
                      empty('اضغط القلب على أي خدمة لتظهر هنا', 'تصفح الخدمات', () {
                        Navigator.of(context).pop();
                        s.setTab(4);
                      }),
                    ]
                  : <Widget>[
                      for (final x in svs) ...[ServiceCard(service: x), const SizedBox(height: 10)],
                    ]),
          ],
        ),
      ),
    );
  }
}

/// بطاقة طبيب مختصرة في المفضلة
class _DoctorFavCard extends StatelessWidget {
  const _DoctorFavCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = doctor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openBooking(context, d),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(32),
          border: highContrast(context) ? Border.all(color: AppColors.ink, width: 1.5) : null,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: DoctorAvatar(doctor: d, size: 84),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                button: true,
                hint: 'فتح صفحة الطبيب والحجز',
                onTap: () => openBooking(context, d),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: ts(18, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(d.role, style: ts(14, color: AppColors.body)),
                      const SizedBox(height: 6),
                      Semantics(
                        label: 'التقييم ${d.ratingText} من 5',
                        child: ExcludeSemantics(child: RatingRow(rating: d.ratingText, reviews: d.reviews)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            FavButton(
              active: true,
              name: d.name,
              size: 44,
              bg: AppColors.bg,
              onTap: () => s.toggleFavDoctor(d.id),
            ),
          ],
        ),
      ),
    );
  }
}
