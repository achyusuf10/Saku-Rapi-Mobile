import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Quick action buttons di dashboard.
///
/// Entry points: Manual Input, Voice Input, Scan Receipt, Wallets.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final actions = [
      _QuickAction(
        icon: FontAwesomeIcons.penToSquare,
        label: l10n.fabManualInput,
        color: colors.primary,
        onTap: () => context.push(AppRouter.transactionForm),
      ),
      _QuickAction(
        icon: FontAwesomeIcons.microphone,
        label: l10n.fabVoiceInput,
        color: colors.info,
        onTap: () {}, // Voice input — upcoming
      ),
      _QuickAction(
        icon: FontAwesomeIcons.camera,
        label: l10n.fabScanReceipt,
        color: colors.accent,
        onTap: () {}, // OCR scan — upcoming
      ),
      _QuickAction(
        icon: FontAwesomeIcons.wallet,
        label: l10n.walletTitle,
        color: colors.transfer,
        onTap: () => context.push(AppRouter.wallet),
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

    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: action.color.withValues(alpha: 0.1),
            ),
            child: Center(
              child: FaIcon(action.icon, size: 18.w, color: action.color),
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
