import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_child_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tile expandable untuk parent category di `CategoryListScreen`.
///
/// Menampilkan icon, nama, badge jumlah children.
/// Tap → expand/collapse children list.
/// Long-press → callback untuk opsi (edit, hide, delete).
class CategoryParentTile extends StatelessWidget {
  const CategoryParentTile({
    super.key,
    required this.category,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
    required this.onChildLongPress,
  });

  /// Kategori parent (sudah diisi [children]).
  final CategoryModel category;

  /// Apakah tile sedang di-expand (menampilkan children).
  final bool isExpanded;

  /// Callback saat tile ditekan (toggle expand).
  final VoidCallback onTap;

  /// Callback saat tile di-long-press (tampilkan opsi).
  final VoidCallback onLongPress;

  /// Callback saat child tile di-long-press.
  final void Function(CategoryModel child) onChildLongPress;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final catColor = _hexColor(category.color);

    return Column(
      children: [
        // ── Parent Row ──
        InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // ── Icon ──
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      _categoryIcon(category.icon),
                      color: catColor,
                      size: 18.r,
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // ── Name + Hidden badge ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyleConstants.b1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: category.isHidden
                              ? appColors.textSecondary
                              : appColors.textPrimary,
                        ),
                      ),
                      if (category.isHidden) ...[
                        SizedBox(height: 2.h),
                        Text(
                          l10n.categoryHidden,
                          style: TextStyleConstants.label3.copyWith(
                            color: appColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Child count badge ──
                if (category.children.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      l10n.categoryChildCount(category.children.length),
                      style: TextStyleConstants.label3.copyWith(
                        color: appColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],

                // ── Expand arrow ──
                if (category.children.isNotEmpty)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 14.r,
                      color: appColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Children (animated) ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: category.children
                .map(
                  (child) => CategoryChildTile(
                    category: child,
                    onLongPress: () => onChildLongPress(child),
                  ),
                )
                .toList(),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
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
