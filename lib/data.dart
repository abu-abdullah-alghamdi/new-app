/// البيانات الثابتة وأدوات التنسيق
library;

const _arDigits = '٠١٢٣٤٥٦٧٨٩';

/// يحوّل الأرقام الإنجليزية إلى عربية
String ar(Object value) => value.toString().replaceAllMapped(
      RegExp(r'\d'),
      (m) => _arDigits[int.parse(m[0]!)],
    );

/// يحوّل الأرقام العربية إلى إنجليزية
String en(String value) => value.replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => _arDigits.indexOf(m[0]!).toString(),
    );

const monthNames = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

// DateTime.weekday: 1 = الاثنين ... 7 = الأحد
const _dayLong = {
  1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس',
  5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
};
const _dayShort = {
  1: 'اثنين', 2: 'ثلاثاء', 3: 'أربعاء', 4: 'خميس',
  5: 'جمعة', 6: 'سبت', 7: 'أحد',
};

/// يوم التطبيق المرجعي (يُحسب مرة وحدة عند التشغيل)
final DateTime appToday = () {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}();

class DayInfo {
  DayInfo(this.offset) : date = DateTime(appToday.year, appToday.month, appToday.day + offset);

  final int offset;
  final DateTime date;

  bool get closed => date.weekday == DateTime.friday;
  String get label => offset == 0
      ? 'اليوم'
      : offset == 1
          ? 'غداً'
          : offset == -1
              ? 'أمس'
              : _dayLong[date.weekday]!;
  String get short => offset == 0 ? 'اليوم' : _dayShort[date.weekday]!;
  String get dayNum => ar(date.day);
  String get month => monthNames[date.month - 1];
  String get full => '$label ${ar(date.day)} $month';
  String get longDate => '${ar(date.day)} $month ${ar(date.year)}';
}

/// الوقت بالدقائق بعد الساعة ٤:٠٠ مساءً
String fmtTime(int minutesAfter4pm) {
  final total = 16 * 60 + minutesAfter4pm;
  var h = (total ~/ 60) % 12;
  if (h == 0) h = 12;
  final mm = (total % 60).toString().padLeft(2, '0');
  return '${ar(h)}:${ar(mm)} م';
}

String fmtRange(int start, int duration) => 'من ${fmtTime(start)} إلى ${fmtTime(start + duration)}';

const slotTimes = [0, 30, 60, 90, 120, 150, 180, 210, 240];

const categories = {
  'dental': 'كشف وعلاج الأسنان',
  'ortho': 'استشارة تقويم',
  'derma': 'استشارة جلدية',
  'laser': 'جلسة ليزر',
};

const List<({String? id, String label})> categoryFilters = [
  (id: null, label: 'الكل'),
  (id: 'dental', label: 'أسنان'),
  (id: 'ortho', label: 'تقويم'),
  (id: 'derma', label: 'جلدية'),
  (id: 'laser', label: 'ليزر'),
];

class Doctor {
  const Doctor({
    required this.id,
    required this.n1,
    required this.n2,
    required this.role,
    required this.cats,
    required this.years,
    required this.duration,
    required this.price,
    required this.availableToday,
    required this.image,
    required this.about,
  });

  final String id;
  final String n1;
  final String n2;
  final String role;
  final List<String> cats;
  final String years;
  final int duration;
  final String price;
  final bool availableToday;
  final String image;
  final String about;

  String get name => '$n1 $n2';
  String get durationText => '${ar(duration)} دقيقة';
  bool get reallyToday => availableToday && !DayInfo(0).closed;
  String get availText => reallyToday ? 'متاح اليوم' : 'متاح غداً';
  int get nextDay => firstOpenDay(fromToday: reallyToday);
  String get nextFull => 'أقرب موعد: ${DayInfo(nextDay).longDate}';
}

int firstOpenDay({bool fromToday = true}) {
  for (var i = fromToday ? 0 : 1; i < 14; i++) {
    if (!DayInfo(i).closed) return i;
  }
  return 1;
}

const doctors = [
  Doctor(
    id: 'd1',
    n1: 'د. ريم',
    n2: 'العتيبي',
    role: 'أخصائية طب أسنان عام',
    cats: ['dental'],
    years: 'خبرة +٨ سنوات',
    duration: 45,
    price: '٢٠٠ ريال',
    availableToday: true,
    image: 'assets/doctors/reem.png',
    about:
        'أخصائية طب أسنان عام، تهتم بالوقاية والعلاج التجميلي للأسنان مثل الحشوات التجميلية والتنظيف العميق. تحرص على شرح الخطة العلاجية بوضوح وتجربة مريحة قدر الإمكان، وتتعامل مع الأطفال والكبار.',
  ),
  Doctor(
    id: 'd2',
    n1: 'د. فهد',
    n2: 'الزهراني',
    role: 'استشاري تقويم الأسنان',
    cats: ['ortho', 'dental'],
    years: 'خبرة +١٢ سنة',
    duration: 30,
    price: '٣٠٠ ريال',
    availableToday: false,
    image: 'assets/doctors/fahd.png',
    about:
        'استشاري تقويم الأسنان، متخصص في التقويم الشفاف والتقليدي وتصحيح إطباق الفك. يبدأ مع كل مريض بتقييم كامل وخطة علاج واضحة المدة والمراحل، مع متابعة دورية حتى نهاية العلاج.',
  ),
  Doctor(
    id: 'd3',
    n1: 'د. نورة',
    n2: 'القحطاني',
    role: 'أخصائية جلدية وليزر',
    cats: ['derma', 'laser'],
    years: 'خبرة +٦ سنوات',
    duration: 30,
    price: '٢٥٠ ريال',
    availableToday: true,
    image: 'assets/doctors/noura.png',
    about:
        'أخصائية الأمراض الجلدية والتجميل، تعالج حب الشباب والتصبغات ومشاكل البشرة، وتشرف على جلسات الليزر. تهتم بوضع خطة مناسبة لنوع البشرة مع روتين عناية منزلي سهل.',
  ),
  Doctor(
    id: 'd4',
    n1: 'د. سلطان',
    n2: 'الغامدي',
    role: 'أخصائي جلدية',
    cats: ['derma'],
    years: 'خبرة +٥ سنوات',
    duration: 20,
    price: '٢٠٠ ريال',
    availableToday: false,
    image: 'assets/doctors/sultan.png',
    about:
        'أخصائي جلدية، يعالج الأكزيما والصدفية وتساقط الشعر والالتهابات الجلدية. يركز على التشخيص الدقيق والمتابعة المنتظمة لضمان أفضل نتيجة.',
  ),
];

Doctor doctorById(String id) => doctors.firstWhere((d) => d.id == id, orElse: () => doctors.first);

/// هل الوقت محجوز؟ (بيانات تجريبية ثابتة لكل طبيب ويوم)
bool slotTaken(String doctorId, int day, int index) {
  final seed = doctorId.codeUnitAt(1);
  return (index * 7 + (day + 1) * 3 + seed) % 4 == 0;
}

class Booking {
  Booking({
    required this.id,
    required this.doctorId,
    required this.cat,
    required this.dayIndex,
    required this.time,
  });

  final String id;
  String doctorId;
  String cat;
  int dayIndex;
  int time;

  Doctor get doctor => doctorById(doctorId);
  DayInfo get day => DayInfo(dayIndex);
  bool get completed => dayIndex < 0;
  String get serviceName => categories[cat] ?? '';
  String get range => fmtRange(time, doctor.duration);
}
