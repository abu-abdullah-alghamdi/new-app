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

/// تقييم مستخدم لخدمة (name = null يعني مستخدم مجهول)
class Review {
  const Review({this.name, required this.stars, required this.daysAgo, required this.text});

  final String? name;
  final int stars;
  final int daysAgo;
  final String text;

  String get displayName => name ?? 'مستخدم مجهول';
  bool get anonymous => name == null;
}

/// "قبل 3 أيام" ...
String agoText(int d) {
  if (d <= 0) return 'اليوم';
  if (d == 1) return 'أمس';
  if (d == 2) return 'قبل يومين';
  if (d <= 10) return 'قبل ${ar(d)} أيام';
  if (d < 30) return 'قبل ${ar(d)} يوم';
  if (d < 60) return 'قبل شهر';
  if (d < 90) return 'قبل شهرين';
  return 'قبل ${ar(d ~/ 30)} شهور';
}

/// نبذة كل خدمة (نص تجريبي)
const serviceAbout = {
  's1': 'تنظيف عميق للأسنان وإزالة الجير والتصبغات السطحية باستخدام أجهزة الموجات فوق الصوتية، مع تلميع نهائي ونصائح للعناية اليومية. ينصح فيه كل 6 أشهر للحفاظ على صحة اللثة.',
  's2': 'تبييض احترافي في العيادة بجلسة وحدة تقريباً ساعة، بمواد آمنة على المينا تحت إشراف الطبيب. النتيجة تختلف حسب لون الأسنان الأساسي، ويعطيك الطبيب تعليمات للحفاظ على النتيجة.',
  's3': 'حشوة بلون السن تُستخدم لعلاج التسوس الصغير والمتوسط أو تعديل شكل السن المكسور، بمادة الكومبوزيت اللي تتطابق مع لون أسنانك الطبيعي.',
  's4': 'فحص كامل للفم والأسنان واللثة مع أشعة عند الحاجة، ويطلع لك تقرير واضح بالحالة وخطة علاج مقترحة بالأولويات والتكلفة.',
  's5': 'جلسة استشارة مع استشاري التقويم: تقييم الإطباق والفكين، وشرح خيارات التقويم المناسبة (الشفاف أو التقليدي) والمدة المتوقعة والتكلفة.',
  's6': 'تنظيف بشرة عميق يشمل التقشير وإزالة الرؤوس السوداء والترطيب، ويُختار نوع الجلسة حسب نوع بشرتك بعد تقييم سريع.',
  's7': 'جلسة ليزر لإزالة الشعر بأجهزة حديثة مناسبة لأغلب أنواع البشرة، والسعر للمنطقة الوحدة. تحتاج عادة من 6 إلى 8 جلسات لنتيجة واضحة.',
  's8': 'برنامج علاج لتساقط الشعر يبدأ بتشخيص السبب، ويشمل حقن البلازما أو الميزوثيرابي حسب الحالة، مع متابعة دورية لقياس التحسن.',
};

/// تقييمات تجريبية لكل خدمة (تُستبدل بتقييمات المرضى الحقيقية قبل النشر)
const serviceReviews = {
  's1': [
    Review(name: 'سارة م.', stars: 5, daysAgo: 3, text: 'التنظيف كان سريع وما حسيت بألم، والطبيبة شرحت لي كل خطوة.'),
    Review(stars: 4, daysAgo: 12, text: 'خدمة ممتازة، بس الانتظار كان أطول من الموعد بشوي.'),
    Review(name: 'عبدالله ع.', stars: 5, daysAgo: 40, text: 'أسناني صارت أنظف بشكل واضح، أنصح فيه.'),
  ],
  's2': [
    Review(name: 'ريم ح.', stars: 5, daysAgo: 6, text: 'النتيجة فرقت كثير من أول جلسة، والحساسية كانت خفيفة.'),
    Review(stars: 4, daysAgo: 25, text: 'حلو بس توقعت درجة أفتح شوي.'),
    Review(name: 'خالد س.', stars: 5, daysAgo: 70, text: 'تعامل راقي وتعليمات واضحة بعد الجلسة.'),
  ],
  's3': [
    Review(name: 'منى ق.', stars: 5, daysAgo: 2, text: 'الحشوة ما تنعرف من لون السن، شغل نظيف.'),
    Review(name: 'فيصل ز.', stars: 5, daysAgo: 18, text: 'سريعة ومريحة، والدكتورة تطمّن.'),
    Review(stars: 4, daysAgo: 33, text: 'كل شي تمام، بس التخدير أخذ وقت يروح.'),
  ],
  's4': [
    Review(stars: 5, daysAgo: 1, text: 'الفحص كان شامل وعطوني تقرير مفصل بكل شي.'),
    Review(name: 'نوف ا.', stars: 5, daysAgo: 9, text: 'سعره مناسب جداً مقابل اللي تاخذه.'),
    Review(name: 'ماجد ت.', stars: 4, daysAgo: 50, text: 'مفيد، وخطة العلاج كانت واضحة ومرتبة.'),
  ],
  's5': [
    Review(name: 'لمى ع.', stars: 5, daysAgo: 5, text: 'الاستشاري شرح الخيارات بدون ما يضغط علي، وفهمت كل شي.'),
    Review(stars: 5, daysAgo: 28, text: 'استشارة مفيدة وطلعت بخطة واضحة ومدة متوقعة.'),
  ],
  's6': [
    Review(name: 'هيا ب.', stars: 5, daysAgo: 4, text: 'بشرتي صارت أنعم من أول جلسة.'),
    Review(stars: 4, daysAgo: 15, text: 'حلوة الجلسة، بس فيه احمرار خفيف يوم كامل.'),
    Review(name: 'شهد ر.', stars: 4, daysAgo: 60, text: 'الأخصائية لطيفة وتعطي نصايح مفيدة.'),
  ],
  's7': [
    Review(name: 'أمل ج.', stars: 5, daysAgo: 7, text: 'الجهاز ممتاز والألم بسيط جداً.'),
    Review(stars: 4, daysAgo: 21, text: 'النتيجة بدت تبين من الجلسة الثالثة.'),
  ],
  's8': [
    Review(name: 'سلطان م.', stars: 4, daysAgo: 10, text: 'بديت ألاحظ فرق بعد شهرين، والمتابعة منتظمة.'),
    Review(stars: 5, daysAgo: 45, text: 'التشخيص كان دقيق وعرفوا السبب من أول زيارة.'),
    Review(name: 'ناصر ح.', stars: 4, daysAgo: 95, text: 'تجربة جيدة، يبيلها صبر.'),
  ],
};

extension ServiceDetails on Service {
  String get about => serviceAbout[id] ?? '';
  List<Review> get reviewList => serviceReviews[id] ?? const [];
}
