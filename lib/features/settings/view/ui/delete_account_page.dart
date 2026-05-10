import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/auth/repositories/auth_repository.dart';
import 'package:app_saku_rapi/features/settings/view/widgets/delete_account_confirm_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman dedikasi untuk soft delete akun (marker di `public.users`).
///
/// Mengarah dari [SettingsPage]. Operasi tulis RPC di [AuthRepository].
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  Future<void> _handleDeleteTap() async {
    if (!mounted) return;

    final confirmed = await showDeleteAccountConfirmDialog(context);
    if (confirmed != true || !mounted) return;

    AppLogger.call(
      '[Settings] [DeleteAccount] Invoking soft_delete_own_account',
      colorLog: ColorLog.blue,
    );

    context.showLoadingOverlay();
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.softDeleteOwnAccount();

      if (!mounted) return;

      if (result is DataStateSuccess<void>) {
        AppLogger.call(
          '[Settings] [DeleteAccount] RPC succeeded, signing out',
          colorLog: ColorLog.green,
        );
        await ref.read(authControllerProvider.notifier).signOut();
        if (!mounted) return;

        context.showAppAlert(
          context.l10n.deleteAccountSuccessSignedOut,
          alertType: AlertTypeEnum.info,
          flashDuration: 4,
        );
        context.go(AppRouter.login);
      } else {
        final detail = result.dataError();
        final msg = detail?.$1 ?? '';
        AppLogger.logError(
          '[Settings] [DeleteAccount] RPC failed: $msg',
          runtimeType: _DeleteAccountPageState,
        );
        context.showAppAlert(
          msg.isNotEmpty ? msg : context.l10n.loginErrorGeneric,
          alertType: AlertTypeEnum.error,
        );
      }
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.deleteAccountScreenTitle),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          Text(
            l10n.deleteAccountIntroTitle,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          _bullet(
            FaIcon(FontAwesomeIcons.circleInfo, size: 14.w, color: colors.primary),
            l10n.deleteAccountBulletSoftDelete,
          ),
          SizedBox(height: 8.h),
          _bullet(
            FaIcon(FontAwesomeIcons.clockRotateLeft, size: 14.w, color: colors.primary),
            l10n.deleteAccountBulletCooldown,
          ),
          SizedBox(height: 8.h),
          _bullet(
            FaIcon(FontAwesomeIcons.circleCheck, size: 14.w, color: colors.primary),
            l10n.deleteAccountBulletReactivate,
          ),
          SizedBox(height: 32.h),
          SakuButton(
            text: l10n.deleteAccountButton,
            backgroundColor: colors.error,
            textColor: colors.onPrimary,
            onPressed: _handleDeleteTap,
          ),
        ],
      ),
    );
  }

  Widget _bullet(Widget icon, String text) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.only(top: 2.h), child: icon),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
