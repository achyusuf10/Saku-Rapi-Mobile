import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
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
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: colors.surface,
          selectedItemColor: colors.primary,
          selectedLabelStyle: TextStyleConstants.label3.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyleConstants.label3,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: FaIcon(
                FontAwesomeIcons.house,
                size: 20.w,
                color: colors.textSecondary,
              ),
              activeIcon: FaIcon(
                FontAwesomeIcons.house,
                size: 20.w,
                color: colors.primary,
              ),
              label: l10n.navDashboard,
            ),
            BottomNavigationBarItem(
              icon: FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 20.w,
                color: colors.textSecondary,
              ),
              activeIcon: FaIcon(
                FontAwesomeIcons.clockRotateLeft,
                size: 20.w,
                color: colors.primary,
              ),
              label: l10n.navHistory,
            ),
            BottomNavigationBarItem(
              icon: FaIcon(
                FontAwesomeIcons.chartPie,
                size: 20.w,
                color: colors.textSecondary,
              ),
              activeIcon: FaIcon(
                FontAwesomeIcons.chartPie,
                size: 20.w,
                color: colors.primary,
              ),
              label: l10n.navBudget,
            ),
            BottomNavigationBarItem(
              icon: FaIcon(
                FontAwesomeIcons.chartColumn,
                size: 20.w,
                color: colors.textSecondary,
              ),
              activeIcon: FaIcon(
                FontAwesomeIcons.chartColumn,
                size: 20.w,
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
