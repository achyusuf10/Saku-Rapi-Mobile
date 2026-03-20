import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/extensions/string_ext.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_color_picker_sheet.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_icon_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layar form untuk menambah / mengedit kategori.
///
/// **Mode Create:** Terima `extra` berupa `Map<String, dynamic>` dengan key
/// `type` (string 'expense' / 'income').
///
/// **Mode Edit:** Terima `extra` berupa [CategoryModel] yang akan di-edit.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category, this.initialType});

  /// Kategori yang sedang di-edit (null jika mode create).
  final CategoryModel? category;

  /// Tipe awal saat mode create.
  final String? initialType;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  late String _selectedIcon;
  late String _selectedColor;
  late String _selectedType;
  String? _selectedParentId;
  bool _isLoading = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _selectedIcon = cat?.icon ?? 'tag';
    _selectedColor = cat?.color ?? '#6B7280';
    _selectedType = cat?.type ?? widget.initialType ?? 'expense';
    _selectedParentId = cat?.parentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Pickers
  // ─────────────────────────────────────────────────────

  Future<void> _pickIcon() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryIconPickerSheet(selectedIcon: _selectedIcon),
    );
    if (result != null) {
      setState(() => _selectedIcon = result);
    }
  }

  Future<void> _pickColor() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryColorPickerSheet(selectedColor: _selectedColor),
    );
    if (result != null) {
      setState(() => _selectedColor = result);
    }
  }

  // ─────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    context.showLoadingOverlay();

    final controller = ref.read(categoryControllerProvider.notifier);
    final l10n = context.l10n;

    try {
      if (_isEdit) {
        final updated = widget.category!.copyWith(
          name: _nameCtrl.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          type: _selectedType,
          parentId: _selectedParentId,
        );
        final result = await controller.editCategory(updated);

        if (!mounted) return;
        context.closeOverlay();

        result.map(
          success: (_) {
            context.showAppAlert(
              l10n.categorySuccessEdit(updated.name),
            
            );
            Navigator.of(context).pop(true);
          },
          error: (err) {
            context.showAppAlert(
              err.message.extEmptyNullReplacement(
                replacement: l10n.categoryErrorSave,
              ),
               alertType: AlertTypeEnum.error,
            );
          },
        );
      } else {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final newCat = CategoryModel(
          id: '',
          userId: userId,
          name: _nameCtrl.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          type: _selectedType,
          parentId: _selectedParentId,
          isDefault: false,
          isHidden: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
        );
        final result = await controller.addCategory(newCat);

        if (!mounted) return;
        context.closeOverlay();

        result.map(
          success: (data) {
            context.showAppAlert(
              l10n.categorySuccessAdd(data.data.name),
             
            );
            Navigator.of(context).pop(true);
          },
          error: (err) {
            context.showAppAlert(
              err.message.extEmptyNullReplacement(
                replacement: l10n.categoryErrorSave,
              ),
               alertType: AlertTypeEnum.error,
            );
          },
        );
      }
    } catch (_) {
      if (!mounted) return;
      context.closeOverlay();
      context.showAppAlert(l10n.categoryErrorSave,  alertType: AlertTypeEnum.error,);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final catColor = _hexToColor(_selectedColor);

    // Parent categories for the selected type (flat list, exclude self in edit)
    final categoryState = ref.watch(categoryControllerProvider).value;
    final parentCategories = <CategoryModel>[];
    if (categoryState != null) {
      final tree = _selectedType == 'income'
          ? categoryState.incomeCategories
          : categoryState.expenseCategories;
      for (final cat in tree) {
        if (_isEdit && cat.id == widget.category!.id) continue;
        parentCategories.add(cat);
      }
    }

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? l10n.categoryEdit : l10n.categoryAdd),
        centerTitle: true,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.xmark,
            size: 18.r,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Preview icon + color ──
              Center(
                child: GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: FaIcon(
                        _categoryIcon(_selectedIcon),
                        color: catColor,
                        size: 28.r,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // ── Category Name ──
              SakuTextField(
                controller: _nameCtrl,
                hintText: l10n.categoryName,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: FaIcon(
                    FontAwesomeIcons.pen,
                    size: 16.r,
                    color: appColors.textSecondary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.categoryNameRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // ── Type selector ──
              Text(
                'Tipe',
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: l10n.categoryExpense,
                      isSelected: _selectedType == 'expense',
                      color: appColors.expense,
                      onTap: _isEdit
                          ? null
                          : () => setState(() {
                              _selectedType = 'expense';
                              _selectedParentId = null;
                            }),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _TypeChip(
                      label: l10n.categoryIncome,
                      isSelected: _selectedType == 'income',
                      color: appColors.income,
                      onTap: _isEdit
                          ? null
                          : () => setState(() {
                              _selectedType = 'income';
                              _selectedParentId = null;
                            }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // ── Icon Picker Button ──
              _PickerRow(
                label: l10n.categoryIconPicker,
                icon: FontAwesomeIcons.icons,
                trailing: FaIcon(
                  _categoryIcon(_selectedIcon),
                  color: catColor,
                  size: 18.r,
                ),
                onTap: _pickIcon,
              ),
              SizedBox(height: 12.h),

              // ── Color Picker Button ──
              _PickerRow(
                label: l10n.categoryColorPicker,
                icon: FontAwesomeIcons.palette,
                trailing: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.border),
                  ),
                ),
                onTap: _pickColor,
              ),
              SizedBox(height: 12.h),

              // ── Parent Picker ──
              _ParentDropdown(
                parentCategories: parentCategories,
                selectedParentId: _selectedParentId,
                noParentLabel: l10n.categoryNoParent,
                label: l10n.categoryParent,
                onChanged: (value) {
                  setState(() => _selectedParentId = value);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: SakuButton(
            text: l10n.categorySave,
            onPressed: _onSave,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' => FontAwesomeIcons.bus,
      'car' => FontAwesomeIcons.car,
      'house' => FontAwesomeIcons.house,
      'bolt' => FontAwesomeIcons.bolt,
      'gamepad' => FontAwesomeIcons.gamepad,
      'heart-pulse' => FontAwesomeIcons.heartPulse,
      'graduation-cap' => FontAwesomeIcons.graduationCap,
      'shirt' => FontAwesomeIcons.shirt,
      'gift' => FontAwesomeIcons.gift,
      'plane' => FontAwesomeIcons.plane,
      'phone' => FontAwesomeIcons.phone,
      'money-bill-wave' => FontAwesomeIcons.moneyBillWave,
      'building-columns' => FontAwesomeIcons.buildingColumns,
      'briefcase' => FontAwesomeIcons.briefcase,
      'mug-hot' => FontAwesomeIcons.mugHot,
      'gas-pump' => FontAwesomeIcons.gasPump,
      'wifi' => FontAwesomeIcons.wifi,
      'baby' => FontAwesomeIcons.baby,
      'paw' => FontAwesomeIcons.paw,
      'dumbbell' => FontAwesomeIcons.dumbbell,
      'wallet' => FontAwesomeIcons.wallet,
      'piggy-bank' => FontAwesomeIcons.piggyBank,
      'hand-holding-dollar' => FontAwesomeIcons.handHoldingDollar,
      'sack-dollar' => FontAwesomeIcons.sackDollar,
      'coins' => FontAwesomeIcons.coins,
      'credit-card' => FontAwesomeIcons.creditCard,
      'chart-line' => FontAwesomeIcons.chartLine,
      'landmark' => FontAwesomeIcons.landmark,
      'stethoscope' => FontAwesomeIcons.stethoscope,
      'tooth' => FontAwesomeIcons.tooth,
      'pills' => FontAwesomeIcons.pills,
      'music' => FontAwesomeIcons.music,
      'film' => FontAwesomeIcons.film,
      'book' => FontAwesomeIcons.book,
      'scissors' => FontAwesomeIcons.scissors,
      'spray-can' => FontAwesomeIcons.sprayCan,
      'broom' => FontAwesomeIcons.broom,
      'wrench' => FontAwesomeIcons.wrench,
      'screwdriver-wrench' => FontAwesomeIcons.screwdriverWrench,
      'laptop' => FontAwesomeIcons.laptop,
      'mobile-screen' => FontAwesomeIcons.mobileScreen,
      'tv' => FontAwesomeIcons.tv,
      'camera' => FontAwesomeIcons.camera,
      'umbrella' => FontAwesomeIcons.umbrella,
      'shield-halved' => FontAwesomeIcons.shieldHalved,
      'cross' => FontAwesomeIcons.cross,
      'church' => FontAwesomeIcons.church,
      _ => FontAwesomeIcons.tag,
    };
  }
}

// ─────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : appColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : appColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? color : appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.icon,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: appColors.border),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 16.r, color: appColors.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyleConstants.b2.copyWith(
                  color: appColors.textPrimary,
                ),
              ),
            ),
            trailing,
            SizedBox(width: 8.w),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentDropdown extends StatelessWidget {
  const _ParentDropdown({
    required this.parentCategories,
    required this.selectedParentId,
    required this.noParentLabel,
    required this.label,
    required this.onChanged,
  });

  final List<CategoryModel> parentCategories;
  final String? selectedParentId;
  final String noParentLabel;
  final String label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
            color: appColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: appColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: appColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedParentId,
              isExpanded: true,
              icon: FaIcon(
                FontAwesomeIcons.chevronDown,
                size: 12.r,
                color: appColors.textSecondary,
              ),
              dropdownColor: appColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              style: TextStyleConstants.b2.copyWith(
                color: appColors.textPrimary,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    noParentLabel,
                    style: TextStyleConstants.b2.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
                ...parentCategories.map(
                  (cat) => DropdownMenuItem<String?>(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
