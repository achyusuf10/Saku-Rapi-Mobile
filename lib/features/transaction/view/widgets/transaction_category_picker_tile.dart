import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Category picker tile dengan ikon lingkaran berwarna.
///
/// Menampilkan kategori yang dipilih atau placeholder jika belum dipilih.
/// [category] dipakai jika ada (multi-item: satu kategori parent);
/// jika null, fallback ke field kategori pada [item] (single-item / legacy).
class TransactionCategoryPickerTile extends StatelessWidget {
  const TransactionCategoryPickerTile({
    super.key,
    required this.type,
    required this.onTap,
    required this.iconColor,
    this.category,
    this.item,
  });

  final TransactionTypeEnum type;
  /// Kategori transaksi level parent (prioritas tampilan).
  final CategoryModel? category;
  final TransactionItemModel? item;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = category?.name ?? item?.categoryName;
    final displayIcon = category?.icon ?? item?.categoryIcon;
    final displayColorHex = category?.color ?? item?.categoryColor;
    final hasCategory = displayName != null;
    final categoryColor = displayColorHex != null
        ? parseHexColor(displayColorHex)
        : null;
    final circleColor = categoryColor ?? iconColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: circleColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasCategory && displayIcon != null
                    ? SakuCategoryIcon(
                        iconName: displayIcon,
                        color: circleColor,
                        size: 16,
                        showBackground: false,
                      )
                    : FaIcon(
                        FontAwesomeIcons.layerGroup,
                        size: 16.w,
                        color: circleColor,
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.transactionCategory.toUpperCase(),
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    displayName ?? context.l10n.transactionSelectCategory,
                    style: TextStyleConstants.b2.copyWith(
                      color: hasCategory
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasCategory
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.w,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
