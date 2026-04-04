import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated transaction type tab bar with sliding indicator.
///
/// Menampilkan tab expense, income, transfer, debt, dan loan.
/// Menggunakan Flutter [TabBar] untuk animasi slide yang smooth.
/// Scrollable untuk mencegah overflow dengan banyak tipe.
class TransactionTypeTabs extends StatefulWidget {
  const TransactionTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TransactionTypeEnum selected;
  final ValueChanged<TransactionTypeEnum> onChanged;

  @override
  State<TransactionTypeTabs> createState() => _TransactionTypeTabsState();
}

class _TransactionTypeTabsState extends State<TransactionTypeTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _types = [
    TransactionTypeEnum.expense,
    TransactionTypeEnum.income,
    TransactionTypeEnum.transfer,
    TransactionTypeEnum.debt, // represents combined "Hutang/Piutang" tab
  ];

  @override
  void initState() {
    super.initState();
    final initialIdx = _resolveTabIndex(widget.selected);
    _tabController = TabController(
      length: _types.length,
      vsync: this,
      initialIndex: initialIdx,
    );
  }

  /// Map TransactionTypeEnum to tab index. Loan maps to debt tab.
  int _resolveTabIndex(TransactionTypeEnum type) {
    if (type == TransactionTypeEnum.loan) {
      return _types.indexOf(TransactionTypeEnum.debt);
    }
    final idx = _types.indexOf(type);
    return idx >= 0 ? idx : 0;
  }

  @override
  void didUpdateWidget(covariant TransactionTypeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      final idx = _resolveTabIndex(widget.selected);
      if (_tabController.index != idx) {
        _tabController.animateTo(idx);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = _colorForType(widget.selected, colors);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => widget.onChanged(_types[index]),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: typeColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: TextStyleConstants.label1.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyleConstants.label1.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: _types.map((type) {
          return Tab(
            height: 34.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(_labelForType(type, context)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelForType(TransactionTypeEnum type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      TransactionTypeEnum.expense => l10n.transactionExpense,
      TransactionTypeEnum.income => l10n.transactionIncome,
      TransactionTypeEnum.transfer => l10n.transactionTransfer,
      TransactionTypeEnum.debt => l10n.debtLoanFormTabLabel,
      TransactionTypeEnum.loan => l10n.transactionLoan,
      TransactionTypeEnum.adjustment => l10n.transactionAdjustment,
      TransactionTypeEnum.transferToAsset => l10n.transactionTransfer,
    };
  }

  Color _colorForType(TransactionTypeEnum type, AppColorScheme colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}
