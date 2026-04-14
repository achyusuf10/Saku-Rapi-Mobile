import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/saku_icon_mapper.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet global untuk memilih ikon.
///
/// Menampilkan ikon dikelompokkan per section (Keuangan, Transportasi, dll).
/// Mendukung pencarian bilingual (ID + EN).
///
/// ```dart
/// final icon = await SakuIconPickerSheet.show(
///   context: context,
///   selectedIcon: currentIcon,
/// );
/// ```
class SakuIconPickerSheet extends StatefulWidget {
  const SakuIconPickerSheet({super.key, this.selectedIcon});

  /// Nama ikon yang sedang dipilih (untuk highlight).
  final String? selectedIcon;

  /// Menampilkan icon picker dan return nama ikon terpilih.
  static Future<String?> show({
    required BuildContext context,
    String? selectedIcon,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SakuIconPickerSheet(selectedIcon: selectedIcon),
    );
  }

  @override
  State<SakuIconPickerSheet> createState() => _SakuIconPickerSheetState();
}

class _SakuIconPickerSheetState extends State<SakuIconPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim();
    setState(() {
      _isSearching = q.isNotEmpty;
      if (_isSearching) {
        _searchResults = SakuIconMapper.search(q);
      }
    });
  }

  String _getSectionLabel(String sectionId) {
    final l10n = context.l10n;
    return switch (sectionId) {
      'finance' => l10n.iconSectionFinance,
      'shopping' => l10n.iconSectionShopping,
      'foodDrink' => l10n.iconSectionFoodDrink,
      'household' => l10n.iconSectionHousehold,
      'transport' => l10n.iconSectionTransport,
      'health' => l10n.iconSectionHealth,
      'bills' => l10n.iconSectionBills,
      'tech' => l10n.iconSectionTech,
      'education' => l10n.iconSectionEducation,
      'entertainment' => l10n.iconSectionEntertainment,
      'nature' => l10n.iconSectionNature,
      'social' => l10n.iconSectionSocial,
      'other' => l10n.iconSectionOther,
      _ => sectionId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              l10n.iconPickerTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuTextField(
              controller: _searchController,
              hint: l10n.iconPickerSearch,
              onChanged: _onSearch,
              prefixIcon: Icon(
                Icons.search,
                color: colors.textSecondary,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Icon content
          Flexible(
            child: _isSearching ? _buildSearchResults() : _buildSections(),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.h),
        ],
      ),
    );
  }

  // ─────────── Grouped Sections ───────────

  Widget _buildSections() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: SakuIconMapper.sections.length,
      itemBuilder: (context, index) {
        final section = SakuIconMapper.sections[index];
        return _buildSection(section);
      },
    );
  }

  Widget _buildSection(IconSection section) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
          child: Text(
            _getSectionLabel(section.id),
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: section.iconNames
              .map((name) => _buildIconTile(name))
              .toList(),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }

  // ─────────── Search Results ───────────

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Text(
            context.l10n.iconSearchEmpty,
            style: TextStyleConstants.b2.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.start,
        spacing: 8.w,
        runSpacing: 8.h,
        children: _searchResults.map((name) => _buildIconTile(name)).toList(),
      ),
    );
  }

  // ─────────── Icon Tile ───────────

  Widget _buildIconTile(String iconName) {
    final colors = context.colors;
    final isSelected = iconName == widget.selectedIcon;
    final icon = SakuIconMapper.getIcon(iconName);

    return InkWell(
      onTap: () => Navigator.pop(context, iconName),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 18.w,
            color: isSelected ? colors.primary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
