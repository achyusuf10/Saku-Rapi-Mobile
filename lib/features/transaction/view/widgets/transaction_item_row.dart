import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget baris item untuk mode multi-item pada form transaksi expense.
///
/// Setiap baris menampilkan: nama item, amount, category picker, note opsional.
/// Bisa dihapus kecuali baris terakhir.
class TransactionItemRow extends StatefulWidget {
  const TransactionItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
    required this.categoryType,
  });

  final TransactionItemModel item;
  final int index;
  final ValueChanged<TransactionItemModel> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;
  final CategoryType categoryType;

  @override
  State<TransactionItemRow> createState() => _TransactionItemRowState();
}

class _TransactionItemRowState extends State<TransactionItemRow> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: item number + delete ───
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Item ${widget.index + 1}',
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.canRemove)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: FaIcon(
                    FontAwesomeIcons.circleXmark,
                    size: 18.w,
                    color: colors.error,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Item name ───
          SakuTextField(
            controller: _nameController,
            label: 'Nama Item',
            hint: 'Contoh: Kopi, Nasi Goreng',
            onChanged: (val) {
              widget.onChanged(widget.item.copyWith(itemName: val));
            },
          ),
          SizedBox(height: 10.h),

          // ─── Amount ───
          SakuCurrencyField(
            label: l10n.transactionAmount,
            initialValue: widget.item.amount > 0 ? widget.item.amount : null,
            onChanged: (val) {
              widget.onChanged(widget.item.copyWith(amount: val));
            },
          ),
          SizedBox(height: 10.h),

          // ─── Category picker ───
          GestureDetector(
            onTap: _pickCategory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  if (widget.item.categoryIcon != null) ...[
                    FaIcon(
                      CategoryIconMapper.getIcon(widget.item.categoryIcon!),
                      size: 16.w,
                      color: widget.item.categoryColor != null
                          ? _parseColor(widget.item.categoryColor!)
                          : colors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: Text(
                      widget.item.categoryName ??
                          l10n.transactionSelectCategory,
                      style: TextStyleConstants.b2.copyWith(
                        color: widget.item.categoryName != null
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 12.w,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await CategoryPickerSheet.show(
      context: context,
      type: widget.categoryType,
      selectedId: widget.item.categoryId,
    );

    if (selected != null) {
      widget.onChanged(
        widget.item.copyWith(
          categoryId: selected.id,
          categoryName: selected.name,
          categoryIcon: selected.icon,
          categoryColor: selected.color,
        ),
      );
    }
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
