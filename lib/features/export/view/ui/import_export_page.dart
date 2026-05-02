import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/export/controllers/export_controller.dart';
import 'package:app_saku_rapi/features/export/utils/export_period_ranges.dart';
import 'package:app_saku_rapi/features/export/view/widgets/export_progress_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Hub Import / Export dari Settings.
class ImportExportPage extends ConsumerStatefulWidget {
  const ImportExportPage({super.key});

  @override
  ConsumerState<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends ConsumerState<ImportExportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.exportImportTitle),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyleConstants.label1,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: l10n.exportTabImport),
            Tab(text: l10n.exportTabExport),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ImportComingTab(l10n: l10n, colors: colors),
          _ExportTabContent(
            l10n: l10n,
            colors: colors,
            onRunExport: _runExportFlow,
          ),
        ],
      ),
    );
  }

  Future<void> _runExportFlow() async {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final result = await showDialog<ExportUiState>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ExportProgressDialog(localeName: localeName),
    );

    if (!mounted || result == null) return;

    if (result.isPartialResult) {
      context.showAppAlert(l10n.exportPartialWarning);
    }

    if (!mounted) return;

    await SakuDialog.show(
      context,
      barrierDismissible: true,
      title: l10n.exportSuccessTitle,
      icon: Icons.check_circle_rounded,
      positiveColor: context.colors.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.exportSavedPath(result.savedFilePath ?? ''),
            style: TextStyleConstants.b2.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          SakuButton(
            text: l10n.exportOpenFile,
            onPressed: () async {
              final p = result.savedFilePath;
              if (p != null) await OpenFilex.open(p);
            },
          ),
          SizedBox(height: 8.h),
          SakuButton(
            text: l10n.exportShareFile,
            isOutlined: true,
            onPressed: () async {
              final p = result.savedFilePath;
              if (p != null) {
                await SharePlus.instance.share(ShareParams(files: [XFile(p)]));
              }
            },
          ),
        ],
      ),
      labelNegative: l10n.exportClose,
      onTapNegative: () => Navigator.pop(context),
    );

    ref.read(exportControllerProvider.notifier).resetAfterDialog();
  }
}

class _ImportComingTab extends StatelessWidget {
  const _ImportComingTab({required this.l10n, required this.colors});

