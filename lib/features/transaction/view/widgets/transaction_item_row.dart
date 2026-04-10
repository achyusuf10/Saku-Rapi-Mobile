import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget baris item untuk mode multi-item pada form transaksi.
///
/// Menampilkan: drag handle, nama item, qty, unit price, category picker.
/// Subtotal dihitung otomatis jika qty & unitPrice tersedia.
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
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName ?? '');
    _qtyController = TextEditingController(
      text: widget.item.qty != 1 ? _formatQty(widget.item.qty) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  /// Format qty: tampilkan tanpa desimal jika bulat.
  String _formatQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasQtyPrice = widget.item.unitPrice != null && widget.item.qty > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: drag handle + item number + delete ───
          Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FaIcon(
                    FontAwesomeIcons.gripVertical,
                    size: 14.w,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
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
            label: l10n.transactionItemName,
            hint: l10n.transactionItemNameHint,
            onChanged: (val) {
              widget.onChanged(widget.item.copyWith(itemName: val));
            },
          ),
          SizedBox(height: 10.h),

          // ─── Qty + Unit Price (side by side) ───
          Row(
            children: [
              // Qty
              SizedBox(
                width: 90.w,
                child: SakuTextField(
                  controller: _qtyController,
                  label: l10n.transactionItemQty,
                  hint: '1',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (val) {
                    final qty = double.tryParse(val) ?? 1;
                    widget.onChanged(widget.item.copyWith(qty: qty));
                  },
                ),
              ),
              SizedBox(width: 10.w),
              // Unit price
              Expanded(
                child: SakuCurrencyField(
                  label: l10n.transactionItemUnitPrice,
                  initialValue: widget.item.unitPrice,
                  onChanged: (val) {
                    widget.onChanged(
                      widget.item.copyWith(unitPrice: val > 0 ? val : null),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Amount / Subtotal ───
          if (hasQtyPrice) ...[
            // Show computed subtotal read-only
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.transactionItemSubtotal,
                    style: TextStyleConstants.label1.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.item.amount.toCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Manual amount input
            SakuCurrencyField(
              label: l10n.transactionItemSubtotal,
              initialValue: widget.item.amount > 0 ? widget.item.amount : null,
              onChanged: (val) {
                widget.onChanged(widget.item.copyWith(amount: val));
              },
            ),
          ],
          SizedBox(height: 10.h),

          // ─── Category picker ───
          GestureDetector(
            onTap: _pickCategory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  if (widget.item.categoryIcon != null) ...[
                    SakuCategoryIcon(
                      iconName: widget.item.categoryIcon!,
                      color: parseHexColor(
                        widget.item.categoryColor ?? '#6B7280',
                      ),
                      size: 16,
                      showBackground: false,
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
}
