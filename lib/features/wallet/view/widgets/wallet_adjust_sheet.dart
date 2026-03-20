import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Bottom sheet untuk menyesuaikan saldo wallet.
///
/// Mengembalikan [double] (nilai saldo sebenarnya yang diinput user),
/// atau `null` jika dibatalkan.
class WalletAdjustSheet extends StatefulWidget {
  const WalletAdjustSheet({super.key, required this.wallet});

  /// Wallet yang saldo-nya akan disesuaikan.
  final WalletModel wallet;

  /// Menampilkan bottom sheet dan mengembalikan saldo sebenarnya.
  static Future<double?> show(
    BuildContext context, {
    required WalletModel wallet,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => WalletAdjustSheet(wallet: wallet),
    );
  }

  @override
  State<WalletAdjustSheet> createState() => _WalletAdjustSheetState();
}

class _WalletAdjustSheetState extends State<WalletAdjustSheet> {
  late final TextEditingController _ctrl;
  double _diff = 0;

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = double.tryParse(_ctrl.text.trim()) ?? 0;
    setState(() => _diff = value - widget.wallet.balance);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Title
          Text(
            l10n.walletAdjust,
            style: TextStyleConstants.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.walletAdjustHint,
            style: TextStyleConstants.caption.copyWith(
              color: appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Current balance display
          Text(
            '${l10n.walletBalance}: ${_rupiahFormat.format(widget.wallet.balance)}',
            style: TextStyleConstants.b2.copyWith(
              color: appColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),

          // Actual balance input
          Text(
            l10n.walletAdjustActual,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
              color: appColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          SakuTextField(
            controller: _ctrl,
            hintText: '0',
            prefixText: 'Rp ',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          SizedBox(height: 12.h),

          // Difference display
          Row(
            children: [
              Text(
                '${l10n.walletAdjustDiff}: ',
                style: TextStyleConstants.b2.copyWith(
                  color: appColors.textSecondary,
                ),
              ),
              Text(
                _diff >= 0
                    ? '+${_rupiahFormat.format(_diff)}'
                    : _rupiahFormat.format(_diff),
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _diff >= 0 ? appColors.income : appColors.expense,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Save button
          SakuButton(
            text: l10n.walletSave,
            onPressed: () {
              final value = double.tryParse(_ctrl.text.trim());
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
          ),
        ],
      ),
    );
  }
}
