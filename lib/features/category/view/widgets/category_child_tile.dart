import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile untuk child category (sub-kategori) di bawah parent.
///
/// Ditampilkan di dalam `CategoryParentTile` saat di-expand.
/// Long-press → callback untuk opsi (edit, hide, delete).
class CategoryChildTile extends StatelessWidget {
  const CategoryChildTile({
    super.key,
    required this.category,
    required this.onLongPress,
  });

  /// Kategori child.
  final CategoryModel category;

  /// Callback saat tile di-long-press.
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final catColor = _hexColor(category.color);

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: 68.w,
          right: 16.w,
          top: 8.h,
          bottom: 8.h,
        ),
        child: Row(
          children: [
            // ── Icon ──
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: FaIcon(
                  _categoryIcon(category.icon),
                  color: catColor,
                  size: 14.r,
                ),
              ),
            ),

            SizedBox(width: 10.w),

            // ── Name ──
            Expanded(
              child: Text(
                category.name,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: category.isHidden
                      ? appColors.textSecondary
                      : appColors.textPrimary,
                ),
              ),
            ),

            // ── Hidden tag ──
            if (category.isHidden)
              Text(
                l10n.categoryHidden,
                style: TextStyleConstants.label3.copyWith(
                  color: appColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _categoryIcon(String iconName) {
    return switch (iconName) {
      'utensils' => FontAwesomeIcons.utensils,
      'cart-shopping' => FontAwesomeIcons.cartShopping,
      'bus' => FontAwesomeIcons.bus,
      'car' => FontAwesomeIcons.car,
      'house' => FontAwesomeIcons.house,
      'bolt' => FontAwesomeIcons.bolt,
      'gamepad' => FontAwesomeIcons.gamepad,
      'heart-pulse' => FontAwesomeIcons.heartPulse,
      'graduation-cap' => FontAwesomeIcons.graduationCap,
      'shirt' => FontAwesomeIcons.shirt,
      'gift' => FontAwesomeIcons.gift,
      'plane' => FontAwesomeIcons.plane,
      'phone' => FontAwesomeIcons.phone,
      'money-bill-wave' => FontAwesomeIcons.moneyBillWave,
      'building-columns' => FontAwesomeIcons.buildingColumns,
      'briefcase' => FontAwesomeIcons.briefcase,
      'mug-hot' => FontAwesomeIcons.mugHot,
      'gas-pump' => FontAwesomeIcons.gasPump,
      'wifi' => FontAwesomeIcons.wifi,
      'baby' => FontAwesomeIcons.baby,
      'paw' => FontAwesomeIcons.paw,
      'dumbbell' => FontAwesomeIcons.dumbbell,
      'wallet' => FontAwesomeIcons.wallet,
      'piggy-bank' => FontAwesomeIcons.piggyBank,
      'hand-holding-dollar' => FontAwesomeIcons.handHoldingDollar,
      'sack-dollar' => FontAwesomeIcons.sackDollar,
      'coins' => FontAwesomeIcons.coins,
      'credit-card' => FontAwesomeIcons.creditCard,
      'chart-line' => FontAwesomeIcons.chartLine,
      'landmark' => FontAwesomeIcons.landmark,
      'stethoscope' => FontAwesomeIcons.stethoscope,
      'tooth' => FontAwesomeIcons.tooth,
      'pills' => FontAwesomeIcons.pills,
      'music' => FontAwesomeIcons.music,
      'film' => FontAwesomeIcons.film,
      'book' => FontAwesomeIcons.book,
      'scissors' => FontAwesomeIcons.scissors,
      'spray-can' => FontAwesomeIcons.sprayCan,
      'broom' => FontAwesomeIcons.broom,
      'wrench' => FontAwesomeIcons.wrench,
      'screwdriver-wrench' => FontAwesomeIcons.screwdriverWrench,
      'laptop' => FontAwesomeIcons.laptop,
      'mobile-screen' => FontAwesomeIcons.mobileScreen,
      'tv' => FontAwesomeIcons.tv,
      'camera' => FontAwesomeIcons.camera,
      'umbrella' => FontAwesomeIcons.umbrella,
      'shield-halved' => FontAwesomeIcons.shieldHalved,
      'cross' => FontAwesomeIcons.cross,
      'church' => FontAwesomeIcons.church,
      _ => FontAwesomeIcons.tag,
    };
  }
}
