import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/models/ai_parse_transaction_slice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Ringkas daftar transaksi hasil AI (multi slice) untuk preview sheet.
class AiMultiTransactionPreviewList extends ConsumerWidget {
  const AiMultiTransactionPreviewList({
    super.key,
    required this.slices,
    this.showOcrAttachmentHint = false,
    this.rootSuggestedWalletId,
  });

  final List<AiParseTransactionSlice> slices;
  final bool showOcrAttachmentHint;

  /// Dompet root dari respons AI (fallback jika slice tidak punya `suggestedWalletId`).
  final String? rootSuggestedWalletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final allCategories = ref.watch(categoryControllerProvider).categories;
    final wallets = ref.watch(walletListProvider);

    String? walletLabelFor(AiParseTransactionSlice slice) {
      final id = (slice.suggestedWalletId != null &&
              slice.suggestedWalletId!.isNotEmpty)
          ? slice.suggestedWalletId
          : rootSuggestedWalletId;
      if (id == null || id.isEmpty) return null;
      return wallets.where((w) => w.id == id).firstOrNull?.name ?? id;
    }

    String? categoryLabel(AiParseTransactionSlice slice) {
      if (slice.categoryId != null) {
        final n = allCategories
            .where((c) => c.id == slice.categoryId)
            .firstOrNull
            ?.name;
        if (n != null) return n;
      }
      final kw = slice.categoryKeyword;
      if (kw != null && kw.isNotEmpty) return kw;
      return null;
    }

    final combined = slices.fold<double>(0, (s, t) => s + t.effectiveTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(
              FontAwesomeIcons.layerGroup,
              size: 16.w,
              color: colors.accent,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiPreviewMultiTitle,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.aiPreviewMultiSubtitle,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showOcrAttachmentHint) ...[
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.image,
                size: 13.w,
                color: colors.info,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.aiPreviewMultiOcrAttachmentHint,
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 14.h),
        ...slices.asMap().entries.map((e) {
          final i = e.key;
          final slice = e.value;
          final cat = categoryLabel(slice);
          return Padding(
            padding: EdgeInsets.only(bottom: i < slices.length - 1 ? 10.h : 0),
            child: _SliceCard(
              index: i + 1,
              slice: slice,
              categoryLabel: cat,
              walletLabel: walletLabelFor(slice),
              colors: colors,
              l10n: l10n,
            ),
          );
        }),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: colors.accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.aiPreviewMultiCombinedTotal,
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                combined.toCurrency(),
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliceCard extends StatelessWidget {
  const _SliceCard({
    required this.index,
    required this.slice,
    required this.categoryLabel,
    required this.walletLabel,
    required this.colors,
    required this.l10n,
  });

  final int index;
  final AiParseTransactionSlice slice;
  final String? categoryLabel;
  final String? walletLabel;
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyleConstants.label1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiPreviewMultiTransactionN(index),
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      slice.effectiveTotal.toCurrency(),
                      style: TextStyleConstants.h7.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (categoryLabel != null && categoryLabel!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.tag,
                  size: 12.w,
                  color: colors.accent,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    categoryLabel!,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (walletLabel != null && walletLabel!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 12.w,
                  color: colors.transfer,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    walletLabel!,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (slice.merchantName != null && slice.merchantName!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.store,
                  size: 12.w,
                  color: colors.info,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    slice.merchantName!,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (slice.note != null && slice.note!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              slice.note!,
              style: TextStyleConstants.caption.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (slice.items.length > 1) ...[
            SizedBox(height: 8.h),
            Text(
              l10n.aiPreviewItemsHeader(slice.items.length),
              style: TextStyleConstants.label3.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            ...slice.items.take(4).map(
              (line) => Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  '${line.name ?? '—'} · ${line.subtotal.toCurrency()}',
                  style: TextStyleConstants.caption.copyWith(
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            if (slice.items.length > 4)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  '+${slice.items.length - 4}',
                  style: TextStyleConstants.label3.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
