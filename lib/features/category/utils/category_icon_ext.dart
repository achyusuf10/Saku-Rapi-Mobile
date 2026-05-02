import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';

/// Extension pada [CategoryModel] untuk membuat [SakuCategoryIcon] secara ringkas.
///
/// Menghilangkan kebutuhan caller untuk parsing hex color manual
/// saat memiliki instance [CategoryModel].
///
/// ```dart
/// category.toIcon(size: 42, useGradient: true)
/// category.toIcon(size: 36, colorOverride: colors.textSecondary)
/// ```
extension CategoryModelIconExt on CategoryModel {
  /// Membuat [SakuCategoryIcon] dari CategoryModel ini.
  ///
  /// [colorOverride] — override warna dari model (misal: saat isHidden).
  /// [backgroundFillOverride] — override latar (misal: preview form).
  SakuCategoryIcon toIcon({
    double size = 38,
    double? iconSize,
    double? borderRadius,
    bool showBackground = true,
    bool useGradient = false,
    bool circular = false,
    Color? colorOverride,
    Color? backgroundFillOverride,
  }) {
    final bg =
        backgroundFillOverride ?? parseHexColor(backgroundColor);
    return SakuCategoryIcon(
      iconName: icon,
      color: colorOverride ?? parseHexColor(color),
      size: size,
      iconSize: iconSize,
      borderRadius: borderRadius,
      showBackground: showBackground,
      useGradient: useGradient,
      backgroundFill: showBackground ? bg : null,
      circular: circular,
    );
  }
}
