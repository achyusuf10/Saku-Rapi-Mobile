import 'package:app_saku_rapi/core/utils/saku_icon_mapper.dart';
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
/// [backgroundFill] — jika diisi (mis. dari `WalletModel.backgroundColor`),
/// menggantikan tint/gradient default sebagai warna latar.
///
/// [circular] — `true` untuk lingkaran penuh (mis. baris transaksi); `false`
/// untuk rounded square (form, kartu).
///
/// Warna dengan alpha pada [backgroundFill] menumpuk langsung ke latar induk
/// (tanpa pola checkerboard).
class SakuCategoryIcon extends StatelessWidget {
  /// Membuat icon dari [iconName] dan [color].
  const SakuCategoryIcon({
    super.key,
    required this.iconName,
    required this.color,
    this.size = 38,
    this.iconSize,
    this.borderRadius,
    this.showBackground = true,
    this.useGradient = false,
    this.backgroundFill,
    this.circular = false,
  });

  /// Nama icon string dari database (misal: 'house', 'car').
  /// Kedepannya jika mengandung '.svg', akan dirender sebagai SVG.
  final String iconName;

  /// Warna icon.
  final Color color;

  /// Ukuran container (width & height). Default 38.
  final double size;

  /// Ukuran ikon override.
  final double? iconSize;

  /// Border radius container (hanya jika [circular] == false). Default: 10.
  final double? borderRadius;

  /// Tampilkan container background. Default true.
  final bool showBackground;

  /// Gunakan gradient background. Default false.
  /// Diabaikan jika [backgroundFill] tidak null.
  final bool useGradient;

  /// Warna latar eksplisit (dompet / kategori). Mendukung transparansi.
  final Color? backgroundFill;

  /// Lingkaran penuh vs rounded rectangle.
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize =
        iconSize ?? (showBackground ? (size * 0.4) : size);

    final iconWidget = FaIcon(
      SakuIconMapper.getIcon(iconName),
      size: effectiveIconSize.w,
      color: color,
    );

    if (!showBackground) return iconWidget;

    final effectiveBorderRadius = borderRadius ?? 10;

    if (backgroundFill != null) {
      final content = SizedBox(
        width: size.w,
        height: size.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundFill!),
            Center(child: iconWidget),
          ],
        ),
      );
      if (circular) {
        return ClipOval(child: content);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius.r),
        child: content,
      );
    }

    if (circular) {
      return Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
        ),
        child: Center(child: iconWidget),
      );
    }

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
