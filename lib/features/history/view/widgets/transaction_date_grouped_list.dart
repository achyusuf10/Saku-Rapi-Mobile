import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/core/utils/transaction_group_utils.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// List transaksi yang dikelompokkan berdasarkan tanggal.
///
/// Menampilkan header tanggal + net total per grup, diikuti card berisi
/// [HistoryTransactionTile]. Cocok dipakai di halaman budget detail dan
/// report category transactions.
class TransactionDateGroupedList extends StatelessWidget {
  const TransactionDateGroupedList({
    super.key,
    required this.transactions,
    required this.onTap,
    this.padding,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  final List<TransactionModel> transactions;
  final void Function(TransactionModel tx) onTap;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final grouped = TransactionGroupUtils.groupByDate(transactions);
    final sections = grouped.entries.toList();
    final colors = context.colors;

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? EdgeInsets.zero,
      itemCount: sections.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final entry = sections[index];
        final txList = entry.value;
        final dateLabel = _formatDateKey(entry.key);
        final netTotal = TransactionGroupUtils.groupNetTotal(txList);
        final isPositive = netTotal >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Date header ───
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: TextStyleConstants.label1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${txList.length} transaksi',
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (netTotal != 0)
                  Text(
                    '${isPositive ? '+' : ''}${netTotal.toCompactCurrency()}',
                    style: TextStyleConstants.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPositive ? colors.income : colors.expense,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            // ─── Transaction card ───
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < txList.length; i++) ...[
                    HistoryTransactionTile(
                      transaction: txList[i],
                      onTap: () => onTap(txList[i]),
                    ),
                    if (i < txList.length - 1)
                      Divider(
                        height: 1,
                        indent: 70.w,
                        color: colors.border,
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateKey(String key) {
    try {
      final date = SakuDateUtils.parseRequiredDate(key, fieldName: 'date_key');
      return date.extToDateStringDDMMMMYYYY();
    } catch (_) {
      return key;
    }
  }
}
