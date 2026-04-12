import 'dart:io';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/view/widgets/ai_quota_info_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk menampilkan hasil scan OCR struk.
///
/// Menampilkan:
/// - Preview gambar struk (thumbnail)
/// - Merchant name & tanggal
/// - Daftar item yang terdeteksi
/// - Grand total
/// - Warning jika total mismatch
/// - Tombol: Rescan / Gunakan Hasil
///
/// Return [OcrParseResultModel] jika user menekan Gunakan Hasil,
/// atau `null` jika dibatalkan.
class OcrResultSheet extends ConsumerWidget {
  const OcrResultSheet({super.key});

  /// Tampilkan sheet dan return hasil OCR atau null.
  static Future<OcrParseResultModel?> show({required BuildContext context}) {
    return showModalBottomSheet<OcrParseResultModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const OcrResultSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(ocrScanControllerProvider);
    final ctrl = ref.read(ocrScanControllerProvider.notifier);

    // Refresh quota setelah AI parse selesai
    ref.listen<OcrScanState>(ocrScanControllerProvider, (prev, next) {
      if (prev?.status == OcrScanStatus.analyzingAi &&
          (next.status == OcrScanStatus.done ||
              next.status == OcrScanStatus.error)) {
        ref.invalidate(aiQuotaProvider);
      }
    });

    final isAnalyzing = state.status == OcrScanStatus.analyzingAi;

    return PopScope(
      canPop: !isAnalyzing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await context.showConfirmDialog(
          title: l10n.aiParseCancelTitle,
          message: l10n.aiParseCancelMessage,
          confirmLabel: l10n.aiParseCancelConfirm,
          cancelLabel: l10n.confirmCancel,
        );
        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandleBar(colors),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.receipt,
                    size: 18.w,
                    color: colors.accent,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.ocrResultTitle,
                    style: TextStyleConstants.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.border.withValues(alpha: 0.2)),

            // Quota info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: const AiQuotaInfoRow(mode: 'ocr'),
            ),

            // Content
            Flexible(child: _buildContent(context, ref, state, ctrl)),

