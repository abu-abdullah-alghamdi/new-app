/// الخدمات والفروع (بيانات تجريبية، تُستبدل ببيانات العيادة الحقيقية قبل النشر)
library;

import 'package:flutter/material.dart';

import 'data.dart';

class Branch {
  const Branch(this.id, this.name);

  final String id;
  final String name;
}

const branches = [
  Branch('rawdah', 'فرع الروضة'),
  Branch('salamah', 'فرع السلامة'),
  Branch('hamdaniyah', 'فرع الحمدانية'),
];

Branch branchById(String id) => branches.firstWhere((b) => b.id == id, orElse: () => branches.first);

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.icon,
    required this.tint,
    this.branchIds,
  });

  final String id;
  final String name;

  /// السعر بالريال
  final int price;
  final double rating;
  final int reviews;

  /// أيقونة مكان صورة الخدمة (لين توصل الصور الحقيقية)
  final IconData icon;
  final Color tint;

  /// null = متوفرة في جميع الفروع
  final List<String>? branchIds;

  bool get allBranches => branchIds == null;
  List<String> get availableIn => branchIds ?? branches.map((b) => b.id).toList();

  String get availabilityText => allBranches
      ? 'متوفرة في جميع الفروع'
      : 'متوفرة في: ${availableIn.map((id) => branchById(id).name).join('، ')}';

  String get priceText => '${ar(price)} ريال';
  String get ratingText => rating.toStringAsFixed(1);
}

const _lime = Color(0xFFE3FF3A);
const _sky = Color(0xFFD7EEFF);
const _peach = Color(0xFFFFE3D3);
const _lilac = Color(0xFFE9E2FF);

const services = [
  Service(
    id: 's1',
    name: 'تنظيف الأسنان',
    price: 200,
    rating: 4.8,
    reviews: 124,
    icon: Icons.clean_hands_rounded,
    tint: _sky,
  ),
  Service(
    id: 's2',
    name: 'تبييض الأسنان',
    price: 900,
    rating: 4.7,
    reviews: 88,
    icon: Icons.auto_awesome_rounded,
    tint: _lime,
    branchIds: ['rawdah', 'salamah'],
  ),
  Service(
    id: 's3',
    name: 'حشوة تجميلية',
    price: 350,
    rating: 4.9,
    reviews: 156,
    icon: Icons.healing_rounded,
    tint: _lilac,
  ),
  Service(
    id: 's4',
    name: 'فحص شامل للأسنان',
    price: 150,
    rating: 4.8,
    reviews: 210,
    icon: Icons.fact_check_rounded,
    tint: _peach,
  ),
  Service(
    id: 's5',
    name: 'استشارة تقويم',
    price: 300,
    rating: 4.9,
    reviews: 97,
    icon: Icons.straighten_rounded,
    tint: _lime,
    branchIds: ['rawdah'],
  ),
  Service(
    id: 's6',
    name: 'تنظيف البشرة',
    price: 300,
    rating: 4.6,
    reviews: 73,
    icon: Icons.face_retouching_natural_rounded,
    tint: _peach,
    branchIds: ['salamah', 'hamdaniyah'],
  ),
  Service(
    id: 's7',
    name: 'جلسة ليزر',
    price: 400,
    rating: 4.7,
    reviews: 64,
    icon: Icons.flash_on_rounded,
    tint: _sky,
    branchIds: ['salamah'],
  ),
  Service(
    id: 's8',
    name: 'علاج تساقط الشعر',
    price: 450,
    rating: 4.5,
    reviews: 41,
    icon: Icons.spa_rounded,
    tint: _lilac,
    branchIds: ['hamdaniyah', 'rawdah'],
  ),
];

Service serviceById(String id) => services.firstWhere((s) => s.id == id);

/// ضريبة القيمة المضافة
const vatRate = 0.15;

/// صورة الخدمة: أيقونة على خلفية ملونة (النص فوقها دايماً أسود)
class ServiceImage extends StatelessWidget {
  const ServiceImage({super.key, required this.service, this.size = 92});

  final Service service;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: service.tint, borderRadius: BorderRadius.circular(size * 0.28)),
          child: Icon(service.icon, size: size * 0.44, color: const Color(0xFF000000)),
        ),
      );
}

/// المبلغ بالريال (بدون كسور إذا رقم صحيح، وإلا برقمين بعد الفاصلة)
String money(num v) {
  final whole = v == v.roundToDouble();
  return '${whole ? v.round().toString() : v.toStringAsFixed(2)} ريال';
}
