import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/ocr_scan_controller.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_detail_rows_builder.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_detail_table.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_image_preview.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_result_type_badge.dart';
import 'package:app_saku_rapi/global/widgets/ai_item_tile.dart';
import 'package:app_saku_rapi/global/widgets/ai_multi_transaction_preview_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Isi scroll sheet saat status **selesai**: ringkasan tabel + daftar item + total.
///
/// Logika kategori per baris vs kategori root mengikuti sheet induk sebelum refactor.
class OcrResultParsedBody extends ConsumerWidget {
  const OcrResultParsedBody({super.key, required this.state});

  /// State scan yang memuat [OcrScanState.parseResult] dan file gambar opsional.
  final OcrScanState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final result = state.parseResult!;

    if (result.isAiMultiTransaction) {
      final slices = result.aiTransactions!;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.imageFile != null)
              OcrResultImagePreview(imageFile: state.imageFile!),
            SizedBox(height: 12.h),
            OcrResultTypeBadge(type: result.type, colors: colors, l10n: l10n),
            SizedBox(height: 12.h),
            AiMultiTransactionPreviewList(
              slices: slices,
              showOcrAttachmentHint: true,
              rootSuggestedWalletId: result.suggestedWalletId,
            ),
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

    // Peta id → nama kategori untuk chip per baris (legacy) dan nama kategori root.
    final allCategories = ref.read(categoryControllerProvider).categories;
    final categoryMap = {for (final c in allCategories) c.id: c.name};

    final hasMultipleItems = result.items.length > 1;
    final unifiedMultiItemCategory =
        hasMultipleItems &&
        (result.type == 'expense' || result.type == 'income');
    final String? rootCategoryDisplay = () {
      if (result.categoryId != null) {
        final n = categoryMap[result.categoryId];
        if (n != null) return n;
      }
      final kw = result.categoryKeyword;
      if (kw != null && kw.isNotEmpty) return kw;
      return null;
    }();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.imageFile != null)
            OcrResultImagePreview(imageFile: state.imageFile!),

          SizedBox(height: 12.h),

          OcrResultTypeBadge(type: result.type, colors: colors, l10n: l10n),

          SizedBox(height: 12.h),

          OcrDetailTable(
            colors: colors,
            rows: buildOcrDetailRows(
              ref: ref,
              result: result,
              l10n: l10n,
              rootCategoryDisplay: rootCategoryDisplay,
            ),
          ),

          SizedBox(height: 12.h),

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
              (e) => AiItemTile(
                index: e.key,
                name: e.value.name,
                qty: e.value.qty,
                unitPrice: e.value.unitPrice,
                subtotal: e.value.subtotal,
                categoryName:
                    (rootCategoryDisplay != null || unifiedMultiItemCategory)
                    ? null
                    : (e.value.categoryId != null
                          ? categoryMap[e.value.categoryId]
                          : null),
              ),
            ),
          ],

          SizedBox(height: 12.h),

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
                  style: TextStyleConstants.b1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  result.grandTotal?.toCurrency() ?? '-',
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),

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
}
