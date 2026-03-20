import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budgeting/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:app_saku_rapi/features/budgeting/view/widgets/budget_period_selector_sheet.dart';
import 'package:app_saku_rapi/features/budgeting/view/widgets/budget_wallet_scope_tile.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parsing hex color string ke [Color], fallback ke abu-abu.
Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF6B7280);
}

/// Layar form untuk membuat atau mengedit budget.
///
/// Jika [budget] diberikan (via GoRouter extra), mode = **edit**.
/// Jika tidak, mode = **create**.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});

  /// Budget yang akan diedit. `null` = mode create.
  final BudgetModel? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;

  // State form
  String? _categoryId;
  String? _categoryName;
  String? _categoryIcon;
  String? _categoryColor;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _periodLabel;
  WalletModel? _selectedWallet;
  bool _isRecurring = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.budget != null
          ? widget.budget!.amount.toStringAsFixed(0)
          : '',
    );
    if (widget.budget != null) {
      final b = widget.budget!;
      _categoryId = b.categoryId;
      _categoryName = b.categoryName;
      _categoryIcon = b.categoryIcon;
      _categoryColor = b.categoryColor;
      _startDate = b.startDate;
      _endDate = b.endDate;
      _isRecurring = b.isRecurring;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(transactionCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.xmark, size: 18.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? l10n.budgetFormTitleEdit : l10n.budgetFormTitleAdd,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section 1: Detail Anggaran ──
                _SectionCard(
                  children: [
                    // Kategori
                    _FormLabel(text: l10n.budgetFormCategory),
                    SizedBox(height: 8.h),
                    categoriesAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => Text(
                        l10n.budgetFormCategoryError,
                        style: TextStyleConstants.b2.copyWith(
                          color: colors.error,
                        ),
                      ),
                      data: (categories) => _CategoryTile(
                        categoryName: _categoryName,
                        categoryIcon: _categoryIcon,
                        categoryColor: _categoryColor,
                        onTap: () async {
                          final cat = await TransactionCategoryPicker.show(
                            context,
                            categories: categories,
                            selectedId: _categoryId,
                            filterType: 'expense',
                          );
                          if (cat != null && mounted) {
                            setState(() {
                              _categoryId = cat.id;
                              _categoryName = cat.name;
                              _categoryIcon = cat.icon;
                              _categoryColor = cat.color;
                            });
                          }
                        },
                      ),
                    ),

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Nominal anggaran
                    _FormLabel(text: l10n.budgetFormAmount),
                    SizedBox(height: 8.h),
                    SakuTextField(
                      controller: _amountCtrl,
                      hintText: '0',
                      prefixText: AppConstants.currencySymbol,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.budgetFormAmountRequired;
                        }
                        final amount = double.tryParse(value) ?? 0;
                        if (amount <= 0) return l10n.budgetFormAmountInvalid;
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Periode
                    _FormLabel(text: l10n.budgetFormPeriod),
                    SizedBox(height: 8.h),
                    _PeriodTile(
                      startDate: _startDate,
                      endDate: _endDate,
                      label: _periodLabel,
                      onTap: () async {
                        final result = await BudgetPeriodSelectorSheet.show(
                          context,
                          initialStart: _startDate,
                          initialEnd: _endDate,
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _startDate = result.startDate;
                            _endDate = result.endDate;
                            _periodLabel = result.label;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Scope Wallet
                    _FormLabel(text: l10n.budgetFormWalletScope),
                    SizedBox(height: 8.h),
                    BudgetWalletScopeTile(
                      selectedWallet: _selectedWallet,
                      onChanged: (wallet) =>
                          setState(() => _selectedWallet = wallet),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ── Section 2: Ulangi Anggaran ──
                _SectionCard(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.budgetFormRecurringTitle,
                        style: TextStyleConstants.b2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        l10n.budgetFormRecurringSubtitle,
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      value: _isRecurring,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // ── Tombol Simpan ──
                SakuButton(
                  text: l10n.budgetSave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _onSave,
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Aksi simpan
  // ─────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;

    if (_categoryId == null) {
      context.showAppAlert(
        l10n.budgetFormCategoryRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      context.showAppAlert(
        l10n.budgetFormPeriodRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    final amount = double.parse(_amountCtrl.text.trim());
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final now = DateTime.now();
    final controller = ref.read(budgetControllerProvider.notifier);

    setState(() => _isSaving = true);
    context.showLoadingOverlay();

    try {
      if (_isEditMode) {
        final updated = widget.budget!.copyWith(
          categoryId: _categoryId,
          walletId: _selectedWallet?.id,
          clearWallet: _selectedWallet == null,
          amount: amount,
          startDate: _startDate,
          endDate: _endDate,
          isRecurring: _isRecurring,
          updatedAt: now,
        );
        final result = await controller.editBudget(updated);

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.budgetSuccessEdit);
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.budgetErrorEdit,
            alertType: AlertTypeEnum.error,
          );
        }
      } else {
        final newBudget = BudgetModel(
          id: '',
          userId: userId,
          categoryId: _categoryId!,
          walletId: _selectedWallet?.id,
          amount: amount,
          usedAmount: 0,
          startDate: _startDate!,
          endDate: _endDate!,
          isRecurring: _isRecurring,
          notificationSent80: false,
          notificationSent100: false,
          createdAt: now,
          updatedAt: now,
          categoryName: _categoryName,
          categoryIcon: _categoryIcon,
          categoryColor: _categoryColor,
        );
        final result = await controller.addBudget(newBudget);

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.budgetSuccessAdd);
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.budgetErrorAdd,
            alertType: AlertTypeEnum.error,
          );
        }
      }
    } finally {
      if (mounted) {
        context.closeOverlay();
        setState(() => _isSaving = false);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════

/// Kartu section dengan border.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Label judul field.
class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyleConstants.label1.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
      ),
    );
  }
}

/// Tile pemilih kategori.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.onTap,
  });

  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasCategory = categoryName != null;
    final catColor = _hexColor(categoryColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: hasCategory
              ? catColor.withValues(alpha: 0.08)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasCategory
                ? catColor.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.tag,
              size: 14.r,
              color: hasCategory ? catColor : colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                categoryName ?? l10n.budgetFormCategorySelect,
                style: TextStyleConstants.b2.copyWith(
                  color: hasCategory
                      ? colors.textPrimary
                      : colors.textSecondary,
                  fontWeight: hasCategory ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile pemilih periode.
class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.onTap,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasPeriod = startDate != null && endDate != null;

    String displayText = l10n.budgetFormPeriodSelect;
    if (hasPeriod) {
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      displayText = '${fmt(startDate!)} – ${fmt(endDate!)}';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: hasPeriod
              ? colors.primary.withValues(alpha: 0.05)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasPeriod
                ? colors.primary.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.calendarDays,
              size: 14.r,
              color: hasPeriod ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                displayText,
                style: TextStyleConstants.b2.copyWith(
                  color: hasPeriod ? colors.textPrimary : colors.textSecondary,
                  fontWeight: hasPeriod ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
