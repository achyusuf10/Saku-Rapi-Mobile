import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Baris tappable untuk memilih tanggal transaksi.
///
/// Menampilkan tanggal yang diformat dan membuka [showDatePicker] saat ditekan.
class TransactionDatePicker extends StatelessWidget {
  const TransactionDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  static final DateFormat _fmt = DateFormat('EEE, d MMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: appColors.border),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.calendarDays,
              size: 16.r,
              color: appColors.primary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.transactionDate,
                    style: TextStyleConstants.label2.copyWith(
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _fmt.format(selectedDate),
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
