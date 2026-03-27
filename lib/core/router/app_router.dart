import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/ui/login_page.dart';
import 'package:app_saku_rapi/features/auth/view/ui/splash_page.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/ui/budget_detail_page.dart';
import 'package:app_saku_rapi/features/budget/view/ui/budget_page.dart';
import 'package:app_saku_rapi/features/budget/view/ui/completed_budgets_page.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_form_sheet.dart';
import 'package:app_saku_rapi/features/category/view/ui/category_management_page.dart';
import 'package:app_saku_rapi/features/dashboard/view/ui/dashboard_page.dart';
import 'package:app_saku_rapi/features/debt_loan/view/ui/debt_loan_page.dart';
import 'package:app_saku_rapi/features/debt_loan/view/ui/debt_loan_person_page.dart';
import 'package:app_saku_rapi/features/debt_loan/view/ui/settlement_history_page.dart';
import 'package:app_saku_rapi/features/history/view/ui/history_page.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/view/ui/investment_form_page.dart';
import 'package:app_saku_rapi/features/investment/view/ui/investment_page.dart';
import 'package:app_saku_rapi/features/notification/view/ui/notification_settings_page.dart';
import 'package:app_saku_rapi/features/reports/view/ui/report_page.dart';
import 'package:app_saku_rapi/features/settings/view/ui/settings_page.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/ui/transaction_detail_page.dart';
import 'package:app_saku_rapi/features/transaction/view/ui/transaction_form_page.dart';
import 'package:app_saku_rapi/features/wallet/view/ui/wallet_page.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

BuildContext? get appContext {
  try {
    return AppRouter.navigatorKey.currentContext;
  } catch (_) {
    return null;
  }
}

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
  static const String transactionDetail = '/transaction/detail';
  static const String settings = '/settings';
  static const String categories = '/categories';
  static const String budgetForm = '/budget/form';
  static const String budgetDetail = '/budget/detail';
  static const String budgetCompleted = '/budget/completed';
  static const String reports = '/reports';
  static const String notificationSettings = '/notification-settings';
  static const String investmentForm = '/investment/form';
  static const String debtLoan = '/debt-loan';
  static const String debtLoanPerson = '/debt-loan/person';
  static const String settlementHistory = '/debt-loan/settlement-history';

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

  static final _settingsNavKey = GlobalKey<NavigatorState>(
    debugLabel: 'settingsNav',
  );

  static GoRouter createRouter(Ref ref) {
    // final authNotifier = ref.watch(authChangeNotifierProvider);

    return GoRouter(
      navigatorKey: navigatorKey,
      debugLogDiagnostics: true,
      initialLocation: splash,
      // refreshListenable: authNotifier,
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
            StatefulShellBranch(
              navigatorKey: _settingsNavKey,
              routes: [
                GoRoute(
                  path: settings,
                  builder: (context, state) => const SettingsPage(),
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
          builder: (context, state) => TransactionFormPage(
            existingTransaction: state.extra as TransactionModel?,
          ),
        ),
        GoRoute(
          path: transactionDetail,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => TransactionDetailPage(
            transaction: state.extra! as TransactionModel,
          ),
        ),
        // GoRoute(
        //   path: settings,
        //   parentNavigatorKey: navigatorKey,
        //   builder: (context, state) => const SettingsPage(),
        // ),
        GoRoute(
          path: categories,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const CategoryManagementPage(),
        ),
        GoRoute(
          path: budgetForm,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) =>
              BudgetFormSheet(existingBudget: state.extra as BudgetModel?),
        ),
        GoRoute(
          path: budgetDetail,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) =>
              BudgetDetailPage(budget: state.extra! as BudgetModel),
        ),
        GoRoute(
          path: budgetCompleted,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const CompletedBudgetsPage(),
        ),
        GoRoute(
          path: reports,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const ReportPage(),
        ),
        GoRoute(
          path: notificationSettings,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: investmentForm,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => InvestmentFormPage(
            existingInvestment: state.extra as InvestmentModel?,
          ),
        ),
        GoRoute(
          path: debtLoan,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) => const DebtLoanPage(),
        ),
        GoRoute(
          path: debtLoanPerson,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) {
            final extra = state.extra! as Map<String, dynamic>;
            return DebtLoanPersonPage(
              withPerson: extra['withPerson'] as String,
              type: extra['type'] as String,
            );
          },
        ),
        GoRoute(
          path: settlementHistory,
          parentNavigatorKey: navigatorKey,
          builder: (context, state) {
            final extra = state.extra! as Map<String, dynamic>;
            return SettlementHistoryPage(
              referenceTransactionId: extra['referenceTransactionId'] as String,
              originalAmount: extra['originalAmount'] as double,
              withPerson: extra['withPerson'] as String,
              type: extra['type'] as String,
            );
          },
        ),
      ],
    );
  }
}
