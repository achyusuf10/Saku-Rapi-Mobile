import 'dart:io';

import 'package:app_saku_rapi/core/config/app_flavor.dart';
import 'package:app_saku_rapi/core/localization/locale_controller.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/themes/app_themes.dart';
import 'package:app_saku_rapi/core/themes/theme_controller.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:app_saku_rapi/utils/services/screen_util_service.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aktifkan edge-to-edge sekali saat bootstrap, bukan di setiap build().
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Fallback style untuk layar tanpa AppBar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Inisialisasi Hive (encrypted box).
  await HiveService.instance();

  AppLogger.call(
    'Flavor: ${AppFlavorConfig.name} | Url Supabase: ${const String.fromEnvironment('SUPABASE_URL')}',
  );
  // Inisialisasi Supabase.
  await Supabase.initialize(
    debug: AppFlavorConfig.isDev,
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  if (kDebugMode) {
    hierarchicalLoggingEnabled = true;
    final supabaseLogger = Logger('supabase');
    supabaseLogger.level = Level.ALL;
    supabaseLogger.onRecord.listen((record) {
      // Log ke console
      AppLogger.call(
        '[Supabase] ${record.level.name}: ${record.time}: ${record.message}',
      );
    });
    final goRouterLogger = Logger('GoRouter');
    goRouterLogger.level = Level.ALL;
    goRouterLogger.onRecord.listen((record) {
      // Log ke console
      AppLogger.call(
        '${record.level.name}: ${record.time}: ${record.message}',
        name: 'GoRouter',
        colorLog: ColorLog.yellow,
      );
    });
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = AppFlavorConfig.name.toLowerCase();
      // Dev: sampleRate=0.0 → tidak ada event dikirim ke Sentry server
      // Prod: sampleRate=1.0 → semua error dikirim
      options.sampleRate = kDebugMode
          ? 0.0
          : AppFlavorConfig.isProd
          ? 1.0
          : 0.0;
      options.tracesSampleRate = kDebugMode
          ? 0
          : AppFlavorConfig.isProd
          ? 0.2
          : 0.0;
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      // ignore: experimental_member_use
      options.attachViewHierarchy = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(settings: TalkerRiverpodLoggerSettings()),
        ],
        child: SakuRapiApp(),
      ),
    ),
  );
}

class SakuRapiApp extends ConsumerWidget {
  const SakuRapiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final designSize = getDesignSize(context);
    return ScreenUtilInit(
      designSize: designSize,
      useInheritedMediaQuery: true,
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: (fontSize, instance) {
        return getScaleTextValue(context, designSize, fontSize);
      },
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'SakuRapi',
          themeMode: themeMode,
          builder: (context, child) {
            return KeyboardWrapper(
              keyboards: [SakuCalculatorKeyboard()],
              child: (Platform.isAndroid)
                  ? SafeArea(
                      top: false,
                      bottom: true,
                      child: child ?? SizedBox(),
                    )
                  : child ?? SizedBox(),
            );
          },
          theme: AppThemes.lightTheme(context),
          darkTheme: AppThemes.darkTheme(context),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: ref.watch(routerProvider),
          localizationsDelegates: const [
            // 1. Delegate untuk teks custom aplikasi kamu (dari ARB)
            AppLocalizations.delegate,

            // 2. Delegate untuk Widget Material bawaan (misal: tulisan 'CANCEL' di DatePicker)
            GlobalMaterialLocalizations.delegate,

            // 3. Delegate untuk Widget Cupertino (iOS)
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
