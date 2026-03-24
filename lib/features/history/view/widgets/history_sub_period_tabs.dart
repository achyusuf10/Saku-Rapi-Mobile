import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Horizontal scrollable tab bar untuk navigasi sub-period.
///
/// Menampilkan tab per sub-period (misal setiap bulan untuk mode "Monthly")
/// hingga 2 tahun ke belakang. Tab terakhir selalu "saat ini" dan otomatis
/// di-scroll ke sana saat pertama kali tampil atau saat period berganti.
class HistorySubPeriodTabs extends ConsumerStatefulWidget {
  const HistorySubPeriodTabs({super.key});

  @override
  ConsumerState<HistorySubPeriodTabs> createState() =>
      _HistorySubPeriodTabsState();
}

class _HistorySubPeriodTabsState extends ConsumerState<HistorySubPeriodTabs> {
  final _scrollController = ScrollController();
  final _itemKeys = <GlobalKey>[];
  int? _lastIndex;
  HistoryPeriod? _lastPeriod;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureKeys(int count) {
    while (_itemKeys.length < count) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyState = ref.read(historyControllerProvider);
      final selectedIndex =
          historyState.subPeriodIndex ??
          (historyState.subPeriodTabs.length - 1);
      _scrollToIndex(selectedIndex);
    });
    super.initState();
  }

  void _scrollToIndex(int index) {
    if (index < 0 || index >= _itemKeys.length) return;
    final ctx = _itemKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final historyState = ref.watch(historyControllerProvider);
    final tabs = historyState.subPeriodTabs;
    if (tabs.isEmpty) return const SizedBox.shrink();

    _ensureKeys(tabs.length);

    final selectedIndex = historyState.subPeriodIndex ?? (tabs.length - 1);

    // Auto-scroll saat sub-period atau period berubah
    if (_lastIndex != selectedIndex || _lastPeriod != historyState.period) {
      _lastIndex = selectedIndex;
      _lastPeriod = historyState.period;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(selectedIndex);
      });
    }

    return SizedBox(
      height: 34.h,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            for (int index = 0; index < tabs.length; index++) ...[
              if (index > 0) SizedBox(width: 6.w),
              GestureDetector(
                key: _itemKeys[index],
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref
                      .read(historyControllerProvider.notifier)
                      .setSubPeriod(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? colors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: index == selectedIndex
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.border.withValues(alpha: 0.25),
                      width: index == selectedIndex ? 1.2 : 0.8,
                    ),
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyleConstants.label3.copyWith(
                        color: index == selectedIndex
                            ? colors.primary
                            : colors.textSecondary,
                        fontWeight: index == selectedIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 11.sp,
                      ),
                      child: Text(tabs[index].label, maxLines: 1),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
