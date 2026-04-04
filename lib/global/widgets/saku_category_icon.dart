import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget reusable untuk menampilkan icon kategori.
///
/// Sentralisasi rendering icon kategori agar mudah diubah
/// (misalnya dari FontAwesome ke SVG di masa depan).
///
/// **Behavior `size` vs `iconSize`:**
/// - Dengan background (`showBackground: true`): `size` = container size,
///   `iconSize` default ~40% dari `size`.
/// - Tanpa background (`showBackground: false`): `size` langsung jadi icon size
///   (intuitif untuk caller), kecuali `iconSize` di-override.
///
/// Penggunaan utama — dari [CategoryModel]:
/// ```dart
/// SakuCategoryIcon(category: myCategory, size: 42)
/// ```
///
/// Dari raw icon name + color hex (saat [CategoryModel] tidak tersedia):
/// ```dart
/// SakuCategoryIcon.raw(iconName: 'house', colorHex: '#F59E0B', size: 36)
/// ```
///
/// Tanpa background (size = icon size langsung):
/// ```dart
/// SakuCategoryIcon(category: myCategory, size: 16, showBackground: false)
/// ```
///
/// Dengan gradient background:
/// ```dart
/// SakuCategoryIcon(category: myCategory, size: 38, useGradient: true)
/// ```
class SakuCategoryIcon extends StatelessWidget {
  /// Membuat icon dari [CategoryModel].
  ///
  /// [size] — ukuran container (default 38).
  /// [iconSize] — ukuran ikon di dalam container. Jika null, dihitung otomatis ~40% dari size.
  /// [borderRadius] — radius sudut container. Jika null, dihitung ~29% dari size.
  /// [showBackground] — tampilkan container background atau hanya icon.
  /// [isCircle] — gunakan container bulat (override borderRadius).
  /// [useGradient] — pakai gradient background (seperti parent category tile).
  /// [colorOverride] — override warna dari CategoryModel (misal: saat isHidden).
  SakuCategoryIcon({
    super.key,
    required CategoryModel category,
    this.size = 38,
    this.iconSize,
    this.borderRadius,
    this.showBackground = true,
    this.isCircle = false,
    this.useGradient = false,
    Color? colorOverride,
  }) : iconName = category.icon,
       color = colorOverride ?? parseHexColor(category.color);

  /// Membuat icon dari raw icon name + color hex.
  ///
  /// Digunakan saat [CategoryModel] tidak tersedia langsung
  /// (misal: TransactionItemModel, ReportCategoryBreakdownModel, form state).
  SakuCategoryIcon.raw({
    super.key,
    required this.iconName,
    required String colorHex,
    this.size = 38,
    this.iconSize,
    this.borderRadius,
    this.showBackground = true,
    this.isCircle = false,
    this.useGradient = false,
    Color? colorOverride,
  }) : color = colorOverride ?? parseHexColor(colorHex);

  /// Membuat icon dari raw icon name + [Color] langsung.
  ///
  /// Digunakan saat warna sudah di-parse menjadi [Color].
  const SakuCategoryIcon.withColor({
    super.key,
    required this.iconName,
    required this.color,
    this.size = 38,
    this.iconSize,
    this.borderRadius,
    this.showBackground = true,
    this.isCircle = false,
    this.useGradient = false,
  });

  /// Nama icon string dari database (misal: 'house', 'car').
  final String iconName;

  /// Warna icon (sudah di-parse).
  final Color color;

  /// Ukuran container (width & height). Default 38.
  final double size;

  /// Ukuran ikon (tanpa .w).
  /// - Jika null & showBackground=true: dihitung ~40% dari [size].
  /// - Jika null & showBackground=false: sama dengan [size] (icon size langsung).
  final double? iconSize;

  /// Border radius container. Jika null, dihitung ~29% dari [size].
  final double? borderRadius;

  /// Tampilkan container background. Default true.
  final bool showBackground;

  /// Container berbentuk lingkaran. Default false.
  final bool isCircle;

  /// Gunakan gradient background. Default false.
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    // Jika showBackground=false dan iconSize tidak di-set, gunakan size langsung.
    // Jika showBackground=true, gunakan proporsi ~40% dari container size.
    final effectiveIconSize =
        iconSize ?? (showBackground ? (size * 0.4) : size);
    final iconWidget = FaIcon(
      CategoryIconMapper.getIcon(iconName),
      size: effectiveIconSize.w,
      color: color,
    );

    if (!showBackground) return iconWidget;

    final effectiveBorderRadius = borderRadius ?? (size * 0.29);

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: useGradient ? null : color.withValues(alpha: 0.15),
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(effectiveBorderRadius.r),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(child: iconWidget),
    );
  }
}
