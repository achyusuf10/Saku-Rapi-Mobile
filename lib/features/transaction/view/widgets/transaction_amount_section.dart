import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centered amount section with label and currency field.
///
/// Digunakan di form transaksi untuk input nominal transaksi.
/// Menampilkan label "AMOUNT" dan [SakuCurrencyField] di tengah.
class TransactionAmountSection extends StatelessWidget {
  const TransactionAmountSection({
    super.key,
    required this.typeColor,
    required this.onChanged,
    this.initialValue,
  });

  final Color typeColor;
  final ValueChanged<double> onChanged;
  final double? initialValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.transactionAmount.toUpperCase(),
            style: TextStyleConstants.overline.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          SakuCurrencyField(
            initialValue: initialValue,
            onChanged: onChanged,
            autofocus: initialValue == null,
          ),
        ],
      ),
    );
  }
}