            // Bottom action buttons
            _buildActions(context, ref, state, ctrl),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHandleBar(dynamic colors) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        width: 36.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: colors.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    OcrScanState state,
    OcrScanController ctrl,
  ) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Loading states
    if (state.status == OcrScanStatus.pickingImage ||
        state.status == OcrScanStatus.cropping) {
      return _buildLoadingState(l10n.ocrProcessing, colors);
    }
    if (state.status == OcrScanStatus.analyzingAi) {
      return _buildLoadingState(l10n.ocrAnalyzingAi, colors);
    }

    // Permission denied
    if (state.status == OcrScanStatus.permissionDenied) {
      return _buildPermissionDenied(context, ctrl, state.isPermanentlyDenied);
    }

    // Error
    if (state.status == OcrScanStatus.error) {
      return _buildError(context, state);
    }

    // Done — show parsed result
    if (state.status == OcrScanStatus.done && state.parseResult != null) {
      return _buildResult(context, ref, state);
    }

    // Idle — show source picker
    return _buildSourcePicker(context, ctrl);
  }

  Widget _buildLoadingState(String message, dynamic colors) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            message,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
    BuildContext context,
    OcrScanController ctrl,
    bool isPermanent,
  ) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.cameraRotate,
            size: 48.w,
            color: colors.expense,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.ocrPermissionDenied,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.ocrPermissionExplainer,
            style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isPermanent) ...[
            SizedBox(height: 20.h),
            TextButton.icon(
              onPressed: ctrl.openSettings,
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: 14.w,
                color: colors.primary,
              ),
              label: Text(
                l10n.voiceOpenSettings,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, OcrScanState state) {
    final colors = context.colors;
    final l10n = context.l10n;

    String message;
    IconData icon;
    if (state.errorMessage == 'NOT_TRANSACTION') {
      message = l10n.ocrNotTransaction;
      icon = FontAwesomeIcons.imagePortrait;
    } else if (state.errorMessage == 'NO_TEXT') {
      message = l10n.ocrNoText;
      icon = FontAwesomeIcons.triangleExclamation;
    } else if (state.errorMessage == 'PARSE_FAILED') {
      message = l10n.ocrImageBlurry;
      icon = FontAwesomeIcons.triangleExclamation;
    } else if (state.errorMessage == 'DAILY_QUOTA_EXCEEDED') {
      message = l10n.aiQuotaExhausted;
      icon = FontAwesomeIcons.circleExclamation;
    } else {
      message = l10n.ocrErrorGeneric;
      icon = FontAwesomeIcons.triangleExclamation;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 48.w, color: colors.expense),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyleConstants.b1.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePicker(BuildContext context, OcrScanController ctrl) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.ocrPickerTitle,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: FontAwesomeIcons.camera,
                  label: l10n.ocrCamera,
                  color: colors.info,
                  onTap: () => ctrl.startFromCamera(context),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _SourceButton(
                  icon: FontAwesomeIcons.images,
                  label: l10n.ocrGallery,
                  color: colors.primary,
                  onTap: () => ctrl.startFromGallery(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, WidgetRef ref, OcrScanState state) {
    final colors = context.colors;
    final l10n = context.l10n;
    final result = state.parseResult!;

    // Build category lookup from user's categories
    final allCategories = ref.read(categoryControllerProvider).categories;
    final categoryMap = {for (final c in allCategories) c.id: c.name};

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview thumbnail
          if (state.imageFile != null) _buildImagePreview(state.imageFile!),

          SizedBox(height: 12.h),

          // Transaction type badge
          _buildTypeBadge(result.type, colors, l10n),

          SizedBox(height: 12.h),

          // Merchant & Date
          if (result.merchantName != null) ...[
            _InfoRow(
              icon: FontAwesomeIcons.store,
              label: l10n.ocrMerchant,
              value: result.merchantName!,
              colors: colors,
            ),
            SizedBox(height: 8.h),
          ],
          if (result.date != null) ...[
            _InfoRow(
              icon: FontAwesomeIcons.calendar,
              label: l10n.ocrDate,
              value: result.date!.extToDateStringDDMMMMYYYY(),
              colors: colors,
            ),
            SizedBox(height: 8.h),
          ],

          // Transfer: wallet info
          if (result.type == 'transfer') ...[
            if (result.suggestedWallet != null) ...[
              _InfoRow(
                icon: FontAwesomeIcons.wallet,
                label: l10n.ocrSourceWallet,
                value: result.suggestedWallet!,
                colors: colors,
              ),
              SizedBox(height: 8.h),
            ],
            if (result.destinationWallet != null) ...[
              _InfoRow(
                icon: FontAwesomeIcons.arrowRight,
                label: l10n.ocrDestWallet,
                value: result.destinationWallet!,
                colors: colors,
              ),
              SizedBox(height: 8.h),
            ],
          ],

          // Debt/Loan: person info
          if ((result.type == 'debt' || result.type == 'loan') &&
              result.withPerson != null) ...[
            _InfoRow(
              icon: FontAwesomeIcons.user,
              label: l10n.ocrWithPerson,
              value: result.withPerson!,
              colors: colors,
            ),
            SizedBox(height: 8.h),
          ],

          // Payment method (non-transfer)
          if (result.type != 'transfer' && result.suggestedWallet != null) ...[
            _InfoRow(
              icon: FontAwesomeIcons.creditCard,
              label: l10n.ocrPaymentMethod,
              value: result.suggestedWallet!,
              colors: colors,
            ),
            SizedBox(height: 8.h),
          ],

          SizedBox(height: 8.h),

          // Items section
          if (result.items.isNotEmpty) ...[
            Row(
              children: [
                FaIcon(FontAwesomeIcons.list, size: 14.w, color: colors.accent),
                SizedBox(width: 8.w),
                Text(
                  l10n.ocrItemCount(result.items.length),
                  style: TextStyleConstants.label1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ...result.items.asMap().entries.map(
              (e) => _OcrItemTile(
                index: e.key,
                item: e.value,
                colors: colors,
                categoryName: e.value.categoryId != null
                    ? categoryMap[e.value.categoryId]
                    : null,
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // Grand total
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.ocrGrandTotal,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  result.grandTotal?.toCurrency() ?? '-',
                  style: TextStyleConstants.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Total mismatch warning
          if (result.grandTotal != null &&
              result.items.isNotEmpty &&
              !result.isTotalMatched) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: colors.expense.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    size: 14.w,
                    color: colors.expense,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.ocrTotalMismatch(
                        result.itemsTotal.toCurrency(),
                        result.grandTotal!.toCurrency(),
                      ),
                      style: TextStyleConstants.caption.copyWith(
                        color: colors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Provider badge
          if (result.provider != null) ...[
            SizedBox(height: 12.h),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'AI: ${result.provider}',
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File imageFile) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.file(imageFile, height: 120.h, fit: BoxFit.cover),
      ),
    );
  }

  /// Badge tipe transaksi (expense/income/transfer/debt/loan).
  Widget _buildTypeBadge(String type, dynamic colors, dynamic l10n) {
    final (String label, Color color, IconData icon) = switch (type) {
      'income' => (
        l10n.ocrTypeIncome as String,
        colors.income as Color,
        FontAwesomeIcons.arrowDown,
      ),
      'transfer' => (
        l10n.ocrTypeTransfer as String,
        colors.info as Color,
        FontAwesomeIcons.rightLeft,
      ),
      'debt' => (
        l10n.ocrTypeDebt as String,
        colors.expense as Color,
        FontAwesomeIcons.handHoldingDollar,
      ),
      'loan' => (
        l10n.ocrTypeLoan as String,
        colors.accent as Color,
        FontAwesomeIcons.handHoldingDollar,
      ),
      _ => (
        l10n.ocrTypeExpense as String,
        colors.expense as Color,
        FontAwesomeIcons.arrowUp,
      ),
    };

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14.w, color: color),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyleConstants.label1.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    OcrScanState state,
    OcrScanController ctrl,
  ) {
    final colors = context.colors;
    final l10n = context.l10n;
    final nav = Navigator.of(context);
    final accentColor = colors.accent;
    final accentForeground = _foregroundForBackground(accentColor);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Cancel / Rescan button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (state.status == OcrScanStatus.done ||
                    state.status == OcrScanStatus.error) {
                  ctrl.reset();
                } else {
                  nav.pop();
                }
              },
              icon: FaIcon(
                state.status == OcrScanStatus.done ||
                        state.status == OcrScanStatus.error
                    ? FontAwesomeIcons.rotateRight
                    : FontAwesomeIcons.xmark,
                size: 14.w,
              ),
              label: Text(
                state.status == OcrScanStatus.done ||
                        state.status == OcrScanStatus.error
                    ? l10n.ocrRescan
                    : l10n.confirmCancel,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.border.withValues(alpha: 0.3)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Continue / Use result button
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  state.status == OcrScanStatus.done &&
                      state.parseResult != null
                  ? () {
                      // Simpan image file ke provider sebelum pop
                      // agar transaction form bisa auto-fill lampiran
                      if (state.imageFile != null) {
                        ref.read(pendingOcrImageFileProvider.notifier).state =
                            state.imageFile;
                      }
                      nav.pop(state.parseResult);
                    }
                  : null,
              icon: FaIcon(FontAwesomeIcons.check, size: 14.w),
              label: Text(l10n.ocrUseResult),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: accentForeground,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.3),
                disabledForegroundColor: accentForeground.withValues(
                  alpha: 0.65,
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _foregroundForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}

// ───────────────── Private Widgets ─────────────────

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Center(
                child: FaIcon(icon, size: 22.w, color: color),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyleConstants.label1.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14.w, color: colors.textSecondary),
        SizedBox(width: 10.w),
        Text(
          '$label: ',
          style: TextStyleConstants.label2.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyleConstants.b2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OcrItemTile extends StatelessWidget {
  const _OcrItemTile({
    required this.index,
    required this.item,
    required this.colors,
    this.categoryName,
  });

  final int index;
  final OcrItemModel item;
  final dynamic colors;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyleConstants.caption.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Name + qty
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '-',
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.qty > 1 || item.unitPrice != null)
                  Text(
                    '${item.qty > 1 ? '${item.qty.toInt()}x ' : ''}'
                    '${item.unitPrice != null ? '@ ${item.unitPrice!.toCurrency(withPrefix: false)}' : ''}',
                    style: TextStyleConstants.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (categoryName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        categoryName!,
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.accent,
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Subtotal
          Text(
            item.subtotal.toCurrency(withPrefix: false),
            style: TextStyleConstants.b2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
