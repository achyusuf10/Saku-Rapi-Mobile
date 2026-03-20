import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/utils/wallet_icon_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih ikon wallet.
///
/// Mengembalikan key [String] dari [walletIconMap] yang dipilih user,
/// atau `null` jika dibatalkan.
class WalletIconPicker extends StatelessWidget {
  const WalletIconPicker({super.key, required this.selected});

  /// Key ikon yang saat ini dipilih.
  final String selected;

  /// Menampilkan bottom sheet dan mengembalikan key ikon yang dipilih.
  static Future<String?> show(BuildContext context, {required String current}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => WalletIconPicker(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final entries = walletIconMap.entries.toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              context.l10n.pickerChooseIcon,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isSelected = entry.key == selected;

                return GestureDetector(
                  onTap: () => Navigator.pop(context, entry.key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appColors.primary.withValues(alpha: 0.15)
                          : appColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: isSelected
                          ? Border.all(color: appColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: FaIcon(
                        entry.value,
                        size: 22.r,
                        color: isSelected
                            ? appColors.primary
                            : appColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
