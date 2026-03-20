import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Parsing hex color string ke [Color], fallback ke abu-abu.
Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF6B7280);
}

/// Memetakan nama ikon string kategori ke [IconData] FontAwesome.
///
/// Ikon default: `FontAwesomeIcons.tag`.
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
    'phone' => FontAwesomeIcons.phone,
    'sack-dollar' || 'salary' => FontAwesomeIcons.sackDollar,
    'money-bill' => FontAwesomeIcons.moneyBill,
    'coins' => FontAwesomeIcons.coins,
    'chart-line' => FontAwesomeIcons.chartLine,
    'building-columns' || 'bank' => FontAwesomeIcons.buildingColumns,
    'cart-shopping' || 'shopping' => FontAwesomeIcons.cartShopping,
    'baby' => FontAwesomeIcons.baby,
    'paw' || 'pet' => FontAwesomeIcons.paw,
    'dumbbell' || 'sport' => FontAwesomeIcons.dumbbell,
    'book' => FontAwesomeIcons.book,
    'wifi' => FontAwesomeIcons.wifi,
    'droplet' || 'water' => FontAwesomeIcons.droplet,
    _ => FontAwesomeIcons.tag,
  };
}

/// Bottom sheet pemilih kategori.
///
/// Menampilkan kategori yang dikelompokkan berdasarkan parent.
/// Mendukung pencarian real-time.
class TransactionCategoryPicker extends ConsumerStatefulWidget {
  const TransactionCategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.filterType,
  });

  final List<CategoryModel> categories;
  final String? selectedId;

  /// 'expense' | 'income' | null (semua)
  final String? filterType;

  /// Menampilkan bottom sheet dan mengembalikan kategori terpilih.
  static Future<CategoryModel?> show(
    BuildContext context, {
    required List<CategoryModel> categories,
    required String? selectedId,
    required String? filterType,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => TransactionCategoryPicker(
        categories: categories,
        selectedId: selectedId,
        filterType: filterType,
      ),
    );
  }

  @override
  ConsumerState<TransactionCategoryPicker> createState() =>
      _TransactionCategoryPickerState();
}

class _TransactionCategoryPickerState
    extends ConsumerState<TransactionCategoryPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filtered {
    final src = widget.categories.where((c) {
      if (widget.filterType != null && c.type != widget.filterType) {
        // Sertakan kategori system (type='system') untuk semua tipe transaksi
        if (c.type != 'system') return false;
      }
      return true;
    }).toList();

    if (_query.isEmpty) return src;
    final q = _query.toLowerCase();
    return src.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Mengelompokkan kategori: parent + children di bawahnya.
  List<CategoryModel> _grouped(List<CategoryModel> flat) {
    final parents = flat.where((c) => !c.isChild).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final result = <CategoryModel>[];
    for (final parent in parents) {
      result.add(parent);
      result.addAll(
        flat.where((c) => c.parentId == parent.id).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final grouped = _grouped(_filtered);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              decoration: BoxDecoration(
                color: appColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                l10n.transactionSelectCategory,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // Search
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyleConstants.b2.copyWith(
                  color: appColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.pickerSearchCategory,
                  hintStyle: TextStyleConstants.b2.copyWith(
                    color: appColors.textSecondary,
                  ),
                  prefixIcon: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 14.r,
                    color: appColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: appColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Divider(color: appColors.border, height: 1),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: grouped.length,
                itemBuilder: (_, i) {
                  final cat = grouped[i];
                  final isSelected = cat.id == widget.selectedId;
                  final catColor = _hexColor(cat.color);
                  final isChild = cat.isChild;

                  return InkWell(
                    onTap: () => Navigator.pop(context, cat),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isChild ? 36.w : 16.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isChild ? 32.r : 36.r,
                            height: isChild ? 32.r : 36.r,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: FaIcon(
                                _categoryIcon(cat.icon),
                                size: isChild ? 14.r : 16.r,
                                color: catColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: isChild
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: appColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            FaIcon(
                              FontAwesomeIcons.check,
                              size: 14.r,
                              color: appColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
