import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/themes/app_themes.dart';
import 'package:app_saku_rapi/core/themes/theme_controller.dart';
import 'package:app_saku_rapi/global/services/notification_service.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:app_saku_rapi/utils/services/screen_util_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzLocal;
import 'package:workmanager/workmanager.dart';

/// Callback WorkManager untuk background tasks.
///
/// Harus berupa fungsi top-level (tidak boleh di dalam kelas).
/// Digunakan untuk menjadwalkan ulang notifikasi setelah perangkat restart.
@pragma('vm:entry-point')
void _workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppLogger.call(
      '[WorkManager] Background task: $taskName',
      colorLog: ColorLog.blue,
    );
    // Re-inisialisasi timezone di isolate WorkManager.
    tz.initializeTimeZones();
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi timezone untuk scheduled notifications.
  tz.initializeTimeZones();
  tzLocal.setLocalLocation(tzLocal.getLocation('Asia/Jakarta'));

  // Inisialisasi Hive (encrypted box).
  await HiveService.instance();
  AppLogger.call(
    'Url Supabase: ${const String.fromEnvironment('SUPABASE_URL')}',
  );
  // Inisialisasi Supabase.
  await Supabase.initialize(
    debug: true,
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Inisialisasi local notifications service.
  await NotificationService().initialize();

  // Inisialisasi WorkManager untuk background task (boot-complete reschedule).
  await Workmanager().initialize(
    _workmanagerCallbackDispatcher,
    isInDebugMode: kDebugMode,
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
        '[GoRouter] ${record.level.name}: ${record.time}: ${record.message}',
      );
    });
  }
  runApp(
    ProviderScope(
      observers: [
        TalkerRiverpodObserver(settings: TalkerRiverpodLoggerSettings()),
      ],
      child: SakuRapiApp(),
    ),
  );
}

class SakuRapiApp extends ConsumerWidget {
  const SakuRapiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final designSize = getDesignSize(context);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          theme: AppThemes.lightTheme(context),
          darkTheme: AppThemes.darkTheme(context),
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
