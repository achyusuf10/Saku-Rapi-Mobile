import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Toggle **Satu / Multi** transaksi + hint penjelasan.
class TransactionMultiManualModeHeader extends ConsumerWidget {
  const TransactionMultiManualModeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final form = ref.watch(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);
    final multi = form.isMultiManualMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(
                      l10n.transactionMultiManualSegmentSingle,
                      style: TextStyleConstants.label1,
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(
                      l10n.transactionMultiManualSegmentMulti,
                      style: TextStyleConstants.label1,
                    ),
                  ),
                ],
                selected: {multi},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  ctrl.setMultiManualMode(s.first);
                },
              ),
            ),
          ],
        ),
        if (multi) ...[
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 14.w,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.transactionMultiManualHint,
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
