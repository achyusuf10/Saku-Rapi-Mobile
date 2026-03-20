import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/view/widgets/auth_google_button.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Layar login SakuRapi.
///
/// Desain elegan: logo besar di tengah, subtitle motivasi,
/// tombol "Masuk dengan Google", dan catatan keamanan.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Logo / App Name ──
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.wallet,
                    size: 36.r,
                    color: appColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                l10n.appName,
                style: TextStyleConstants.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: appColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),

              // ── Subtitle ──
              Text(
                l10n.loginSubtitle,
                style: TextStyleConstants.b1.copyWith(
                  color: appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 4),

              // ── Tombol Google Sign-In ──
              AuthGoogleButton(
                text: l10n.loginWithGoogle,
                onPressed: () => _onGoogleLogin(context, ref),
              ),

              SizedBox(height: 16.h),

              // ── Security Note ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 12.r,
                    color: appColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.loginSecurityNote,
                    style: TextStyleConstants.caption.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Handler tombol login Google.
  ///
  /// Tampilkan loading overlay selama proses, dan alert jika error.
  Future<void> _onGoogleLogin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    context.showLoadingOverlay();
    try {
      await ref.read(authControllerProvider.notifier).signIn();

      if (!context.mounted) return;

      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        context.showAppAlert(
          authState.error?.toString() ?? l10n.loginErrorGeneric,
          alertType: AlertTypeEnum.error,
        );
      }
      // Jika sukses, GoRouter redirect otomatis ke /dashboard.
    } finally {
      if (context.mounted) context.closeOverlay();
    }
  }
}
