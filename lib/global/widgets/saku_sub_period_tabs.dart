import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Horizontal scrollable tab bar untuk navigasi sub-period.
///
/// Reusable — tidak bergantung pada controller manapun. Digunakan di
/// history & report. Caller bertanggung jawab menyediakan [tabs],
/// [selectedIndex], dan [onTabSelected].
///
/// Tab terakhir selalu "saat ini" dan otomatis di-scroll ke sana saat
/// pertama kali tampil atau saat [selectedIndex]/[tabs] berubah.
class SakuSubPeriodTabs extends StatefulWidget {
  const SakuSubPeriodTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  /// Daftar tab sub-period yang akan ditampilkan.
  final List<SubPeriodTab> tabs;

  /// Index tab yang sedang aktif.
  final int selectedIndex;

  /// Callback saat pengguna mengetuk tab.
  final ValueChanged<int> onTabSelected;

  @override
  State<SakuSubPeriodTabs> createState() => _SakuSubPeriodTabsState();
}

class _SakuSubPeriodTabsState extends State<SakuSubPeriodTabs> {
  final _scrollController = ScrollController();
  final _itemKeys = <GlobalKey>[];

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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(widget.selectedIndex);
    });
  }

  @override
  void didUpdateWidget(SakuSubPeriodTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll saat selectedIndex berubah atau daftar tab berganti
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.tabs.length != widget.tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(widget.selectedIndex);
      });
    }
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
    final tabs = widget.tabs;
    if (tabs.isEmpty) return const SizedBox.shrink();

    _ensureKeys(tabs.length);

    final colors = context.colors;
    final selectedIndex = widget.selectedIndex;

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
                onTap: () => widget.onTabSelected(index),
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
