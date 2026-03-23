import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/ui/login_page.dart';
import 'package:app_saku_rapi/features/auth/view/ui/splash_page.dart';
import 'package:app_saku_rapi/features/budget/view/ui/budget_page.dart';
import 'package:app_saku_rapi/features/dashboard/view/ui/dashboard_page.dart';
import 'package:app_saku_rapi/features/history/view/ui/history_page.dart';
import 'package:app_saku_rapi/features/investment/view/ui/investment_page.dart';
import 'package:app_saku_rapi/features/settings/view/ui/settings_page.dart';
import 'package:app_saku_rapi/features/transaction/view/ui/transaction_form_page.dart';
import 'package:app_saku_rapi/features/wallet/view/ui/wallet_page.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

BuildContext? get appContext => AppRouter.navigatorKey.currentContext;

/// Provider untuk [GoRouter] yang di-cache oleh Riverpod.
///
/// Menggunakan `refreshListenable` dari [AuthChangeNotifier] sehingga
/// redirect otomatis terpicu saat status auth berubah.
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Konfigurasi utama routing aplikasi SakuRapi menggunakan GoRouter.
///
/// Semua route didefinisikan di sini secara terpusat.
/// GoRouter akan otomatis redirect berdasarkan status autentikasi user
/// menggunakan `refreshListenable` dari [AuthChangeNotifier].
///
/// Bottom Navigation Bar diimplementasikan via [StatefulShellRoute.indexedStack]
/// agar state tiap tab dipertahankan saat berpindah tab.
class AppRouter {
  AppRouter._();

  /// Navigator key global untuk akses navigasi di luar widget tree.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ───────────────── Route Paths ─────────────────

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String budget = '/budget';
  static const String investment = '/investment';
  static const String wallet = '/wallet';
  static const String transactionForm = '/transaction/form';
  static const String settings = '/settings';

  // ───────────────── Shell Keys ─────────────────

  static final _dashboardNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'dashboardNav',
  );
  static final _historyNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'historyNav',
  );
  static final _budgetNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'budgetNav',
  );
  static final _investmentNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'investmentNav',
  );

  static GoRouter createRouter(Ref ref) {
    final authNotifier = ref.watch(authChangeNotifierProvider);

    return GoRouter(
      navigatorKey: navigatorKey,
      debugLogDiagnostics: true,
      initialLocation: splash,
      refreshListenable: authNotifier,
      // redirect: (context, state) {
      //   final authState = ref.read(authControllerProvider);
      //   final isAuthenticated = authState.isAuthenticated;
      //   final currentLocation = state.matchedLocation;

      //   // Saat masih di splash, biarkan splash handle redirect sendiri
      //   if (currentLocation == splash) return null;

      //   final isLoginRoute = currentLocation == login;

      //   // Belum login → paksa ke login
      //   if (!isAuthenticated && !isLoginRoute) return login;
      //   // Sudah login tapi di halaman login → ke dashboard
      //   if (isAuthenticated && isLoginRoute) return dashboard;

      //   return null;
      // },
      routes: [
        // ─── Splash ───
        GoRoute(path: splash, builder: (context, state) => const SplashPage()),

        // ─── Auth ───
        GoRoute(path: login, builder: (context, state) => const LoginPage()),

        // ─── Main Shell (Bottom Nav) ───
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: navigatorKey,
          builder: (context, state, navigationShell) {
            return MainShellPage(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Dashboard
            StatefulShellBranch(
              navigatorKey: _dashboardNavKey,
              routes: [
                GoRoute(
                  path: dashboard,
                  builder: (context, state) => const DashboardPage(),
                ),
              ],
            ),
            // Tab 1: History
            StatefulShellBranch(
              navigatorKey: _historyNavKey,
              routes: [
                GoRoute(
                  path: history,
                  builder: (context, state) => const HistoryPage(),
                ),
              ],
            ),
            // Tab 2: Budget
            StatefulShellBranch(
              navigatorKey: _budgetNavKey,
              routes: [
                GoRoute(
                  path: budget,
                  builder: (context, state) => const BudgetPage(),
                ),
              ],
            ),
            // Tab 3: Investment
            StatefulShellBranch(
              navigatorKey: _investmentNavKey,
              routes: [
                GoRoute(
                  path: investment,
                  builder: (context, state) => const InvestmentPage(),
                ),
              ],
            ),
          ],
        ),

        // ─── Full-screen routes (di atas bottom nav) ───
        GoRoute(
          path: wallet,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: transactionForm,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const TransactionFormPage(),
        ),
        GoRoute(
          path: settings,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );
  }
}
