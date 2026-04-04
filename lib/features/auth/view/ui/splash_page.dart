import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

/// Halaman splash screen SakuRapi.
///
/// Ditampilkan saat app pertama kali dibuka.
/// Melakukan pengecekan session existing:
/// - Jika ada session aktif → redirect ke dashboard.
/// - Jika tidak ada → redirect ke login.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    await ref.read(authControllerProvider.notifier).restoreSession();

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    if (authState.isAuthenticated) {
      context.go(AppRouter.dashboard);
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 36.w,
                  color: colors.primary,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // App Name
            Text(
              l10n.appName,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 32.h),

            // Loading indicator
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5.w,
                color: colors.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
