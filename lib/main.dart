import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

final appState = AppState();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // الصفحات التعريفية تطلع أول مرة بس
  var seen = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seen = prefs.getBool(onboardingSeenKey) ?? false;
  } catch (_) {}
  // التذكير المحلي قبل المواعيد
  await Reminders.init();
  runApp(AreemApp(showOnboarding: !seen));
}

ThemeData _theme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: appFont,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lime),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: appFont, bodyColor: AppColors.ink, displayColor: AppColors.ink),
    // عناصر آبل المرسومة في فلاتر (قائمة الضغط المطوّل، شريط العنوان، السحب للتحديث) بنفس الخط
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.ink,
      textTheme: CupertinoTextThemeData(
        textStyle: ts(17),
        actionTextStyle: ts(17),
        navTitleTextStyle: ts(17, weight: FontWeight.w600),
        navLargeTitleTextStyle: ts(36, color: AppColors.title, height: 1.2),
      ),
    ),
  );
}

class AreemApp extends StatelessWidget {
  const AreemApp({super.key, this.showOnboarding = false});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: MaterialApp(
        // يخفي شريط آبل وقت النوافذ والصفحات اللي تطلع فوقه
        navigatorObservers: [CNTabBarRouteObserver()],
        title: 'عيادتي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // التطبيق فاتح دايماً (حتى لو الجوال على الوضع الداكن)
        theme: _theme(),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.light),
            child: child!,
          ),
        ),
        // يتصفح على طول؛ التسجيل يطلب لما يحجز أو يدفع
        home: showOnboarding ? const OnboardingScreen() : const MainShell(),
      ),
    );
  }
}

/// انتقال iOS (انزلاق كامل + سحب من الحافة للرجوع)، ويصير تلاشي بسيط مع "تقليل الحركة"
class AppRoute<T> extends CupertinoPageRoute<T> {
  AppRoute({required super.builder, super.fullscreenDialog, super.settings});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}

Route<T> iosRoute<T>(Widget page, {String? name}) =>
    AppRoute<T>(builder: (_) => page, settings: name == null ? null : RouteSettings(name: name));

/// اسم صفحات خطوات تسجيل الدخول (رقم الجوال، الرمز، المعلومات الشخصية)
/// عشان نرجع للمكان اللي بدأ منه المستخدم بعد ما يخلّص
const loginRouteName = 'login';

/// نافذة كاملة تطلع من تحت (للمهام المؤقتة مثل الحجز)، وفيها زر إغلاق
Route<T> iosModal<T>(Widget page) => AppRoute<T>(builder: (_) => page, fullscreenDialog: true);
