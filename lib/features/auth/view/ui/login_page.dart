import 'package:app_saku_rapi/core/constants/image_constant.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman login SakuRapi.
///
/// Sesuai PRD §7.1: Login hanya via Google Sign-In melalui Supabase Auth.
/// Menangani edge case: user cancel, network error, auth failure,
/// serta masa tunggu penghapusan akun (`loginAccountCooldownDays`).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);

    ref.listen<AppAuthState>(authControllerProvider, (previous, next) {
      final days = next.accountCooldownDaysRemaining;
      if (days == null) return;
      if (previous?.accountCooldownDaysRemaining == days) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        context.showAppAlert(
          context.l10n.loginAccountCooldownDays(days),
          alertType: AlertTypeEnum.warning,
          flashDuration: 5,
        );
        ref
            .read(authControllerProvider.notifier)
            .dismissAccountCooldownNotice();
      });
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Image.asset(ImageConstant.logoApp, width: 200.w, height: 200.w),
              SizedBox(height: 24.h),

              Text(
                l10n.loginTitle,
                style: TextStyleConstants.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              Text(
                l10n.loginSubtitle,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              SakuButton(
                text: l10n.loginWithGoogle,
                isLoading: authState.isLoading,
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  size: 18.w,
                  color: colors.onPrimary,
                ),
                onPressed: () => _handleGoogleSignIn(context, ref),
              ),
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.loginSecurityNote,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();

    if (!context.mounted) return;

    if (!success) {
      final state = ref.read(authControllerProvider);
      final cooldownActive = state.accountCooldownDaysRemaining != null;

      final errorMsg = state.errorMessage;

      if (!cooldownActive &&
          errorMsg != null &&
          !errorMsg.toLowerCase().contains('dibatalkan') &&
          !errorMsg.toLowerCase().contains('cancel')) {
        context.showAppAlert(
          errorMsg.isNotEmpty ? errorMsg : context.l10n.loginErrorGeneric,
          alertType: AlertTypeEnum.error,
        );
      }
    } else {
      context.go(AppRouter.dashboard);
    }
  }
}
