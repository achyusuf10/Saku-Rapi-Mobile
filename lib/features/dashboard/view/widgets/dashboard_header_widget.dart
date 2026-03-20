import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Header dashboard: nama user, total saldo, toggle sembunyikan.
///
/// Background gradient hijau soft (primary → primaryLight).
/// Ikon 👁️ untuk hide/show saldo, state disimpan di Hive.
class DashboardHeaderWidget extends ConsumerStatefulWidget {
  const DashboardHeaderWidget({super.key});

  @override
  ConsumerState<DashboardHeaderWidget> createState() =>
      _DashboardHeaderWidgetState();
}

class _DashboardHeaderWidgetState extends ConsumerState<DashboardHeaderWidget> {
  static const String _hideBalanceKey = 'hideBalance';
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _isHidden = HiveService.get<bool>(key: _hideBalanceKey) ?? false;
  }

  void _toggleVisibility() {
    setState(() => _isHidden = !_isHidden);
    HiveService.set(key: _hideBalanceKey, data: _isHidden);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    final authState = ref.watch(authControllerProvider);
    final dashState = ref.watch(dashboardControllerProvider);

    final userName = authState.whenOrNull(data: (user) => user?.fullName) ?? '';
    final firstName = userName.split(' ').first;

    final totalBalance =
        dashState.whenOrNull(data: (data) => data.totalBalance) ?? 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appColors.primary, appColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting row ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $firstName 👋',
                        style: TextStyleConstants.b1.copyWith(
                          color: appColors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.dashboardTitle,
                        style: TextStyleConstants.h6.copyWith(
                          fontWeight: FontWeight.w700,
                          color: appColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Avatar ──
                if (authState.value?.avatarUrl != null)
                  CircleAvatar(
                    radius: 20.r,
                    backgroundImage: NetworkImage(authState.value!.avatarUrl!),
                  ),
              ],
            ),

            SizedBox(height: 20.h),

            // ── Total saldo ──
            Text(
              l10n.dashboardTotalBalance,
              style: TextStyleConstants.caption.copyWith(
                color: appColors.onPrimary.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: dashState.when(
                    loading: () => _buildSkeletonText(appColors),
                    error: (_, __) => Text(
                      '-',
                      style: TextStyleConstants.h5.copyWith(
                        fontWeight: FontWeight.w800,
                        color: appColors.onPrimary,
                      ),
                    ),
                    data: (_) => Text(
                      _isHidden ? '••••••••' : totalBalance.toCurrency(),
                      style: TextStyleConstants.h5.copyWith(
                        fontWeight: FontWeight.w800,
                        color: appColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleVisibility,
                  child: Padding(
                    padding: EdgeInsets.all(8.r),
                    child: FaIcon(
                      _isHidden
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      color: appColors.onPrimary.withValues(alpha: 0.8),
                      size: 18.r,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton placeholder saat loading.
  Widget _buildSkeletonText(appColors) {
    return Container(
      height: 28.h,
      width: 180.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
