import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tab-style horizontal period selector — dipakai di history & report.
///
/// - Animated pill yang bergerak ke tab yang diklik
/// - Auto-scroll ke tab yang sedang aktif
/// - Tab "Kustom" menampilkan date range yang dipilih saat aktif,
///   dan kembali ke label "Kustom" saat tab lain dipilih
/// - Overflow ditangani dengan horizontal scroll
class SakuPeriodSelector extends StatefulWidget {
  const SakuPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onCustomTap,
    this.customStart,
    this.customEnd,
  });

  final AppPeriod selected;
  final ValueChanged<AppPeriod> onSelected;

  /// Callback untuk tab "Kustom" — membuka date range picker.
  final VoidCallback? onCustomTap;

  /// Tanggal mulai custom range (untuk label dinamis).
  final DateTime? customStart;

  /// Tanggal selesai custom range (untuk label dinamis).
  final DateTime? customEnd;

  @override
  State<SakuPeriodSelector> createState() => _SakuPeriodSelectorState();
}

class _SakuPeriodSelectorState extends State<SakuPeriodSelector> {
  final _scrollController = ScrollController();

  /// Key per-tab untuk auto-scroll ke tab yang aktif.
  final _itemKeys = List.generate(AppPeriod.values.length, (_) => GlobalKey());

  @override
  void didUpdateWidget(SakuPeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    final index = AppPeriod.values.indexOf(widget.selected);
    if (index < 0) return;
    final ctx = _itemKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.5,
    );
  }

  /// Label untuk setiap tab.
  ///
  /// Tab custom menampilkan date range saat periode == custom dan
  /// range sudah dipilih, selain itu tampilkan label default.
  String _labelFor(AppPeriod period) {
    final l10n = context.l10n;
    if (period == AppPeriod.custom &&
        widget.selected == AppPeriod.custom &&
        widget.customStart != null &&
        widget.customEnd != null) {
      final start = widget.customStart!.extToFormattedString(
        outputDateFormat: 'd MMM',
      );
      final end = widget.customEnd!.extToFormattedString(
        outputDateFormat: 'd MMM',
      );
      return '$start – $end';
    }
    return switch (period) {
      AppPeriod.daily => l10n.historyDaily,
      AppPeriod.weekly => l10n.historyWeekly,
      AppPeriod.monthly => l10n.historyMonthly,
      AppPeriod.quarterly => l10n.historyQuarterly,
      AppPeriod.yearly => l10n.historyYearly,
      AppPeriod.custom => l10n.historyCustomRange,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: AppPeriod.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 6.w),
        itemBuilder: (context, index) {
          final period = AppPeriod.values[index];
          final isSelected = period == widget.selected;
          // Custom tab sudah punya range tapi bukan yang sedang aktif
          final isCustomSaved =
              period == AppPeriod.custom &&
              widget.customStart != null &&
              widget.customEnd != null &&
              !isSelected;

          return _SakuPeriodTab(
            key: _itemKeys[index],
            label: _labelFor(period),
            isSelected: isSelected,
            isCustomSaved: isCustomSaved,
            isCalendarIcon: period == AppPeriod.custom && !isSelected,
            onTap: () {
              if (period == AppPeriod.custom) {
                widget.onCustomTap?.call();
              } else {
                widget.onSelected(period);
              }
            },
          );
        },
      ),
    );
  }
}

/// Tab individual dengan animasi fill.
class _SakuPeriodTab extends StatelessWidget {
  const _SakuPeriodTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCustomSaved = false,
    this.isCalendarIcon = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Custom tab dengan range tersimpan tapi tidak aktif — semi-highlighted.
  final bool isCustomSaved;

  /// Tampilkan ikon kalender kecil sebelum label (custom tidak aktif).
  final bool isCalendarIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : isCustomSaved
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : isCustomSaved
                ? colors.primary.withValues(alpha: 0.45)
                : colors.border.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCalendarIcon) ...[
                FaIcon(
                  FontAwesomeIcons.calendarDays,
                  size: 10.w,
                  color: isCustomSaved ? colors.primary : colors.textSecondary,
                ),
                SizedBox(width: 4.w),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyleConstants.label2.copyWith(
                  color: isSelected
                      ? colors.onPrimary
                      : isCustomSaved
                      ? colors.primary
                      : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.sp,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
