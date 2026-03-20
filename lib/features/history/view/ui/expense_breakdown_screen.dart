import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/expense_breakdown_controller.dart';
import 'package:app_saku_rapi/features/history/models/category_summary_model.dart';
import 'package:app_saku_rapi/features/history/view/widgets/breakdown_stats_widget.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Layar drill-down Expense Breakdown per kategori.
///
/// Konten:
/// 1. Header: Icon + Nama Kategori + Total Amount bulan ini
/// 2. Stats Card: vs Bulan Lalu + Rata-rata Harian
/// 3. Sub-kategori Section: child categories dengan progress bar
/// 4. Transaksi Section: semua transaksi di kategori ini
class ExpenseBreakdownScreen extends ConsumerStatefulWidget {
  const ExpenseBreakdownScreen({
    super.key,
    required this.category,
    required this.periodStart,
    required this.periodEnd,
  });

  final CategorySummaryModel category;
  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  ConsumerState<ExpenseBreakdownScreen> createState() =>
      _ExpenseBreakdownScreenState();
}

class _ExpenseBreakdownScreenState
    extends ConsumerState<ExpenseBreakdownScreen> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    // Trigger init once after first build
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        ref
            .read(expenseBreakdownControllerProvider.notifier)
            .init(
              BreakdownParams(
                category: widget.category,
                periodStart: widget.periodStart,
                periodEnd: widget.periodEnd,
              ),
            );
      });
    }

    final breakdownState = ref.watch(expenseBreakdownControllerProvider);

    final categoryColor = _hexColor(widget.category.categoryColor);

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.breakdownTitle,
          style: TextStyleConstants.h7.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.textPrimary,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Header: Icon + Name + Amount ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: FaIcon(
                        _categoryIcon(widget.category.categoryIcon),
                        color: categoryColor,
                        size: 20.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.categoryName,
                          style: TextStyleConstants.h7.copyWith(
                            fontWeight: FontWeight.w700,
                            color: appColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.category.amount.toCurrency(),
                          style: TextStyleConstants.h6.copyWith(
                            fontWeight: FontWeight.w800,
                            color: appColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Persentase Badge ──
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      widget.category.percentage.toPercentage(),
                      style: TextStyleConstants.label2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Card ──
          SliverToBoxAdapter(child: BreakdownStatsWidget()),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Sub-kategori Section ──
          if (widget.category.childSummaries.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  l10n.breakdownSubcategories,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w700,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final child = widget.category.childSummaries[index];
                return _SubcategoryRow(
                  summary: child,
                  parentColor: categoryColor,
                );
              }, childCount: widget.category.childSummaries.length),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],

          // ── Transaksi Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                l10n.breakdownTransactions,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 8.h)),

          // ── Transaction List ──
          if (breakdownState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: CircularProgressIndicator(color: appColors.primary),
                ),
              ),
            )
          else if (breakdownState.transactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Text(
                    l10n.breakdownNoData,
                    style: TextStyleConstants.caption.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tx = breakdownState.transactions[index];
                return _BreakdownTxTile(transaction: tx);
              }, childCount: breakdownState.transactions.length),
            ),

          // ── Bottom padding ──
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' || 'car' => FontAwesomeIcons.bus,
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
      _ => FontAwesomeIcons.tag,
    };
  }
}

/// Baris sub-kategori dengan progress bar.
class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.summary, required this.parentColor});

  final CategorySummaryModel summary;
  final Color parentColor;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final color = _hexColor(summary.categoryColor);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        children: [
          Row(
            children: [
              // ── Icon ──
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: FaIcon(
                    _categoryIcon(summary.categoryIcon),
                    color: color,
                    size: 12.r,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // ── Name ──
              Expanded(
                child: Text(
                  summary.categoryName,
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              // ── Percentage ──
              Text(
                summary.percentage.toPercentage(),
                style: TextStyleConstants.label3.copyWith(
                  color: appColors.textSecondary,
                ),
              ),
              SizedBox(width: 8.w),
              // ── Amount ──
              Text(
                summary.amount.toCurrency(),
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appColors.expense,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: summary.percentage.clamp(0.0, 1.0),
              minHeight: 4.h,
              backgroundColor: appColors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(parentColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' || 'car' => FontAwesomeIcons.bus,
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
      _ => FontAwesomeIcons.tag,
    };
  }
}

/// Tile transaksi di breakdown screen.
class _BreakdownTxTile extends StatelessWidget {
  const _BreakdownTxTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: appColors.expense.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.arrowUp,
                color: appColors.expense,
                size: 14.r,
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // ── Title + Date ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note ?? transaction.merchantName ?? '',
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  transaction.date.extToFormattedString(
                    outputDateFormat: 'dd MMM yyyy, HH:mm',
                  ),
                  style: TextStyleConstants.label3.copyWith(
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Amount ──
          Text(
            '-${transaction.totalAmount.toCurrency()}',
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
