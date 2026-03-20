import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Hasil pilihan periode di [BudgetPeriodSelectorSheet].
class BudgetPeriodSelection {
  const BudgetPeriodSelection({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String label;
}

/// Enum internal untuk opsi preset periode.
enum _PeriodPreset { thisWeek, thisMonth, thisQuarter, thisYear, custom }

/// Bottom sheet pemilih periode budget.
///
/// Menyediakan 5 opsi:
/// 1. Minggu ini
/// 2. Bulan ini
/// 3. Kuartal ini
/// 4. Tahun ini
/// 5. Custom → DateRangePicker
class BudgetPeriodSelectorSheet extends StatefulWidget {
  const BudgetPeriodSelectorSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;

  /// Menampilkan bottom sheet dan mengembalikan [BudgetPeriodSelection].
  static Future<BudgetPeriodSelection?> show(
    BuildContext context, {
    DateTime? initialStart,
    DateTime? initialEnd,
  }) {
    return showModalBottomSheet<BudgetPeriodSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => BudgetPeriodSelectorSheet(
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }

  @override
  State<BudgetPeriodSelectorSheet> createState() =>
      _BudgetPeriodSelectorSheetState();
}

class _BudgetPeriodSelectorSheetState extends State<BudgetPeriodSelectorSheet> {
  _PeriodPreset _selected = _PeriodPreset.thisMonth;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _inferPreset();
  }

  /// Coba deteksi preset dari initial dates.
  void _inferPreset() {
    if (widget.initialStart == null || widget.initialEnd == null) return;
    final now = DateTime.now();
    final start = widget.initialStart!;
    final end = widget.initialEnd!;

    // Bulan ini
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    if (_isSameDay(start, monthStart) && _isSameDay(end, monthEnd)) {
      _selected = _PeriodPreset.thisMonth;
      return;
    }

    // Minggu ini (Senin–Minggu)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (_isSameDay(start, weekStart) && _isSameDay(end, weekEnd)) {
      _selected = _PeriodPreset.thisWeek;
      return;
    }

    // Kuartal ini
    final q = ((now.month - 1) ~/ 3) * 3 + 1;
    final qStart = DateTime(now.year, q, 1);
    final qEnd = DateTime(now.year, q + 3, 0);
    if (_isSameDay(start, qStart) && _isSameDay(end, qEnd)) {
      _selected = _PeriodPreset.thisQuarter;
      return;
    }

    // Tahun ini
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    if (_isSameDay(start, yearStart) && _isSameDay(end, yearEnd)) {
      _selected = _PeriodPreset.thisYear;
      return;
    }

    // Custom
    _selected = _PeriodPreset.custom;
    _customRange = DateTimeRange(start: start, end: end);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Text(
            l10n.budgetPeriodTitle,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Divider(color: colors.border, height: 1),

          // Opsi
          _RadioOption(
            title: l10n.budgetPeriodThisWeek,
            selected: _selected == _PeriodPreset.thisWeek,
            onTap: () => setState(() => _selected = _PeriodPreset.thisWeek),
          ),
          _RadioOption(
            title: l10n.budgetPeriodThisMonth,
            selected: _selected == _PeriodPreset.thisMonth,
            onTap: () => setState(() => _selected = _PeriodPreset.thisMonth),
          ),
          _RadioOption(
            title: l10n.budgetPeriodThisQuarter,
            selected: _selected == _PeriodPreset.thisQuarter,
            onTap: () => setState(() => _selected = _PeriodPreset.thisQuarter),
          ),
          _RadioOption(
            title: l10n.budgetPeriodThisYear,
            selected: _selected == _PeriodPreset.thisYear,
            onTap: () => setState(() => _selected = _PeriodPreset.thisYear),
          ),
          _RadioOption(
            title: _customRange != null
                ? '${l10n.budgetPeriodCustom} (${_formatRange(_customRange!)})'
                : l10n.budgetPeriodCustom,
            selected: _selected == _PeriodPreset.custom,
            onTap: () async {
              setState(() => _selected = _PeriodPreset.custom);
              await _pickCustomRange();
            },
          ),

          SizedBox(height: 12.h),
          Divider(color: colors.border, height: 1),
          SizedBox(height: 12.h),

          // Tombol batal / simpan
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      l10n.budgetCancel,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      l10n.budgetSave,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );
    if (picked != null && mounted) {
      setState(() => _customRange = picked);
    }
  }

  void _onSave() {
    final result = _buildSelection();
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  BudgetPeriodSelection? _buildSelection() {
    final now = DateTime.now();
    final l10n = context.l10n;

    return switch (_selected) {
      _PeriodPreset.thisWeek => () {
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return BudgetPeriodSelection(
          startDate: _dateOnly(start),
          endDate: _dateOnly(end),
          label: l10n.budgetPeriodThisWeek,
        );
      }(),
      _PeriodPreset.thisMonth => BudgetPeriodSelection(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        label: l10n.budgetPeriodThisMonth,
      ),
      _PeriodPreset.thisQuarter => () {
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return BudgetPeriodSelection(
          startDate: DateTime(now.year, q, 1),
          endDate: DateTime(now.year, q + 3, 0),
          label: l10n.budgetPeriodThisQuarter,
        );
      }(),
      _PeriodPreset.thisYear => BudgetPeriodSelection(
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        label: l10n.budgetPeriodThisYear,
      ),
      _PeriodPreset.custom =>
        _customRange == null
            ? null
            : BudgetPeriodSelection(
                startDate: _customRange!.start,
                endDate: _customRange!.end,
                label: l10n.budgetPeriodCustom,
              ),
    };
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatRange(DateTimeRange range) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }
}

/// Radio tile untuk satu opsi periode.
class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20.r,
              color: selected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