  final AppLocalizations l10n;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.clock,
              size: 48.w,
              color: colors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.exportImportComingTitle,
              style: TextStyleConstants.h6.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.exportImportComingBody,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportTabContent extends ConsumerWidget {
  const _ExportTabContent({
    required this.l10n,
    required this.colors,
    required this.onRunExport,
  });

  final AppLocalizations l10n;
  final AppColorScheme colors;
  final Future<void> Function() onRunExport;

  static String _rangeLabel(DateTimeRange range) {
    return '${range.start.extToFormattedString(outputDateFormat: 'dd MMM yyyy')} – ${range.end.extToFormattedString(outputDateFormat: 'dd MMM yyyy')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportControllerProvider);
    final range = exportState.effectivePeriod;
    final preset = exportState.periodPreset;

    Future<void> pickCustomRange() async {
      final def =
          exportState.customPeriod ??
          range ??
          DateTimeRange(start: DateTime.now(), end: DateTime.now());
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: def,
        helpText: l10n.historySelectDateRange,
      );
      if (picked != null && context.mounted) {
        ref.read(exportControllerProvider.notifier).setCustomPeriod(picked);
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        SakuCard(
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exportFormatLabel,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => ref
                    .read(exportControllerProvider.notifier)
                    .setFileFormat(ExportFileFormat.excel),
                title: Text(
                  l10n.exportFormatExcel,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  exportState.fileFormat == ExportFileFormat.excel
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: exportState.fileFormat == ExportFileFormat.excel
                      ? colors.primary
                      : colors.textSecondary,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => ref
                    .read(exportControllerProvider.notifier)
                    .setFileFormat(ExportFileFormat.pdf),
                title: Text(
                  l10n.exportFormatPdf,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  exportState.fileFormat == ExportFileFormat.pdf
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: exportState.fileFormat == ExportFileFormat.pdf
                      ? colors.primary
                      : colors.textSecondary,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${l10n.exportFormatCsv} (${l10n.exportSoonShort})',
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                trailing: Icon(Icons.lock_outline, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SakuCard(
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exportPeriodLabel,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _PeriodChip(
                    label: l10n.exportPeriodThisMonth,
                    selected: preset == ExportPeriodPreset.thisMonth,
                    colors: colors,
                    onTap: () => ref
                        .read(exportControllerProvider.notifier)
                        .setPeriodPreset(ExportPeriodPreset.thisMonth),
                  ),
                  _PeriodChip(
                    label: l10n.exportPeriodLastMonth,
                    selected: preset == ExportPeriodPreset.lastMonth,
                    colors: colors,
                    onTap: () => ref
                        .read(exportControllerProvider.notifier)
                        .setPeriodPreset(ExportPeriodPreset.lastMonth),
                  ),
                  _PeriodChip(
                    label: l10n.exportPeriodThisQuarter,
                    selected: preset == ExportPeriodPreset.thisQuarter,
                    colors: colors,
                    onTap: () => ref
                        .read(exportControllerProvider.notifier)
                        .setPeriodPreset(ExportPeriodPreset.thisQuarter),
                  ),
                  _PeriodChip(
                    label: l10n.exportPeriodThisYear,
                    selected: preset == ExportPeriodPreset.thisYear,
                    colors: colors,
                    onTap: () => ref
                        .read(exportControllerProvider.notifier)
                        .setPeriodPreset(ExportPeriodPreset.thisYear),
                  ),
                  _PeriodChip(
                    label: l10n.exportPeriodCustom,
                    selected: preset == ExportPeriodPreset.custom,
                    colors: colors,
                    onTap: () async {
                      ref
                          .read(exportControllerProvider.notifier)
                          .setPeriodPreset(ExportPeriodPreset.custom);
                      await pickCustomRange();
                    },
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (range != null)
                Text(
                  _rangeLabel(range),
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                Text(
                  l10n.exportTapCustomToPickRange,
                  style: TextStyleConstants.b2.copyWith(color: colors.warning),
                ),
              if (preset == ExportPeriodPreset.custom) ...[
                SizedBox(height: 8.h),
                OutlinedButton.icon(
                  onPressed: pickCustomRange,
                  icon: FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 16.sp,
                    color: colors.primary,
                  ),
                  label: Text(
                    l10n.exportSelectCustomRange,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (exportState.errorMessage != null) ...[
          SizedBox(height: 12.h),
          Text(
            exportState.errorMessage!,
            style: TextStyleConstants.label2.copyWith(color: colors.error),
          ),
        ],
        SizedBox(height: 16.h),
        SakuCard(
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exportScopeAlwaysIncluded,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.exportIncludeDebt,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                value: exportState.includeDebtSheet,
                onChanged: (v) => ref
                    .read(exportControllerProvider.notifier)
                    .setIncludeDebt(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.exportIncludeTransfer,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                value: exportState.includeTransferSheet,
                onChanged: (v) => ref
                    .read(exportControllerProvider.notifier)
                    .setIncludeTransfer(v),
              ),
              Text(
                l10n.exportDashboardNote,
                style: TextStyleConstants.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        SakuButton(
          text: exportState.fileFormat == ExportFileFormat.pdf
              ? l10n.exportBuildButtonPdf
              : l10n.exportBuildButton,
          onPressed: range != null ? () => onRunExport() : null,
          isEnabled: range != null,
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyleConstants.label1.copyWith(
          color: selected ? colors.primaryDark : colors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: colors.primaryLight,
      backgroundColor: colors.surfaceVariant.withValues(alpha: 0.35),
      side: BorderSide(
        color: selected ? colors.primary.withValues(alpha: 0.5) : colors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    );
  }
}
