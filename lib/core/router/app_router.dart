import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/ui/login_screen.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:app_saku_rapi/features/budgeting/view/screens/budget_form_screen.dart';
import 'package:app_saku_rapi/features/budgeting/view/screens/budget_list_screen.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/ui/category_form_screen.dart';
import 'package:app_saku_rapi/features/category/view/ui/category_list_screen.dart';
import 'package:app_saku_rapi/features/dashboard/view/ui/dashboard_screen.dart';
import 'package:app_saku_rapi/features/history/models/category_summary_model.dart';
import 'package:app_saku_rapi/features/history/view/ui/expense_breakdown_screen.dart';
import 'package:app_saku_rapi/features/history/view/ui/history_screen.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/view/screens/investment_form_screen.dart';
import 'package:app_saku_rapi/features/investment/view/screens/investment_list_screen.dart';
import 'package:app_saku_rapi/features/notification/view/ui/notification_settings_screen.dart';
import 'package:app_saku_rapi/features/ocr_scan/view/ui/ocr_scan_screen.dart';
import 'package:app_saku_rapi/features/profile/view/ui/profile_screen.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/view/ui/transaction_form_screen.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/ui/wallet_form_screen.dart';
import 'package:app_saku_rapi/features/wallet/view/ui/wallet_list_screen.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

BuildContext? get appContext => AppRouter.navigatorKey.currentContext;

/// Provider untuk [GoRouter] yang di-cache oleh Riverpod.
///
/// Menggunakan `refreshListenable` dari [AuthController] sehingga
/// redirect otomatis terpicu saat status auth berubah.
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Konfigurasi utama routing aplikasi SakuRapi menggunakan GoRouter.
///
/// Semua route didefinisikan di sini secara terpusat.
/// GoRouter akan otomatis redirect berdasarkan status autentikasi user
/// menggunakan `refreshListenable` dari [AuthController].
///
/// Bottom Navigation Bar diimplementasikan via [StatefulShellRoute.indexedStack]
/// agar state tiap tab dipertahankan saat berpindah tab.
class AppRouter {
  AppRouter._();

  /// Navigator key global untuk akses navigasi di luar widget tree.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigator keys per-branch agar setiap tab punya navigator sendiri.
  static final GlobalKey<NavigatorState> _dashboardNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  static final GlobalKey<NavigatorState> _historyNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'history');
  static final GlobalKey<NavigatorState> _budgetNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'budget');
  static final GlobalKey<NavigatorState> _investmentNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'investment');

  /// Daftar nama route (path constants).
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String walletList = '/wallets';
  static const String walletForm = '/wallet-form';
  static const String transactionForm = '/transaction-form';
  static const String history = '/history';
  static const String expenseBreakdown = '/expense-breakdown';
  static const String categoryList = '/categories';
  static const String categoryForm = '/category-form';
  static const String ocrScan = '/ocr-scan';
  static const String budgetList = '/budgets';
  static const String budgetForm = '/budget-form';
  static const String investmentList = '/investments';
  static const String investmentForm = '/investment-form';
  static const String notificationSettings = '/notification-settings';
  static const String profile = '/profile';

  /// Membuat [GoRouter] yang terhubung dengan [AuthController] via
  /// [refreshListenable], sehingga redirect otomatis saat auth state berubah.
  ///
  /// Dipanggil sekali oleh [routerProvider]. Jangan panggil langsung di build().
  static GoRouter createRouter(Ref ref) {
    final authController = ref.read(authControllerProvider.notifier);

    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: login,
      debugLogDiagnostics: true,
      refreshListenable: authController.authListenable,
      redirect: (BuildContext context, GoRouterState state) {
        final authStatus = ref.read(authControllerProvider.notifier).authStatus;
        final bool isOnLogin = state.matchedLocation == login;
        AppLogger.call(
          'Auth Status: $authStatus, Current Route: ${state.matchedLocation}',
        );

        // Selagi loading, jangan redirect kemana-mana.
        if (authStatus == AuthStatus.loading) return null;

        // Belum login & bukan di halaman login → lempar ke login.
        if (authStatus == AuthStatus.unauthenticated && !isOnLogin) {
          return login;
        }

        // Sudah login tapi masih di halaman login → lempar ke dashboard.
        if (authStatus == AuthStatus.authenticated && isOnLogin) {
          return dashboard;
        }

        return null;
      },
      routes: <RouteBase>[
        // ── Auth ──
        GoRoute(
          path: login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen();
          },
        ),

        // ── Main Shell (Bottom Navigation Bar) ──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0 — Dashboard
            StatefulShellBranch(
              navigatorKey: _dashboardNavKey,
              routes: [
                GoRoute(
                  path: dashboard,
                  name: 'dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),

            // Tab 1 — History
            StatefulShellBranch(
              navigatorKey: _historyNavKey,
              routes: [
                GoRoute(
                  path: history,
                  name: 'history',
                  builder: (context, state) => const HistoryScreen(),
                ),
              ],
            ),

            // Tab 2 — Budgeting
            StatefulShellBranch(
              navigatorKey: _budgetNavKey,
              routes: [
                GoRoute(
                  path: budgetList,
                  name: 'budgetList',
                  builder: (context, state) => const BudgetListScreen(),
                ),
              ],
            ),

            // Tab 3 — Investment
            StatefulShellBranch(
              navigatorKey: _investmentNavKey,
              routes: [
                GoRoute(
                  path: investmentList,
                  name: 'investmentList',
                  builder: (context, state) => const InvestmentListScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Standalone Routes (di luar shell / full-screen) ──
        GoRoute(
          path: walletList,
          name: 'walletList',
          builder: (context, state) => const WalletListScreen(),
        ),
        GoRoute(
          path: walletForm,
          name: 'walletForm',
          builder: (context, state) {
            final wallet = state.extra as WalletModel?;
            return WalletFormScreen(wallet: wallet);
          },
        ),
        GoRoute(
          path: transactionForm,
          name: 'transactionForm',
          builder: (context, state) {
            final initialState = state.extra as TransactionFormState?;
            return TransactionFormScreen(initialState: initialState);
          },
        ),
        GoRoute(
          path: expenseBreakdown,
          name: 'expenseBreakdown',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ExpenseBreakdownScreen(
              category: extra['category'] as CategorySummaryModel,
              periodStart: extra['periodStart'] as DateTime,
              periodEnd: extra['periodEnd'] as DateTime,
            );
          },
        ),
        GoRoute(
          path: categoryList,
          name: 'categoryList',
          builder: (context, state) => const CategoryListScreen(),
        ),
        GoRoute(
          path: categoryForm,
          name: 'categoryForm',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is CategoryModel) {
              return CategoryFormScreen(category: extra);
            }
            final map = extra as Map<String, dynamic>?;
            return CategoryFormScreen(initialType: map?['type'] as String?);
          },
        ),
        GoRoute(
          path: ocrScan,
          name: 'ocrScan',
          builder: (context, state) => const OcrScanScreen(),
        ),
        GoRoute(
          path: budgetForm,
          name: 'budgetForm',
          builder: (context, state) {
            final budget = state.extra as BudgetModel?;
            return BudgetFormScreen(budget: budget);
          },
        ),
        GoRoute(
          path: investmentForm,
          name: 'investmentForm',
          builder: (context, state) {
            final investment = state.extra as InvestmentModel?;
            return InvestmentFormScreen(investment: investment);
          },
        ),
        GoRoute(
          path: notificationSettings,
          name: 'notificationSettings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
