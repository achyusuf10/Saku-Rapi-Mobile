import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/utils/wallet_icon_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih warna wallet.
///
/// Mengembalikan hex string `#RRGGBB` yang dipilih user,
/// atau `null` jika dibatalkan.
class WalletColorPicker extends StatelessWidget {
  const WalletColorPicker({super.key, required this.selected});

  /// Hex color yang saat ini dipilih.
  final String selected;

  /// Menampilkan bottom sheet dan mengembalikan hex color yang dipilih.
  static Future<String?> show(BuildContext context, {required String current}) {
    return showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => WalletColorPicker(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

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
              context.l10n.pickerChooseColor,
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
                crossAxisCount: 6,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
              ),
              itemCount: walletColorOptions.length,
              itemBuilder: (context, index) {
                final hex = walletColorOptions[index];
                final color = _hexToColor(hex);
                final isSelected = hex.toUpperCase() == selected.toUpperCase();

                return GestureDetector(
                  onTap: () => Navigator.pop(context, hex),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: appColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? Center(
                            child: FaIcon(
                              FontAwesomeIcons.check,
                              size: 16.r,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Konversi hex string `#RRGGBB` ke [Color].
  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
