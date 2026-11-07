import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../countries.dart';
import '../data.dart';
import '../main.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'privacy_screen.dart';
import 'shell.dart';
import 'terms_screen.dart';

/// نهاية خطوات الدخول: إذا بدأ من داخل التطبيق يرجع لنفس المكان، وإلا يفتح الرئيسية
void finishLogin(BuildContext context, {required bool inside}) {
  final nav = Navigator.of(context);
  if (inside) {
    nav.popUntil((r) => r.settings.name != loginRouteName);
  } else {
    nav.pushAndRemoveUntil(iosRoute(const MainShell()), (_) => false);
  }
}

String formatBirth(DateTime d) => '${fmtNum(d.day)} ${monthNames[d.month - 1]} ${fmtNum(d.year)}';

/// يعرض الجوال 05xxxxxxxx بالشكل +966 5x xxx xxxx
String displayPhone(String phone) {
  final n = phone.startsWith('0') ? phone.substring(1) : phone;
  if (n.length != 9) return phone;
  return '+966 ${n.substring(0, 2)} ${n.substring(2, 5)} ${n.substring(5)}';
}

/// المعلومات الشخصية: بعد رمز التحقق لأول مرة، أو للتعديل من "حسابي"
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.phone, this.inside = false, this.initial});

  /// رقم الجوال الموثّق (05xxxxxxxx)
  final String phone;
  final bool inside;

  /// المعلومات الحالية (لو موجودة = وضع التعديل)
  final Profile? initial;

  bool get editing => initial != null;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _id;
  late final TextEditingController _email;
  final _idFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _idTouched = false;
  bool _emailTouched = false;

  String? _gender;
  DateTime? _birth;
  String _nationality = saudiArabia;
  bool _consentData = false;
  bool _consentTerms = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _id = TextEditingController(text: p?.idNumber ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _gender = p?.gender;
    _birth = p?.birthDate;
    _nationality = p?.nationality ?? saudiArabia;
    _consentData = widget.editing;
    _consentTerms = widget.editing;
    _idFocus.addListener(() {
      if (!_idFocus.hasFocus) setState(() => _idTouched = true);
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _email.dispose();
    _idFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _saudi => _nationality == saudiArabia;
  String get _idDigits => normalizeDigits(_id.text).replaceAll(RegExp(r'\D'), '');
  bool get _nameOk => _name.text.trim().length >= 3;
  bool get _idOk => RegExp(_saudi ? r'^1\d{9}$' : r'^2\d{9}$').hasMatch(_idDigits);
  bool get _emailOk {
    final e = _email.text.trim();
    return e.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(e);
  }

  bool get _valid =>
      _nameOk && _idOk && _gender != null && _birth != null && _emailOk && _consentData && _consentTerms;

  void _submit() {
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    final s = AppScope.read(context);
    s.saveProfile(Profile(
      name: _name.text.trim(),
      idNumber: _idDigits,
      gender: _gender!,
      birthDate: _birth!,
      nationality: _nationality,
      phone: widget.phone,
      email: _email.text.trim(),
    ));
    HapticFeedback.lightImpact();
    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      finishLogin(context, inside: widget.inside);
    }
  }

  Future<void> _pickBirth() async {
    FocusScope.of(context).unfocus();
    final picked = await showBirthPicker(context, _birth);
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _pickNationality() async {
    FocusScope.of(context).unfocus();
    final picked = await showCountryPicker(context, _nationality);
    if (picked != null) setState(() => _nationality = picked);
  }

  Widget _label(String text, {String? note}) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
        child: Row(
          children: [
            Text(text, style: ts(15)),
            if (note != null) ...[
              const SizedBox(width: 6),
              Text(note, style: ts(13, color: AppColors.faint)),
            ],
          ],
        ),
      );

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Text(text, style: ts(13, color: AppColors.red)),
      );

  @override
  Widget build(BuildContext context) {
    final idLabel = _saudi ? 'رقم الهوية الوطنية' : 'رقم الإقامة';
    final idError = _saudi ? 'رقم الهوية 10 أرقام ويبدأ بـ 1' : 'رقم الإقامة 10 أرقام ويبدأ بـ 2';
    final showIdError = _idDigits.isNotEmpty && (_idTouched || _idDigits.length >= 10) && !_idOk;
    final showEmailError = _emailTouched && !_emailOk;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const Align(alignment: AlignmentDirectional.centerStart, child: BackCircle()),
                  const SizedBox(height: 18),
                  BigTitle(widget.editing ? 'معلوماتي\nالشخصية' : 'معلوماتك\nالشخصية', size: 40),
                  if (!widget.editing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                      child: Text(
                        'نحتاجها مرة وحدة لفتح ملفك في العيادة',
                        style: ts(15, color: AppColors.body, height: 1.7),
                      ),
                    ),

                  // الاسم
                  _label('الاسم الكامل'),
                  TextField(
                    controller: _name,
                    style: ts(16),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: pillInput('مثل: محمد أحمد الغامدي'),
                    onChanged: (_) => setState(() {}),
                  ),

                  // رقم الهوية أو الإقامة
                  _label(idLabel),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _id,
                      focusNode: _idFocus,
                      style: ts(17).copyWith(letterSpacing: 1),
                      keyboardType: TextInputType.number,
                      inputFormatters: [const WesternDigits(), FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: pillInput(_saudi ? '1xxxxxxxxx' : '2xxxxxxxxx'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (showIdError) _error(idError),

                  // الجنس
                  _label('الجنس'),
                  Row(
                    children: [
                      Expanded(child: _ChoicePill(label: 'ذكر', selected: _gender == 'm', onTap: () => setState(() => _gender = 'm'))),
                      const SizedBox(width: 8),
                      Expanded(child: _ChoicePill(label: 'أنثى', selected: _gender == 'f', onTap: () => setState(() => _gender = 'f'))),
                    ],
                  ),

                  // تاريخ الميلاد
                  _label('تاريخ الميلاد'),
                  _SelectField(
                    value: _birth == null ? null : formatBirth(_birth!),
                    placeholder: 'اختر تاريخ ميلادك',
                    icon: CupertinoIcons.calendar,
                    semanticLabel: 'تاريخ الميلاد',
                    onTap: _pickBirth,
                  ),

                  // الجنسية
                  _label('الجنسية'),
                  _SelectField(
                    value: _nationality,
                    placeholder: 'اختر الجنسية',
                    icon: CupertinoIcons.chevron_down,
                    semanticLabel: 'الجنسية',
                    onTap: _pickNationality,
                  ),

                  // الجوال (موثّق بالرمز)
                  _label('رقم الجوال'),
                  Semantics(
                    label: 'رقم الجوال ${displayPhone(widget.phone)}، موثّق',
                    child: ExcludeSemantics(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 62),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayPhone(widget.phone),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.start,
                                style: ts(17, color: AppColors.body),
                              ),
                            ),
                            Icon(CupertinoIcons.checkmark_seal_fill, size: 20, color: AppColors.green),
                            const SizedBox(width: 6),
                            Text('موثّق', style: ts(14, weight: FontWeight.w600, color: AppColors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // الإيميل
                  _label('البريد الإلكتروني', note: '(اختياري)'),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _email,
                      focusNode: _emailFocus,
                      style: ts(16),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: pillInput('name@example.com'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (showEmailError) _error('اكتب بريد إلكتروني صحيح أو اتركه فاضي'),

                  if (!widget.editing) ...[
                    const SizedBox(height: 14),
                    AppCheck(
                      value: _consentData,
                      onChanged: () => setState(() => _consentData = !_consentData),
                      child: Text(
                        'أوافق على التسجيل ومشاركة بياناتي مع العيادة لإدارة مواعيدي وملفي الطبي',
                        style: ts(14, height: 1.7),
                      ),
                    ),
                    AppCheck(
                      value: _consentTerms,
                      onChanged: () => setState(() => _consentTerms = !_consentTerms),
                      child: Text('أوافق على سياسة الخصوصية والشروط والأحكام', style: ts(14, height: 1.7)),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 34),
                      child: Wrap(
                        children: [
                          _Link('قراءة سياسة الخصوصية', () => Navigator.of(context).push(iosRoute(const PrivacyScreen()))),
                          _Link('قراءة الشروط والأحكام', () => Navigator.of(context).push(iosRoute(const TermsScreen()))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            BottomAction(
              child: PillButton(
                label: widget.editing ? 'حفظ' : 'متابعة',
                height: 66,
                enabled: _valid,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.text, this.onTap);

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Text(text, style: ts(14, decoration: TextDecoration.underline)),
          ),
        ),
      );
}

/// زر اختيار (ذكر / أنثى): المختار ليموني
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: motion(context, 200),
          constraints: const BoxConstraints(minHeight: 60),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.lime : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: selected && highContrast(context) ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 20, color: AppColors.onAccent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: ts(17, weight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.onAccent : AppColors.ink),
              ),
            ],
          ),
        ),
      );
}

/// خانة تفتح نافذة اختيار (التاريخ أو الجنسية)
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: '$semanticLabel: ${value ?? 'غير محدد'}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              Expanded(
                child: Text(value ?? placeholder, style: ts(16, color: value == null ? AppColors.faint : AppColors.ink)),
              ),
              Icon(icon, size: 20, color: AppColors.faint),
            ],
          ),
        ),
      );
}

