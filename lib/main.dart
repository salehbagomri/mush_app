import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد اتجاه التطبيق RTL للغة العربية
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // التحقق من حالة شاشة الترحيب (Onboarding)
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingDone = prefs.getBool('onboarding_done') ?? false;

  // تهيئة Supabase
  // ⚠️ ضع هنا بيانات Supabase الخاصة بك
  await Supabase.initialize(
    url: AppStrings.supabaseUrl,       // 🔑 استبدل بـ URL المشروع
    anonKey: AppStrings.supabaseAnonKey, // 🔑 استبدل بـ Anon Key
    debug: false,
  );

  runApp(
    ProviderScope(
      overrides: [
        isOnboardingDoneProvider.overrideWithValue(isOnboardingDone),
      ],
      child: const MushApp(),
    ),
  );
}

class MushApp extends ConsumerWidget {
  const MushApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appFullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // دعم اللغة العربية والاتجاه RTL
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [
        Locale('ar', 'YE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },

      routerConfig: router,
    );
  }
}
