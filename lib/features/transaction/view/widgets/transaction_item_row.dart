import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Parsing hex color ke [Color], fallback abu-abu.
Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF6B7280);
}

/// Memetakan nama ikon string kategori ke [IconData] FontAwesome.
IconData _categoryIcon(String? icon) {
  return switch (icon) {
    'tag' => FontAwesomeIcons.tag,
    'utensils' || 'food' => FontAwesomeIcons.utensils,
    'car' => FontAwesomeIcons.car,
    'house' || 'home' => FontAwesomeIcons.house,
    'shirt' || 'tshirt' => FontAwesomeIcons.shirt,
    'heart-pulse' || 'health' => FontAwesomeIcons.heartPulse,
    'graduation-cap' => FontAwesomeIcons.graduationCap,
    'gamepad' || 'entertainment' => FontAwesomeIcons.gamepad,
    'briefcase' || 'work' => FontAwesomeIcons.briefcase,
    'gift' => FontAwesomeIcons.gift,
    'plane' || 'travel' => FontAwesomeIcons.plane,
    'bolt' || 'electric' => FontAwesomeIcons.bolt,
    'sack-dollar' || 'salary' => FontAwesomeIcons.sackDollar,
    'cart-shopping' || 'shopping' => FontAwesomeIcons.cartShopping,
    'coins' => FontAwesomeIcons.coins,
    'chart-line' => FontAwesomeIcons.chartLine,
    _ => FontAwesomeIcons.tag,
  };
}

/// Satu baris item transaksi dalam mode multi-item.
///
/// Menampilkan:
/// - Nomor urut item
/// - Chip kategori (tap untuk membuka category picker)
/// - Field input nominal
/// - Field catatan per-item (opsional)
/// - Tombol hapus (jika [canDelete] true)
class TransactionItemRow extends ConsumerStatefulWidget {
  const TransactionItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.categories,
    required this.typeColor,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final TransactionItemFormState item;
  final List<CategoryModel> categories;
  final Color typeColor;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  ConsumerState<TransactionItemRow> createState() => _TransactionItemRowState();
}

class _TransactionItemRowState extends ConsumerState<TransactionItemRow> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final amt = widget.item.amount;
    _amountCtrl = TextEditingController(
      text: amt != null && amt > 0 ? amt.toInt().toString() : '',
    );
    _noteCtrl = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _openCategoryPicker() async {
    final cat = await TransactionCategoryPicker.show(
      context,
      categories: widget.categories,
      selectedId: widget.item.categoryId,
      filterType: _currentFormType(),
    );
    if (!mounted) return;
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    if (cat != null) {
      notifier.updateItemCategory(
        widget.index,
        categoryId: cat.id,
        categoryName: cat.name,
        categoryColor: cat.color,
        categoryIcon: cat.icon,
      );
    }
  }

  String? _currentFormType() {
    final type = ref.read(transactionFormControllerProvider).type;
    if (type == 'expense') return 'expense';
    if (type == 'income') return 'income';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    final hasCategory = widget.item.categoryId != null;
    final catColor = _hexColor(widget.item.categoryColor);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: item number + delete button
          Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: widget.typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.typeColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: FaIcon(
                    FontAwesomeIcons.trashCan,
                    size: 14.r,
                    color: appColors.error,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Category chip
          GestureDetector(
            onTap: _openCategoryPicker,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: hasCategory
                    ? catColor.withValues(alpha: 0.1)
                    : appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: hasCategory ? catColor : appColors.border,
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    hasCategory
                        ? _categoryIcon(widget.item.categoryIcon)
                        : FontAwesomeIcons.tag,
                    size: 12.r,
                    color: hasCategory ? catColor : appColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      widget.item.categoryName ??
                          l10n.transactionSelectCategory,
                      style: TextStyleConstants.caption.copyWith(
                        color: hasCategory
                            ? appColors.textPrimary
                            : appColors.textSecondary,
                        fontWeight: hasCategory
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronDown,
                    size: 10.r,
                    color: appColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyleConstants.b1.copyWith(
              fontWeight: FontWeight.w600,
              color: appColors.textPrimary,
            ),
            onChanged: (v) {
              final amount = double.tryParse(v);
              notifier.updateItemAmount(widget.index, amount);
            },
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              prefixStyle: TextStyleConstants.b1.copyWith(
                color: appColors.textSecondary,
              ),
              hintStyle: TextStyleConstants.b1.copyWith(
                color: appColors.textSecondary.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: appColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              isDense: true,
            ),
          ),
          SizedBox(height: 6.h),

          // Note field (opsional)
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyleConstants.caption.copyWith(
              color: appColors.textPrimary,
            ),
            onChanged: (v) {
              notifier.updateItemNote(widget.index, v.isEmpty ? null : v);
            },
            decoration: InputDecoration(
              hintText: l10n.transactionNote,
              hintStyle: TextStyleConstants.caption.copyWith(
                color: appColors.textSecondary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: appColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
