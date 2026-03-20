import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Daftar item multi-transaksi.
///
/// Digunakan saat mode multi-item aktif (hanya untuk tipe `expense`).
/// Menampilkan:
/// - Daftar [TransactionItemRow] per item
/// - Tombol "+ Tambah Item"
/// - Baris total grand total di bawah
class TransactionMultiItemList extends ConsumerWidget {
  const TransactionMultiItemList({
    super.key,
    required this.categories,
    required this.typeColor,
  });

  final List<CategoryModel> categories;
  final Color typeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(transactionFormControllerProvider.notifier);
    final state = ref.watch(transactionFormControllerProvider);
    final appColors = context.colors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Item rows
        ...state.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TransactionItemRow(
            key: ValueKey('item_$index'),
            index: index,
            item: item,
            categories: categories,
            typeColor: typeColor,
            canDelete: state.items.length > 1,
            onDelete: () => controller.removeItem(index),
          );
        }),

        // Add item button
        TextButton.icon(
          onPressed: controller.addItem,
          icon: FaIcon(FontAwesomeIcons.plus, size: 12.r, color: typeColor),
          label: Text(
            l10n.transactionAddItem,
            style: TextStyleConstants.b2.copyWith(
              color: typeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Grand total row
        Container(
          margin: EdgeInsets.only(top: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.transactionGrandTotal,
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
              Text(
                state.totalAmount.toCurrency(withPrefix: true),
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
