import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bagian detail opsional (merchant, catatan, lampiran) dengan expand/collapse.
///
/// Menampilkan header yang bisa di-tap untuk membuka/menutup konten.
/// Digunakan di form transaksi sebagai bagian opsional.
class TransactionOptionalDetailsSection extends StatefulWidget {
  const TransactionOptionalDetailsSection({
    super.key,
    required this.merchantController,
    required this.noteController,
    required this.onMerchantChanged,
    required this.onNoteChanged,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    this.attachmentUrl,
  });

  final TextEditingController merchantController;
  final TextEditingController noteController;
  final ValueChanged<String> onMerchantChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onPickAttachment;
  final VoidCallback onRemoveAttachment;
  final String? attachmentUrl;

  @override
  State<TransactionOptionalDetailsSection> createState() =>
      _TransactionOptionalDetailsSectionState();
}

class _TransactionOptionalDetailsSectionState
    extends State<TransactionOptionalDetailsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              color: Colors.transparent,
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circlePlus,
                    size: 18.w,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.l10n.transactionOptionalFields,
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 12.w,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: colors.border.withValues(alpha: 0.3)),
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    children: [
                      SakuTextField(
                        controller: widget.merchantController,
                        label: context.l10n.transactionMerchant,
                        hint: context.l10n.transactionMerchantHint,
                        onChanged: (v) => widget.onMerchantChanged(v),
                      ),
                      SizedBox(height: 10.h),
                      SakuTextField(
                        controller: widget.noteController,
                        label: context.l10n.transactionNote,
                        hint: '...',
                        maxLines: 2,
                        minLines: 2,
                        onChanged: (v) => widget.onNoteChanged(v),
                      ),
                      SizedBox(height: 10.h),
                      TransactionAttachmentField(
                        attachmentUrl: widget.attachmentUrl,
                        onPick: widget.onPickAttachment,
                        onRemove: widget.onRemoveAttachment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

/// Field lampiran: menampilkan tombol pick atau preview gambar.
///
/// Digunakan di dalam [TransactionOptionalDetailsSection].
class TransactionAttachmentField extends StatelessWidget {
  const TransactionAttachmentField({
    super.key,
    required this.onPick,
    required this.onRemove,
    this.attachmentUrl,
  });

  final String? attachmentUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (attachmentUrl != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                attachmentUrl!,
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120.h,
                  color: colors.background,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      size: 24.w,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: colors.expense.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 10.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pick button
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.paperclip,
              size: 13.w,
              color: colors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              context.l10n.transactionAttachmentAdd,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
