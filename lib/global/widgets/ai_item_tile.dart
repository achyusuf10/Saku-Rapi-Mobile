import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tile untuk menampilkan satu item dari hasil AI parse.
///
/// Dipakai bersama oleh fitur Suara, Teks, dan Scan Struk.
/// Menerima field generic (bukan model-specific) agar reusable.
class AiItemTile extends StatelessWidget {
  const AiItemTile({
    super.key,
    required this.index,
    this.name,
    this.qty = 1,
    this.unitPrice,
    required this.subtotal,
    this.categoryName,
  });

  /// Index urutan item (0-based, ditampilkan +1).
  final int index;

  /// Nama item.
  final String? name;

  /// Jumlah / kuantitas.
  final double qty;

  /// Harga per unit.
  final double? unitPrice;

  /// Subtotal item.
  final double subtotal;

  /// Nama kategori yang sudah di-resolve (null jika tidak ada).
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Nomor urut (badge bulat)
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyleConstants.caption.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Nama + detail qty + kategori badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '-',
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (qty > 1 || unitPrice != null)
                  Text(
                    '${qty > 1 ? '${qty.toInt()}x ' : ''}'
                    '${unitPrice != null ? '@ ${unitPrice!.toCurrency(withPrefix: false)}' : ''}',
                    style: TextStyleConstants.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (categoryName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        categoryName!,
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.accent,
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Subtotal
          Text(
            subtotal.toCurrency(withPrefix: false),
            style: TextStyleConstants.b2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
