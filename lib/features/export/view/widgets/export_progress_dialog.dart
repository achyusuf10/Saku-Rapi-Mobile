import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/export/controllers/export_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dialog blocking selama fetch/build export. Mengembalikan [ExportUiState]
/// saat sukses, atau `null` jika dibatalkan / ditutup tanpa file.
class ExportProgressDialog extends ConsumerStatefulWidget {
  const ExportProgressDialog({super.key, required this.localeName});

  final String localeName;

  @override
  ConsumerState<ExportProgressDialog> createState() =>
      _ExportProgressDialogState();
}

class _ExportProgressDialogState extends ConsumerState<ExportProgressDialog> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      final l10n = context.l10n;
      ref
          .read(exportControllerProvider.notifier)
          .runExport(context, l10n, widget.localeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(exportControllerProvider);

    ref.listen<ExportUiState>(exportControllerProvider, (prev, next) {
      if (next.phase == ExportRunPhase.success && next.savedFilePath != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context, next);
        });
      } else if (prev != null &&
          prev.phase != ExportRunPhase.idle &&
          next.phase == ExportRunPhase.idle &&
          next.savedFilePath == null &&
          next.errorMessage == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context, null);
        });
      }
    });

    final isBusy =
        state.phase == ExportRunPhase.fetching ||
        state.phase == ExportRunPhase.building;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 340.w),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.fileFormat == ExportFileFormat.pdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.table_chart_rounded,
                      color: colors.primary,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      l10n.exportProgressMessage,
                      style: TextStyleConstants.b1.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              if (isBusy) LinearProgressIndicator(color: colors.primary),
              SizedBox(height: 16.h),
              SakuButton(
                text: l10n.exportCancel,
                isOutlined: true,
                onPressed: isBusy
                    ? () => ref
                          .read(exportControllerProvider.notifier)
                          .cancelExport()
                    : null,
                isEnabled: isBusy,
              ),
              if (state.showPartialAction) ...[
                SizedBox(height: 8.h),
                SakuButton(
                  text: l10n.exportStopAndBuild,
                  onPressed: isBusy
                      ? () => ref
                            .read(exportControllerProvider.notifier)
                            .requestPartialStop()
                      : null,
                  isEnabled: isBusy,
                ),
              ],
              if (state.errorMessage != null && !isBusy) ...[
                SizedBox(height: 12.h),
                Text(
                  state.errorMessage!,
                  style: TextStyleConstants.label2.copyWith(color: colors.error),
                ),
                SizedBox(height: 12.h),
                SakuButton(
                  text: l10n.exportClose,
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
