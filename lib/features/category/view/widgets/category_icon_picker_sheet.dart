import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Daftar icon yang tersedia untuk category picker.
///
/// Setiap entry: (nama string untuk DB, IconData FontAwesome, label display).
const List<({String name, IconData icon, String label})> _availableIcons = [
  (name: 'utensils', icon: FontAwesomeIcons.utensils, label: 'Food'),
  (name: 'mug-hot', icon: FontAwesomeIcons.mugHot, label: 'Coffee'),
  (
    name: 'cart-shopping',
    icon: FontAwesomeIcons.cartShopping,
    label: 'Shopping',
  ),
  (name: 'bus', icon: FontAwesomeIcons.bus, label: 'Bus'),
  (name: 'car', icon: FontAwesomeIcons.car, label: 'Car'),
  (name: 'gas-pump', icon: FontAwesomeIcons.gasPump, label: 'Gas'),
  (name: 'plane', icon: FontAwesomeIcons.plane, label: 'Travel'),
  (name: 'house', icon: FontAwesomeIcons.house, label: 'Home'),
  (name: 'bolt', icon: FontAwesomeIcons.bolt, label: 'Electric'),
  (name: 'wifi', icon: FontAwesomeIcons.wifi, label: 'Internet'),
  (name: 'phone', icon: FontAwesomeIcons.phone, label: 'Phone'),
  (name: 'gamepad', icon: FontAwesomeIcons.gamepad, label: 'Gaming'),
  (name: 'heart-pulse', icon: FontAwesomeIcons.heartPulse, label: 'Health'),
  (name: 'stethoscope', icon: FontAwesomeIcons.stethoscope, label: 'Doctor'),
  (name: 'tooth', icon: FontAwesomeIcons.tooth, label: 'Dental'),
  (name: 'pills', icon: FontAwesomeIcons.pills, label: 'Medicine'),
  (
    name: 'graduation-cap',
    icon: FontAwesomeIcons.graduationCap,
    label: 'Education',
  ),
  (name: 'book', icon: FontAwesomeIcons.book, label: 'Book'),
  (name: 'shirt', icon: FontAwesomeIcons.shirt, label: 'Clothing'),
  (name: 'scissors', icon: FontAwesomeIcons.scissors, label: 'Haircut'),
  (name: 'spray-can', icon: FontAwesomeIcons.sprayCan, label: 'Beauty'),
  (name: 'gift', icon: FontAwesomeIcons.gift, label: 'Gift'),
  (name: 'music', icon: FontAwesomeIcons.music, label: 'Music'),
  (name: 'film', icon: FontAwesomeIcons.film, label: 'Movie'),
  (name: 'dumbbell', icon: FontAwesomeIcons.dumbbell, label: 'Gym'),
  (name: 'baby', icon: FontAwesomeIcons.baby, label: 'Baby'),
  (name: 'paw', icon: FontAwesomeIcons.paw, label: 'Pet'),
  (name: 'broom', icon: FontAwesomeIcons.broom, label: 'Cleaning'),
  (name: 'wrench', icon: FontAwesomeIcons.wrench, label: 'Repair'),
  (
    name: 'screwdriver-wrench',
    icon: FontAwesomeIcons.screwdriverWrench,
    label: 'Tools',
  ),
  (name: 'laptop', icon: FontAwesomeIcons.laptop, label: 'Laptop'),
  (name: 'mobile-screen', icon: FontAwesomeIcons.mobileScreen, label: 'Mobile'),
  (name: 'tv', icon: FontAwesomeIcons.tv, label: 'TV'),
  (name: 'camera', icon: FontAwesomeIcons.camera, label: 'Camera'),
  (name: 'wallet', icon: FontAwesomeIcons.wallet, label: 'Wallet'),
  (name: 'piggy-bank', icon: FontAwesomeIcons.piggyBank, label: 'Savings'),
  (
    name: 'hand-holding-dollar',
    icon: FontAwesomeIcons.handHoldingDollar,
    label: 'Salary',
  ),
  (name: 'sack-dollar', icon: FontAwesomeIcons.sackDollar, label: 'Bonus'),
  (name: 'coins', icon: FontAwesomeIcons.coins, label: 'Coins'),
  (name: 'credit-card', icon: FontAwesomeIcons.creditCard, label: 'Card'),
  (
    name: 'money-bill-wave',
    icon: FontAwesomeIcons.moneyBillWave,
    label: 'Cash',
  ),
  (name: 'chart-line', icon: FontAwesomeIcons.chartLine, label: 'Investment'),
  (
    name: 'building-columns',
    icon: FontAwesomeIcons.buildingColumns,
    label: 'Bank',
  ),
  (name: 'landmark', icon: FontAwesomeIcons.landmark, label: 'Government'),
  (name: 'briefcase', icon: FontAwesomeIcons.briefcase, label: 'Work'),
  (name: 'umbrella', icon: FontAwesomeIcons.umbrella, label: 'Insurance'),
  (
    name: 'shield-halved',
    icon: FontAwesomeIcons.shieldHalved,
    label: 'Security',
  ),
  (name: 'cross', icon: FontAwesomeIcons.cross, label: 'Charity'),
  (name: 'church', icon: FontAwesomeIcons.church, label: 'Worship'),
  (name: 'tag', icon: FontAwesomeIcons.tag, label: 'Other'),
];

/// Bottom sheet grid view untuk memilih icon FontAwesome.
///
/// Fitur:
/// - Grid 5 kolom dengan 50 icon keuangan relevan.
/// - Search box untuk filter icon by name.
/// - Icon yang dipilih diberi border highlight `context.colors.primary`.
class CategoryIconPickerSheet extends StatefulWidget {
  const CategoryIconPickerSheet({super.key, this.selectedIcon});

  /// Nama icon yang sedang dipilih (untuk highlight).
  final String? selectedIcon;

  @override
  State<CategoryIconPickerSheet> createState() =>
      _CategoryIconPickerSheetState();
}

class _CategoryIconPickerSheetState extends State<CategoryIconPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<({String name, IconData icon, String label})> _filtered =
      _availableIcons;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _availableIcons;
      } else {
        _filtered = _availableIcons
            .where(
              (e) =>
                  e.name.contains(query) ||
                  e.label.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.65.sh),
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // ── Title ──
          Text(
            l10n.categoryIconPicker,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),

          // ── Search ──
          SakuTextField(
            controller: _searchController,
            hintText: l10n.categorySearchIcon,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                size: 16.r,
                color: appColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // ── Icon Grid ──
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final item = _filtered[index];
                final isSelected = widget.selectedIcon == item.name;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(item.name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appColors.primary.withValues(alpha: 0.12)
                          : appColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: isSelected
                          ? Border.all(color: appColors.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          item.icon,
                          size: 20.r,
                          color: isSelected
                              ? appColors.primary
                              : appColors.textPrimary,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.label,
                          style: TextStyleConstants.label3.copyWith(
                            color: isSelected
                                ? appColors.primary
                                : appColors.textSecondary,
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
