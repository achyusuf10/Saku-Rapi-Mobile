import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/core/utils/transaction_group_utils.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// List transaksi yang dikelompokkan berdasarkan tanggal.
///
/// Menampilkan header tanggal + net total per grup, diikuti card berisi
/// [HistoryTransactionTile]. Cocok dipakai di halaman budget detail,
/// report category transactions, dan history page (byDate mode).
///
/// Mendukung **load-more** opsional: sediakan [onLoadMore], [hasMore], dan
/// [isLoadingMore] agar scroll trigger di-append otomatis di bawah list.
class TransactionDateGroupedList extends StatelessWidget {
  const TransactionDateGroupedList({
    super.key,
    required this.transactions,
    required this.onTap,
    this.padding,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    // ─── Load-more ───
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreKey,
  });

  final List<TransactionModel> transactions;
  final void Function(TransactionModel tx) onTap;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  /// Dipanggil saat load-more trigger terlihat. Jika null, load-more dinonaktifkan.
  final VoidCallback? onLoadMore;

  /// Apakah masih ada data berikutnya yang bisa di-load.
  final bool hasMore;

  /// Apakah sedang loading data berikutnya.
  final bool isLoadingMore;

  /// Key unik untuk [VisibilityDetector] load-more. Wajib diisi jika [onLoadMore] != null.
  final Key? loadMoreKey;

  bool get _hasLoadMore => onLoadMore != null;

  @override
  Widget build(BuildContext context) {
    final grouped = TransactionGroupUtils.groupByDate(transactions);
    final sections = grouped.entries.toList();
    final colors = context.colors;

    // +1 slot untuk load-more footer jika aktif
    final itemCount = sections.length + (_hasLoadMore ? 1 : 0);

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        // ─── Load-more footer slot ───
        if (_hasLoadMore && index == sections.length) {
          if (isLoadingMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: SakuLoadingIndicator()),
            );
          }
          if (!hasMore) return const SizedBox.shrink();
          return VisibilityDetector(
            key: loadMoreKey ?? const Key('transaction_date_list_load_more'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction > 0) onLoadMore?.call();
            },
            child: const SizedBox(height: 1),
          );
        }

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
                      Divider(height: 1, indent: 70.w, color: colors.border),
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
