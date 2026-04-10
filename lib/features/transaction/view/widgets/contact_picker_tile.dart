import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile kontak yang ditampilkan di form transaksi hutang/piutang.
///
/// Menampilkan kontak yang dipilih atau placeholder. Klik membuka
/// [ContactPickerSheet]. Ada tombol clear untuk menghapus pilihan.
class ContactPickerTile extends StatelessWidget {
  const ContactPickerTile({
    super.key,
    required this.onTap,
    required this.onClear,
    this.selected,
    this.iconColor,
  });

  final ContactModel? selected;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasSelection = selected != null;
    final tileIconColor = iconColor ?? colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Avatar / icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: tileIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasSelection
                    ? Text(
                        selected!.name.isNotEmpty
                            ? selected!.name[0].toUpperCase()
                            : '?',
                        style: TextStyleConstants.b1.copyWith(
                          color: tileIconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : FaIcon(
                        FontAwesomeIcons.userGroup,
                        size: 16.w,
                        color: tileIconColor,
                      ),
              ),
            ),
            SizedBox(width: 12.w),

            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contactPickerSelected.toUpperCase(),
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasSelection
                        ? selected!.displayLabel
                        : l10n.contactPickerTitle,
                    style: TextStyleConstants.b2.copyWith(
                      color: hasSelection
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Clear or chevron
            if (hasSelection)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    Icons.close,
                    size: 18.w,
                    color: colors.textSecondary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20.w,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
