import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'welcome_screen.dart';

/// مفتاح حفظ "شاف الصفحات التعريفية"
const onboardingSeenKey = 'onboarding_seen';

class _Page {
  const _Page(this.image, this.title, this.body);

  final String image;
  final String title;
  final String body;
}

const _pages = [
  _Page('assets/doctors/reem.png', 'احجز موعدك\nبسهولة', 'اختر طبيبك والوقت المناسب لك في ثواني.'),
  _Page('assets/doctors/noura.png', 'خدمات العيادة\nبين يديك', 'تصفح الخدمات وأسعارها، وأضفها للسلة وادفع بسهولة.'),
  _Page('assets/doctors/fahd.png', 'ما يفوتك\nموعد', 'نذكّرك بموعدك على واتساب، وتتابع كل زياراتك من مكان واحد.'),
];

/// ٣ صفحات تعريفية تطلع أول مرة بس
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _index = 0;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingSeenKey, true);
    } catch (_) {
      // لو ما انحفظ، أسوأ شي إنها تطلع مرة ثانية
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(iosRoute(const WelcomeScreen()), (_) => false);
  }

  void _next() {
    if (_last) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.jumpToPage(_index + 1);
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // زر "تخطي" (يختفي في آخر صفحة)
            SizedBox(
              height: 56,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedOpacity(
                  duration: motion(context, 200),
                  opacity: _last ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _last,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        foregroundColor: AppColors.ink,
                      ),
                      child: Text('تخطي', style: ts(16, weight: FontWeight.w500)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),
            // النقاط
            Semantics(
              label: 'صفحة ${_index + 1} من ${_pages.length}',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: motion(context, 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? AppColors.ink : AppColors.disabled,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(label: _last ? 'ابدأ الآن' : 'التالي', height: 64, onTap: _next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // حجم الدائرة يتناسب مع الشاشة
        final d = (box.maxWidth - 80).clamp(200.0, 320.0).toDouble();
        final circle = (box.maxHeight * 0.55).clamp(160.0, d).toDouble();
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(child: _Portrait(image: page.image, size: circle)),
                const SizedBox(height: 34),
                Semantics(
                  header: true,
                  child: Text(page.title, textAlign: TextAlign.center, style: ts(34, height: 1.25)),
                ),
                const SizedBox(height: 12),
                Text(page.body, textAlign: TextAlign.center, style: ts(17, color: AppColors.body, height: 1.7)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// دائرة ليمونية والصورة طالعة من فوقها (الرأس برا الدائرة، والأسفل يتقص على حدها)
class _Portrait extends StatelessWidget {
  const _Portrait({required this.image, required this.size});

  final String image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imgH = size * 1.18;
    return SizedBox(
      width: size,
      height: imgH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
          ),
          ClipPath(
            clipper: _PopOutClipper(circle: size),
            child: SizedBox(
              width: size,
              height: imgH,
              child: Image.asset(image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
            ),
          ),
        ],
      ),
    );
  }
}

/// يقص الصورة على حد الدائرة من تحت، ويخليها حرة من فوق
class _PopOutClipper extends CustomClipper<Path> {
  const _PopOutClipper({required this.circle});

  final double circle;

  @override
  Path getClip(Size size) {
    final top = size.height - circle;
    final oval = Path()..addOval(Rect.fromLTWH(0, top, size.width, circle));
    final upper = Path()..addRect(Rect.fromLTWH(0, 0, size.width, top + circle / 2));
    return Path.combine(PathOperation.union, oval, upper);
  }

  @override
  bool shouldReclip(_PopOutClipper old) => old.circle != circle;
}
