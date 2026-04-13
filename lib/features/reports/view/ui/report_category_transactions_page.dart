import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/history/datasource/history_remote_data_source.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/reports/models/report_category_transactions_argument.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman daftar transaksi untuk kategori tertentu dari Report.
///
/// Menampilkan transaksi yang difilter berdasarkan:
/// - Kategori (categoryId)
/// - Periode (startDate–endDate)
/// - Tipe (expense/income)
/// - Dompet (walletId, opsional)
class ReportCategoryTransactionsPage extends StatefulWidget {
  const ReportCategoryTransactionsPage({super.key, required this.argument});

  final ReportCategoryTransactionsArgument argument;

  @override
  State<ReportCategoryTransactionsPage> createState() =>
      _ReportCategoryTransactionsPageState();
}

class _ReportCategoryTransactionsPageState
    extends State<ReportCategoryTransactionsPage> {
  final _dataSource = HistoryRemoteDataSource();

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _dataSource.getTransactionsByCategory(
      startDate: widget.argument.startDate,
      endDate: widget.argument.endDate,
      walletId: widget.argument.walletId,
      categoryId: widget.argument.categoryId,
      type: widget.argument.type,
      limit: 200,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess()) {
        _transactions = result.dataSuccess() ?? [];
      } else if (result.isError()) {
        final err = result.dataError();
        _errorMessage = err?.$1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final arg = widget.argument;
    final catColor = parseHexColor(arg.categoryColor);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: SakuCategoryIcon(
                  iconName: arg.categoryIcon,
                  color: catColor,
                  size: 13,
                  showBackground: false,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(arg.categoryName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, dynamic l10n) {
    if (_isLoading) {
      return const Center(child: SakuLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SakuErrorState(
          message: _errorMessage!,
          onRetry: _loadTransactions,
        ),
      );
    }

    if (_transactions.isEmpty) {
      return SakuEmptyState(
        icon: FontAwesomeIcons.rectangleList,
        title: l10n.historyNoTransactions,
        message: '',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: context.colors.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) => SizedBox(height: 4.h),
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return HistoryTransactionTile(
            transaction: tx,
            showDate: true,
            onTap: () => context.push(AppRouter.transactionDetail, extra: tx),
          );
        },
      ),
    );
  }
}
