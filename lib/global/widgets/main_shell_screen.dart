import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Shell screen utama dengan Bottom Navigation Bar (4 tab).
///
/// Menggunakan [StatefulNavigationShell] dari GoRouter agar
/// state tiap tab dipertahankan saat berpindah (IndexedStack).
///
/// Tab:
/// 0 - Dashboard (Beranda)
/// 1 - History (Riwayat)
/// 2 - Budget (Anggaran)
/// 3 - Investment (Investasi)
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  /// Navigation shell yang di-provide oleh GoRouter [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appColors.surface,
          boxShadow: [
            BoxShadow(
              color: appColors.border.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: FontAwesomeIcons.house,
                  label: l10n.navDashboard,
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                  appColors: appColors,
                ),
                _NavItem(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  label: l10n.navHistory,
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                  appColors: appColors,
                ),
                _NavItem(
                  icon: FontAwesomeIcons.wallet,
                  label: l10n.navBudget,
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                  appColors: appColors,
                ),
                _NavItem(
                  icon: FontAwesomeIcons.chartLine,
                  label: l10n.navInvestment,
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => _onTap(3),
                  appColors: appColors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pindah tab via [StatefulNavigationShell.goBranch].
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Item navigasi bawah individual.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme appColors;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? appColors.primary : appColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? appColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: FaIcon(icon, size: 18.r, color: color),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
