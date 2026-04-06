import 'package:app_saku_rapi/core/utils/category_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget reusable untuk menampilkan icon kategori / wallet.
///
/// Sentralisasi rendering icon agar mudah diubah
/// (misalnya dari FontAwesome ke SVG di masa depan).
///
/// **Behavior `size` vs `iconSize`:**
/// - Dengan background (`showBackground: true`): `size` = container size,
///   `iconSize` default ~40% dari `size`.
/// - Tanpa background (`showBackground: false`): `size` langsung jadi icon size
///   (intuitif untuk caller), kecuali `iconSize` di-override.
///
/// Penggunaan langsung:
/// ```dart
/// SakuCategoryIcon(iconName: 'house', color: Colors.amber, size: 42)
/// ```
///
/// Tanpa background (size = icon size langsung):
/// ```dart
/// SakuCategoryIcon(iconName: 'house', color: Colors.amber, size: 16, showBackground: false)
/// ```
///
/// Dengan gradient background:
/// ```dart
/// SakuCategoryIcon(iconName: 'house', color: Colors.amber, size: 38, useGradient: true)
/// ```
///
/// Dari [CategoryModel], gunakan extension `toIcon()`:
/// ```dart
/// import 'package:app_saku_rapi/features/category/utils/category_icon_ext.dart';
/// myCategory.toIcon(size: 42, useGradient: true)
/// ```
class SakuCategoryIcon extends StatelessWidget {
  /// Membuat icon dari [iconName] dan [color].
  ///
  /// [size] — ukuran container (default 38).
  /// [iconSize] — ukuran ikon di dalam container. Jika null, dihitung otomatis ~40% dari size.
  /// [borderRadius] — radius sudut container. Jika null, dihitung ~29% dari size.
  /// [showBackground] — tampilkan container background atau hanya icon.
  /// [useGradient] — pakai gradient background (seperti parent category tile).
  const SakuCategoryIcon({
    super.key,
    required this.iconName,
    required this.color,
    this.size = 38,
    this.iconSize,
    this.borderRadius,
    this.showBackground = true,
    this.useGradient = false,
  });

  /// Nama icon string dari database (misal: 'house', 'car').
  /// Kedepannya jika mengandung '.svg', akan dirender sebagai SVG.
  final String iconName;

  /// Warna icon.
  final Color color;

  /// Ukuran container (width & height). Default 38.
  final double size;

  /// Ukuran ikon override.
  /// - Jika null & showBackground=true: dihitung ~40% dari [size].
  /// - Jika null & showBackground=false: sama dengan [size] (icon size langsung).
  final double? iconSize;

  /// Border radius container. Jika null, dihitung ~29% dari [size].
  final double? borderRadius;

  /// Tampilkan container background. Default true.
  final bool showBackground;

  /// Gunakan gradient background. Default false.
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize =
        iconSize ?? (showBackground ? (size * 0.4) : size);

    // TODO: Jika iconName mengandung '.svg', render sebagai SvgPicture.
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
        borderRadius: BorderRadius.circular(effectiveBorderRadius.r),
      ),
      child: Center(child: iconWidget),
    );
  }
}
