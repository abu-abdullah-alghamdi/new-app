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
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const AreemApp());
}

class AreemApp extends StatelessWidget {
  const AreemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lime,
        primary: AppColors.ink,
        surface: AppColors.bg,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );

    return AppScope(
      state: appState,
      child: MaterialApp(
        title: 'عيادات أريام',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: base.copyWith(
          textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

/// انتقال الصفحات بأسلوب iOS (انزلاق كامل + سحب من الحافة للرجوع)
Route<T> iosRoute<T>(Widget page) => CupertinoPageRoute<T>(builder: (_) => page);
