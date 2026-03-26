import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Form full-screen untuk membuat / mengedit budget.
///
/// Menampilkan field: kategori (expense only), jumlah, periode, wallet scope,
/// dan toggle recurring. Mengikuti desain screenshot referensi.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.existingBudget});

  /// Budget yang akan diedit. Null = mode tambah baru.
  final BudgetModel? existingBudget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  bool get _isEdit => widget.existingBudget != null;

  // Form state
  CategoryModel? _selectedCategory;
  WalletModel? _selectedWallet;
  bool _isGlobal = true;
  double _amount = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isRecurring = false;
  String _selectedPeriodKey = 'this_month';

  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPeriod();
    _prefillIfEdit();
  }

  void _initPeriod() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _prefillIfEdit() {
    final b = widget.existingBudget;
    if (b == null) return;

    _selectedCategory = b.category;
    _selectedWallet = b.wallet;
    _isGlobal = b.walletId == null;
    _amount = b.amount;
    _startDate = b.startDate;
    _endDate = b.endDate;
    _isRecurring = b.isRecurring;

    if (_amount > 0) {
      _amountController.text = _amount.toInt().toString();
      // Re-format with ThousandInputFormatter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final text = _amountController.text;
        final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          final number = int.tryParse(digits) ?? 0;
          final formatted = _formatNumber(number);
          _amountController.text = formatted;
          _amountController.selection = TextSelection.collapsed(
            offset: formatted.length,
          );
        }
      });
    }

    _selectedPeriodKey = _detectPeriodKey();
  }

  String _detectPeriodKey() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    if (_startDate == monthStart && _endDate == monthEnd) return 'this_month';
    return 'custom';
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? l10n.budgetFormTitleEdit : l10n.budgetFormTitleAdd,
          style: TextStyleConstants.h7.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        children: [
          SizedBox(height: 8.h),

          // ─── Category Picker ───
          _SectionTile(
            icon: _selectedCategory != null
                ? CategoryIconMapper.getIcon(_selectedCategory!.icon)
                : FontAwesomeIcons.circleQuestion,
            iconColor: _selectedCategory != null
                ? _parseColor(_selectedCategory!.color)
                : colors.textSecondary,
            title: _selectedCategory?.name ?? l10n.budgetFormCategorySelect,
            titleColor: _selectedCategory != null
                ? colors.textPrimary
                : colors.textSecondary,
            onTap: () => _pickCategory(context),
          ),

          // ─── Amount ───
          SizedBox(height: 4.h),
          SakuCurrencyField(
            controller: _amountController,
            label: l10n.budgetFormAmount,
            hint: '0',
            onChanged: (v) => setState(() => _amount = v),
          ),

          SizedBox(height: 16.h),

          // ─── Period Picker ───
          _SectionTile(
            icon: FontAwesomeIcons.calendarDays,
            iconColor: colors.primary,
            title:
                '${l10n.budgetPeriodThisMonth} (${_startDate.extToFormattedString(outputDateFormat: 'dd/MM')} – ${_endDate.extToFormattedString(outputDateFormat: 'dd/MM')})',
            onTap: () => _showPeriodPicker(context),
          ),

          SizedBox(height: 4.h),

          // ─── Wallet Scope ───
          _SectionTile(
            icon: FontAwesomeIcons.wallet,
            iconColor: _isGlobal
                ? colors.primary
                : _parseColor(_selectedWallet?.color),
            title: _isGlobal
                ? l10n.budgetAllWallets
                : (_selectedWallet?.name ?? l10n.budgetSpecificWallet),
            onTap: () => _showWalletScopePicker(context, wallets),
          ),

          SizedBox(height: 16.h),
          Divider(color: colors.border.withValues(alpha: 0.3)),
          SizedBox(height: 8.h),

          // ─── Recurring toggle ───
          _RecurringToggle(
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: SakuButton(
            text: l10n.budgetSave,
            onPressed: _canSave ? () => _onSave(context) : null,
            isEnabled: _canSave,
          ),
        ),
      ),
    );
  }

  bool get _canSave => _selectedCategory != null && _amount > 0;

  void _onSave(BuildContext context) {
    final periodType = switch (_selectedPeriodKey) {
      'this_week' => BudgetPeriodType.weekly,
      'this_month' => BudgetPeriodType.monthly,
      'this_quarter' => BudgetPeriodType.quarterly,
      'this_year' => BudgetPeriodType.yearly,
      _ => BudgetPeriodType.custom,
    };

    Navigator.of(context).pop(<String, dynamic>{
      'categoryId': _selectedCategory!.id,
      'categoryName': _selectedCategory!.name,
      'walletId': _isGlobal ? null : _selectedWallet?.id,
      'walletName': _isGlobal ? null : _selectedWallet?.name,
      'amount': _amount,
      'startDate': _startDate,
      'endDate': _endDate,
      'isRecurring': _isRecurring,
      'periodType': periodType,
    });
  }

  // ───────────────── Category Picker ─────────────────

  Future<void> _pickCategory(BuildContext context) async {
    final result = await CategoryPickerSheet.show(
      context: context,
      type: CategoryType.expense,
      selectedId: _selectedCategory?.id,
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  // ───────────────── Period Picker ─────────────────

  void _showPeriodPicker(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final now = DateTime.now();

    final periods = [
      _PeriodOption(
        key: 'this_week',
        label: l10n.budgetPeriodThisWeek,
        start: now.subtract(Duration(days: now.weekday - 1)),
        end: now.add(Duration(days: 7 - now.weekday)),
      ),
      _PeriodOption(
        key: 'this_month',
        label: l10n.budgetPeriodThisMonth,
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      _PeriodOption(
        key: 'this_quarter',
        label: l10n.budgetPeriodThisQuarter,
        start: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1),
        end: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0),
      ),
      _PeriodOption(
        key: 'this_year',
        label: l10n.budgetPeriodThisYear,
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31),
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  l10n.budgetPeriodTitle,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                ...periods.map(
                  (p) => ListTile(
                    title: Text(
                      p.label,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: _selectedPeriodKey == p.key
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: _selectedPeriodKey == p.key
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${p.start.extToFormattedString(outputDateFormat: 'dd MMM')} – ${p.end.extToFormattedString(outputDateFormat: 'dd MMM yyyy')}',
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: _selectedPeriodKey == p.key
                        ? FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 18.w,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPeriodKey = p.key;
                        _startDate = p.start;
                        _endDate = p.end;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                // Custom range
                ListTile(
                  title: Text(
                    l10n.budgetPeriodCustom,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: _selectedPeriodKey == 'custom'
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: _selectedPeriodKey == 'custom'
                          ? colors.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: DateTimeRange(
                        start: _startDate,
                        end: _endDate,
                      ),
                    );
                    if (range != null) {
                      setState(() {
                        _selectedPeriodKey = 'custom';
                        _startDate = range.start;
                        _endDate = range.end;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────── Wallet Scope Picker ─────────────────

  void _showWalletScopePicker(BuildContext context, List<WalletModel> wallets) {
    final colors = context.colors;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  l10n.budgetFormWalletScope,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),

                // Global (semua wallet)
                ListTile(
                  leading: FaIcon(
                    FontAwesomeIcons.globe,
                    size: 18.w,
                    color: colors.primary,
                  ),
                  title: Text(
                    l10n.budgetAllWallets,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: _isGlobal
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: _isGlobal ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  trailing: _isGlobal
                      ? FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 18.w,
                          color: colors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _isGlobal = true;
                      _selectedWallet = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                Divider(color: colors.border.withValues(alpha: 0.2)),

                // Per-wallet
                ...wallets.map(
                  (w) => ListTile(
                    leading: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: _parseColor(w.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: FaIcon(
                          CategoryIconMapper.getIcon(w.icon),
                          size: 14.w,
                          color: _parseColor(w.color),
                        ),
                      ),
                    ),
                    title: Text(
                      w.name,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: !_isGlobal && _selectedWallet?.id == w.id
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: !_isGlobal && _selectedWallet?.id == w.id
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                    trailing: !_isGlobal && _selectedWallet?.id == w.id
                        ? FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 18.w,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _isGlobal = false;
                        _selectedWallet = w;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF6B7280);
  }
}

// ───────────────── Section Tile ─────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: (iconColor ?? colors.textSecondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 16.w,
            color: iconColor ?? colors.textSecondary,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyleConstants.b1.copyWith(
          color: titleColor ?? colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 14.w,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

// ───────────────── Recurring Toggle ─────────────────

class _RecurringToggle extends StatelessWidget {
  const _RecurringToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: SizedBox(
        width: 28.w,
        height: 28.w,
        child: Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
      title: Text(
        l10n.budgetFormRecurringTitle,
        style: TextStyleConstants.b2.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        l10n.budgetFormRecurringSubtitle,
        style: TextStyleConstants.label2.copyWith(color: colors.textSecondary),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

// ───────────────── Period Option ─────────────────

class _PeriodOption {
  const _PeriodOption({
    required this.key,
    required this.label,
    required this.start,
    required this.end,
  });

  final String key;
  final String label;
  final DateTime start;
  final DateTime end;
}
