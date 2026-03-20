import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Tile untuk satu item transaksi di daftar history.
///
/// Desain: Row horizontal —
/// - **Kiri:** [icon] dibungkus lingkaran bundar berwarna primary soft.
/// - **Tengah:** Column berisi [title] (tebal) dan [subtitle] (abu-abu).
/// - **Kanan:** Nominal Rupiah. Warna mengikuti [type]:
///   `income` → `context.colors.income`, `expense` → minus + `context.colors.expense`.
class TransactionItemTile extends StatelessWidget {
  const TransactionItemTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.icon,
  });

  /// Judul transaksi (misal: nama kategori).
  final String title;

  /// Subtitle (tanggal / catatan).
  final String subtitle;

  /// Nilai nominal transaksi (selalu positif).
  final double amount;

  /// Tipe transaksi: `'income'` atau `'expense'`.
  final String type;

  /// Widget ikon (biasanya [FaIcon]).
  final Widget icon;

  /// Formatter Rupiah statis agar tidak dibuat ulang setiap build.
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final bool isIncome = type == 'income';
    final Color amountColor = isIncome ? appColors.income : appColors.expense;
    final String formattedAmount = isIncome
        ? _rupiahFormat.format(amount)
        : '-${_rupiahFormat.format(amount)}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          // ── Icon lingkaran ──
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),

          SizedBox(width: 12.w),

          // ── Title & Subtitle ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyleConstants.b1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyleConstants.caption.copyWith(
                    color: appColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // ── Nominal ──
          Text(
            formattedAmount,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
