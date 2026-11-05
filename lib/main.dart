import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_screen.dart';
import 'state.dart';
import 'theme.dart';

final appState = AppState();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AreemApp());
}

ThemeData _theme(Brightness b) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: b == Brightness.dark ? const Color(0xFF0B0B0C) : const Color(0xFFEEEEF0),
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lime, brightness: b),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
  final text = b == Brightness.dark ? Colors.white : Colors.black;
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
  );
}

/// يعيد بناء كل الشاشات لما يتغير الوضع الفاتح/الداكن (بدون ما تضيع الحالة)
void _rebuildAll(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}

class AreemApp extends StatelessWidget {
  const AreemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: MaterialApp(
        title: 'عيادتي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: ThemeMode.system,
        builder: (context, child) {
          final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          if (AppColors.dark != dark) {
            AppColors.dark = dark;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) _rebuildAll(context);
            });
          }
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: child!,
          );
        },
        home: const WelcomeScreen(),
      ),
    );
  }
}

/// انتقال iOS (انزلاق كامل + سحب من الحافة للرجوع)، ويصير تلاشي بسيط مع "تقليل الحركة"
class AppRoute<T> extends CupertinoPageRoute<T> {
  AppRoute({required super.builder, super.fullscreenDialog});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}

Route<T> iosRoute<T>(Widget page) => AppRoute<T>(builder: (_) => page);

/// نافذة كاملة تطلع من تحت (للمهام المؤقتة مثل الحجز)، وفيها زر إغلاق
Route<T> iosModal<T>(Widget page) => AppRoute<T>(builder: (_) => page, fullscreenDialog: true);
