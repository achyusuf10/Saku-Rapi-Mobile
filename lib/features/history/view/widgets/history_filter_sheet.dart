import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet filter untuk history.
///
/// Filter:
/// - Wallet (pilih dompet atau semua)
/// - Type (semua / income / expense / transfer / debt / loan)
/// - Grouping mode (by date / by category)
class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({
    super.key,
    required this.currentWalletId,
    required this.currentType,
    required this.currentGroupMode,
  });

  final String? currentWalletId;
  final TransactionTypeEnum? currentType;
  final HistoryGroupMode currentGroupMode;

  @override
  ConsumerState<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  late String? _walletId;
  late TransactionTypeEnum? _typeFilter;
  late HistoryGroupMode _groupMode;

  @override
  void initState() {
    super.initState();
    _walletId = widget.currentWalletId;
    _typeFilter = widget.currentType;
    _groupMode = widget.currentGroupMode;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Handle ───
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ─── Title ───
          Text(
            l10n.historyFilter,
            style: TextStyleConstants.h7.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.h),

          // ─── Wallet Filter ───
          Text(
            l10n.historySelectWallet,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          _WalletChips(
            wallets: wallets,
            selectedId: _walletId,
            allLabel: l10n.historyAllWallets,
            onSelected: (id) => setState(() => _walletId = id),
          ),
          SizedBox(height: 20.h),

          // ─── Type Filter ───
          Text(
            l10n.historySelectType,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          _TypeChips(
            selected: _typeFilter,
            onSelected: (type) => setState(() => _typeFilter = type),
          ),
          SizedBox(height: 20.h),

          // ─── Grouping Mode ───
          Text(
            l10n.historyFilter,
            style: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _GroupChip(
                label: l10n.historyGroupByDate,
                icon: FontAwesomeIcons.calendarDay,
                isSelected: _groupMode == HistoryGroupMode.byDate,
                onTap: () =>
                    setState(() => _groupMode = HistoryGroupMode.byDate),
              ),
              SizedBox(width: 8.w),
              _GroupChip(
                label: l10n.historyGroupByCategory,
                icon: FontAwesomeIcons.layerGroup,
                isSelected: _groupMode == HistoryGroupMode.byCategory,
                onTap: () =>
                    setState(() => _groupMode = HistoryGroupMode.byCategory),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // ─── Apply / Reset ───
          Row(
            children: [
              Expanded(
                child: SakuButton(
                  text: l10n.historyResetFilter,
                  isOutlined: true,
                  onPressed: () {
                    Navigator.pop(context, const _FilterResult.reset());
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SakuButton(
                  text: l10n.historyApplyFilter,
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _FilterResult(
                        walletId: _walletId,
                        typeFilter: _typeFilter,
                        groupMode: _groupMode,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

/// Result model dari filter sheet.
class _FilterResult {
  const _FilterResult({
    this.walletId,
    this.typeFilter,
    this.groupMode = HistoryGroupMode.byDate,
  }) : isReset = false;

  const _FilterResult.reset()
    : walletId = null,
      typeFilter = null,
      groupMode = HistoryGroupMode.byDate,
      isReset = true;

  final String? walletId;
  final TransactionTypeEnum? typeFilter;
  final HistoryGroupMode groupMode;
  final bool isReset;
}

/// Horizontal wrap of wallet filter chips.
class _WalletChips extends StatelessWidget {
  const _WalletChips({
    required this.wallets,
    required this.selectedId,
    required this.allLabel,
    required this.onSelected,
  });

  final List<WalletModel> wallets;
  final String? selectedId;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        // "Semua Dompet" chip
        _FilterChip(
          label: allLabel,
          isSelected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        ...wallets.map(
          (w) => _FilterChip(
            label: w.name,
            isSelected: selectedId == w.id,
            leadingColor: _parseColor(w.color, colors.primary),
            onTap: () => onSelected(w.id),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

/// Type filter chips.
class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onSelected});

  final TransactionTypeEnum? selected;
  final ValueChanged<TransactionTypeEnum?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final types = <TransactionTypeEnum?, String>{
      null: l10n.historyAllTypes,
      TransactionTypeEnum.expense: l10n.transactionExpense,
      TransactionTypeEnum.income: l10n.transactionIncome,
      TransactionTypeEnum.transfer: l10n.transactionTransfer,
      TransactionTypeEnum.debt: l10n.transactionDebt,
      TransactionTypeEnum.loan: l10n.transactionLoan,
    };

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: types.entries
          .map(
            (e) => _FilterChip(
              label: e.value,
              isSelected: selected == e.key,
              onTap: () => onSelected(e.key),
            ),
          )
          .toList(),
    );
  }
}

/// Generic filter chip.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingColor != null) ...[
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leadingColor,
                ),
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyleConstants.label2.copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouping mode chip.
class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 12.w,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyleConstants.label2.copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilkan filter sheet dan apply hasilnya ke controller.
Future<void> showHistoryFilterSheet(BuildContext context, WidgetRef ref) async {
  final historyState = ref.read(historyControllerProvider);
  final controller = ref.read(historyControllerProvider.notifier);

  final result = await showModalBottomSheet<_FilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HistoryFilterSheet(
      currentWalletId: historyState.walletId,
      currentType: historyState.typeFilter,
      currentGroupMode: historyState.groupMode,
    ),
  );

  if (result == null) return;

  if (result.isReset) {
    await controller.resetFilters();
    return;
  }

  // Apply type & grouping locally (no refetch)
  controller.setTypeFilter(result.typeFilter);
  controller.setGroupMode(result.groupMode);

  // Wallet filter triggers refetch
  await controller.setWalletFilter(result.walletId);
}
