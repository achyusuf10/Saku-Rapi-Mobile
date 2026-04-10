import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/ocr/view/ui/ocr_result_sheet.dart';
import 'package:app_saku_rapi/features/voice/controllers/pending_voice_prefill_provider.dart';
import 'package:app_saku_rapi/features/voice/view/ui/text_input_sheet.dart';
import 'package:app_saku_rapi/features/voice/view/ui/voice_input_sheet.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Quick action buttons di dashboard.
///
/// Entry points: Manual Input, Voice Input, Scan Receipt, Wallets.
class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    final actions = [
      _QuickAction(
        icon: FontAwesomeIcons.penToSquare,
        label: l10n.fabManualInput,
        color: colors.primary,
        onTap: () async {
          final result = await context.push<bool>(AppRouter.transactionForm);
          if (result == true) {
            ref.read(dashboardControllerProvider.notifier).loadDashboard();
            ref.read(walletControllerProvider.notifier).loadWallets();
          }
        },
      ),
      _QuickAction(
        icon: FontAwesomeIcons.microphone,
        label: l10n.fabVoiceInput,
        color: colors.info,
        onTap: () => _handleVoiceInput(context, ref),
      ),
      _QuickAction(
        icon: FontAwesomeIcons.camera,
        label: l10n.fabScanReceipt,
        color: colors.accent,
        onTap: () => _handleOcrScan(context, ref),
      ),
      _QuickAction(
        icon: FontAwesomeIcons.keyboard,
        label: l10n.fabTextInput,
        color: colors.transfer,
        onTap: () => _handleTextInput(context, ref),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _QuickActionButton(action: action),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Buka voice input sheet → jika berhasil, set pending prefill → navigate ke form.
  Future<void> _handleVoiceInput(BuildContext context, WidgetRef ref) async {
    final result = await VoiceInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      final navResult = await context.push<bool>(AppRouter.transactionForm);
      if (navResult == true && context.mounted) {
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(walletControllerProvider.notifier).loadWallets();
      }
    }
  }

  /// Buka OCR scan sheet → jika berhasil, set pending prefill → navigate ke form.
  Future<void> _handleOcrScan(BuildContext context, WidgetRef ref) async {
    final result = await OcrResultSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingOcrPrefillProvider.notifier).state = result;
      final navResult = await context.push<bool>(AppRouter.transactionForm);
      if (navResult == true && context.mounted) {
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(walletControllerProvider.notifier).loadWallets();
      }
    }
  }

  /// Buka text input sheet → jika berhasil, set pending prefill → navigate ke form.
  Future<void> _handleTextInput(BuildContext context, WidgetRef ref) async {
    final result = await TextInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      final navResult = await context.push<bool>(AppRouter.transactionForm);
      if (navResult == true && context.mounted) {
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(walletControllerProvider.notifier).loadWallets();
      }
    }
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = action.color;

    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: colors.surfaceVariant,
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: FaIcon(action.icon, size: 18.w, color: iconColor),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            action.label,
            style: TextStyleConstants.label3.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