/// اختيار تاريخ الميلاد بثلاث عجلات (اليوم · الشهر · السنة) مثل آيفون
Future<DateTime?> showBirthPicker(BuildContext context, DateTime? current) {
  return showGlassSheet<DateTime>(context, builder: (ctx) => _BirthSheet(current: current));
}

class _BirthSheet extends StatefulWidget {
  const _BirthSheet({required this.current});

  final DateTime? current;

  @override
  State<_BirthSheet> createState() => _BirthSheetState();
}

class _BirthSheetState extends State<_BirthSheet> {
  final _now = DateTime.now();
  late final int _firstYear = _now.year - 110;
  late int _day;
  late int _month;
  late int _year;
  late final FixedExtentScrollController _dayCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.current ?? DateTime(_now.year - 30, 1, 1);
    _day = init.day;
    _month = init.month;
    _year = init.year;
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _firstYear);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  int get _maxDay => DateTime(_year, _month + 1, 0).day;

  /// لو اليوم أكبر من أيام الشهر (مثل 31 فبراير) نرجّعه لآخر يوم
  void _fixDay() {
    if (_day > _maxDay) {
      _day = _maxDay;
      _dayCtrl.animateToItem(_maxDay - 1, duration: motion(context, 200), curve: Curves.easeOut);
    }
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required Widget Function(int i) item,
    required ValueChanged<int> onChanged,
    required String semantic,
  }) =>
      Semantics(
        label: semantic,
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: 44,
          onSelectedItemChanged: onChanged,
          children: [for (var i = 0; i < count; i++) Center(child: item(i))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('تاريخ الميلاد', style: ts(22, weight: FontWeight.w500))),
            const SizedBox(height: 6),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _wheel(
                        controller: _dayCtrl,
                        count: 31,
                        semantic: 'اليوم',
                        // الأيام اللي ما تنفع للشهر المختار تطلع باهتة
                        item: (i) => Text(fmtNum(i + 1), style: ts(20, color: i < _maxDay ? AppColors.ink : AppColors.faint)),
                        onChanged: (i) => setState(() {
                          _day = i + 1;
                          _fixDay();
                        }),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _wheel(
                        controller: _monthCtrl,
                        count: 12,
                        semantic: 'الشهر',
                        item: (i) => Text(monthNames[i], style: ts(20)),
                        onChanged: (i) => setState(() {
                          _month = i + 1;
                          _fixDay();
                        }),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _wheel(
                        controller: _yearCtrl,
                        count: _now.year - _firstYear + 1,
                        semantic: 'السنة',
                        item: (i) => Text(fmtNum(_firstYear + i), style: ts(20)),
                        onChanged: (i) => setState(() {
                          _year = _firstYear + i;
                          _fixDay();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'تم',
              height: 60,
              onTap: () {
                var picked = DateTime(_year, _month, _day.clamp(1, _maxDay));
                final today = DateTime(_now.year, _now.month, _now.day);
                if (picked.isAfter(today)) picked = today;
                Navigator.of(context).pop(picked);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// اختيار الجنسية: بحث + قائمة (السعودية أولها)
Future<String?> showCountryPicker(BuildContext context, String current) {
  // تفتح لنص الشاشة، وتنسحب لفوق للقائمة كاملة (مثل نوافذ آبل)
  final sheet = DraggableScrollableController();
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x33000000),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      controller: sheet,
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.55],
      builder: (ctx, scroll) => GlassSheet(
        fill: true,
        child: _CountrySheet(current: current, scroll: scroll, sheet: sheet),
      ),
    ),
  ).whenComplete(sheet.dispose);
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.current, required this.scroll, required this.sheet});

  final String current;
  final ScrollController scroll;
  final DraggableScrollableController sheet;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = searchKey(_q.text);
    final list = q.isEmpty ? countries : countries.where((c) => searchKey(c).contains(q)).toList();
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Semantics(header: true, child: Text('الجنسية', style: ts(22, weight: FontWeight.w500))),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _q,
                style: ts(16),
                textInputAction: TextInputAction.search,
                // لما يبدأ يكتب نفتح النافذة كاملة عشان الكيبورد ما يغطي القائمة
                onTap: () {
                  if (!widget.sheet.isAttached || widget.sheet.size >= 0.9) return;
                  final d = motion(context, 280);
                  if (d == Duration.zero) {
                    widget.sheet.jumpTo(0.94);
                  } else {
                    widget.sheet.animateTo(0.94, duration: d, curve: Curves.easeOutCubic);
                  }
                },
                decoration: pillInput('ابحث عن دولة').copyWith(
                  fillColor: AppColors.bg,
                  prefixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 18, end: 8),
                    child: Icon(CupertinoIcons.search, size: 20, color: AppColors.faint),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? ListView(
                      controller: widget.scroll,
                      padding: const EdgeInsets.only(top: 40),
                      children: [Text('ما لقينا دولة بهذا الاسم', textAlign: TextAlign.center, style: ts(15, color: AppColors.faint))],
                    )
                  : ListView.builder(
                      controller: widget.scroll,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final sel = c == widget.current;
                        return Pressable(
                          onTap: () => Navigator.of(context).pop(c),
                          selected: sel,
                          semanticLabel: c,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 54),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(c, style: ts(17, color: sel ? AppColors.onAccent : AppColors.ink)),
                                ),
                                if (sel) const Icon(Icons.check_rounded, size: 22, color: AppColors.onAccent),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
