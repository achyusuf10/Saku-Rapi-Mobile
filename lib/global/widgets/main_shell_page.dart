import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Scaffold utama dengan Bottom Navigation Bar.
///
/// Digunakan oleh [StatefulShellRoute.indexedStack] untuk mempertahankan
/// state tiap tab saat berpindah.
/// 4 tab sesuai PRD: Dashboard, Riwayat, Anggaran, Investasi.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: colors.surface,
          indicatorColor: colors.primaryLight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64.h,
          destinations: [
            NavigationDestination(
              icon: FaIcon(
                FontAwesomeIcons.house,
                size: 18.w,
                color: colors.textSecondary,
              ),
              selectedIcon: FaIcon(
                FontAwesomeIcons.house,
                size: 18.w,
                color: colors.primary,
              ),
              label: l10n.navDashboard,
            ),
            NavigationDestination(
              icon: FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 18.w,
                color: colors.textSecondary,
              ),
              selectedIcon: FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 18.w,
                color: colors.primary,
              ),
              label: l10n.navHistory,
            ),
            NavigationDestination(
              icon: FaIcon(
                FontAwesomeIcons.chartPie,
                size: 18.w,
                color: colors.textSecondary,
              ),
              selectedIcon: FaIcon(
                FontAwesomeIcons.chartPie,
                size: 18.w,
                color: colors.primary,
              ),
              label: l10n.navBudget,
            ),
            NavigationDestination(
              icon: FaIcon(
                FontAwesomeIcons.chartColumn,
                size: 18.w,
                color: colors.textSecondary,
              ),
              selectedIcon: FaIcon(
                FontAwesomeIcons.chartColumn,
                size: 18.w,
                color: colors.primary,
              ),
              label: l10n.navInvestment,
            ),
          ],
        ),
      ),
    );
  }
}
