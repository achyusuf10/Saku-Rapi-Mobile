import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Halaman terpisah untuk anggaran yang sudah selesai (expired).
class CompletedBudgetsPage extends ConsumerStatefulWidget {
  const CompletedBudgetsPage({super.key});

  @override
  ConsumerState<CompletedBudgetsPage> createState() =>
      _CompletedBudgetsPageState();
}

class _CompletedBudgetsPageState extends ConsumerState<CompletedBudgetsPage> {
  List<BudgetModel> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    final controller = ref.read(budgetControllerProvider.notifier);
    final result = await controller.loadCompletedBudgets();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess()) {
          _budgets = result.dataSuccess()!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.budgetCompletedTitle,
          style: TextStyleConstants.h7.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Text(
                  l10n.budgetCompletedEmpty,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: _budgets.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (_, i) {
                final budget = _budgets[i];
                return BudgetCardTile(
                  budget: budget,
                  onTap: () =>
                      context.push(AppRouter.budgetDetail, extra: budget),
                );
              },
            ),
    );
  }
}
