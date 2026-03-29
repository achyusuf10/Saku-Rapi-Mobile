import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ═══════════════ Filter State ═══════════════

/// Enum opsi sorting.
enum InvestmentSortOption { newest, oldest, highest, lowest }

/// State untuk filter & sort investasi.
class InvestmentFilterState {
  const InvestmentFilterState({
    this.sortOption = InvestmentSortOption.newest,
    this.selectedType,
    this.selectedAssetTypeId,
    this.searchQuery = '',
  });

  final InvestmentSortOption sortOption;

  /// Filter by investment type: 'gold', 'crypto', 'custom', or null (all).
  final String? selectedType;

  /// Filter by specific asset type ID (for custom types).
  final String? selectedAssetTypeId;

  /// Search by name.
  final String searchQuery;

  bool get hasActiveFilter =>
      sortOption != InvestmentSortOption.newest ||
      selectedType != null ||
      selectedAssetTypeId != null ||
      searchQuery.isNotEmpty;

  InvestmentFilterState copyWith({
    InvestmentSortOption? sortOption,
    String? selectedType,
    bool clearSelectedType = false,
    String? selectedAssetTypeId,
    bool clearSelectedAssetTypeId = false,
    String? searchQuery,
  }) {
    return InvestmentFilterState(
      sortOption: sortOption ?? this.sortOption,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      selectedAssetTypeId: clearSelectedAssetTypeId
          ? null
          : (selectedAssetTypeId ?? this.selectedAssetTypeId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ═══════════════ Bottom Sheet ═══════════════

/// Bottom sheet untuk filter & sorting investasi.
///
/// Returns [InvestmentFilterState] ketika user tap "Terapkan",
/// atau `null` jika dismissed.
class InvestmentFilterSheet extends StatefulWidget {
  const InvestmentFilterSheet({
    super.key,
    required this.currentFilter,
    required this.assetTypes,
  });

  final InvestmentFilterState currentFilter;
  final List<AssetTypeModel> assetTypes;

  /// Show the filter bottom sheet and return the selected filter state.
  static Future<InvestmentFilterState?> show(
    BuildContext context, {
    required InvestmentFilterState currentFilter,
    required List<AssetTypeModel> assetTypes,
  }) {
    return showModalBottomSheet<InvestmentFilterState>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => InvestmentFilterSheet(
        currentFilter: currentFilter,
        assetTypes: assetTypes,
      ),
    );
  }

  @override
  State<InvestmentFilterSheet> createState() => _InvestmentFilterSheetState();
}

class _InvestmentFilterSheetState extends State<InvestmentFilterSheet> {
  late InvestmentSortOption _sortOption;
  late String? _selectedType;
  late String? _selectedAssetTypeId;
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _sortOption = widget.currentFilter.sortOption;
    _selectedType = widget.currentFilter.selectedType;
    _selectedAssetTypeId = widget.currentFilter.selectedAssetTypeId;
    _searchCtrl = TextEditingController(text: widget.currentFilter.searchQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onApply() {
    Navigator.of(context).pop(
      InvestmentFilterState(
        sortOption: _sortOption,
        selectedType: _selectedType,
        selectedAssetTypeId: _selectedAssetTypeId,
        searchQuery: _searchCtrl.text.trim(),
      ),
    );
  }

  void _onReset() {
    setState(() {
      _sortOption = InvestmentSortOption.newest;
      _selectedType = null;
      _selectedAssetTypeId = null;
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Handle ───
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // ─── Title ───
            Text(
              l10n.investmentFilterTitle,
              style: TextStyleConstants.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),

            // ─── Search ───
            SakuTextField(
              controller: _searchCtrl,
              hint: l10n.investmentFilterSearch,
              prefixIcon: FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                size: 14.w,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            // ─── Sort ───
            Text(
              l10n.investmentFilterSort,
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _sortChip(
                  InvestmentSortOption.newest,
                  l10n.investmentFilterSortNewest,
                  colors,
                  isDark,
                ),
                _sortChip(
                  InvestmentSortOption.oldest,
                  l10n.investmentFilterSortOldest,
                  colors,
                  isDark,
                ),
                _sortChip(
                  InvestmentSortOption.highest,
                  l10n.investmentFilterSortHighest,
                  colors,
                  isDark,
                ),
                _sortChip(
                  InvestmentSortOption.lowest,
                  l10n.investmentFilterSortLowest,
                  colors,
                  isDark,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // ─── Type Filter ───
            Text(
              l10n.investmentFilterType,
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All
                  _typeChip(
                    null,
                    l10n.investmentFilterAll,
                    FontAwesomeIcons.layerGroup,
                    colors,
                    isDark,
                  ),
                  SizedBox(width: 8.w),
                  // Gold
                  _typeChip(
                    'gold',
                    l10n.investmentTypeGold,
                    FontAwesomeIcons.coins,
                    colors,
                    isDark,
                  ),
                  SizedBox(width: 8.w),
                  // Crypto
                  _typeChip(
                    'crypto',
                    l10n.investmentTypeBtc,
                    FontAwesomeIcons.bitcoin,
                    colors,
                    isDark,
                  ),
                  // User asset types (custom — individual chips)
                  ...widget.assetTypes.map((at) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _assetTypeChip(at, colors, isDark),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ─── Actions ───
            Row(
              children: [
                Expanded(
                  child: SakuButton(
                    text: l10n.investmentFilterReset,
                    isOutlined: true,
                    onPressed: _onReset,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SakuButton(
                    text: l10n.investmentFilterApply,
                    onPressed: _onApply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(
    InvestmentSortOption option,
    String label,
    dynamic colors,
    bool isDark,
  ) {
    final isSelected = _sortOption == option;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = option),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : colors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.5)
                : colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    String? type,
    String label,
    IconData icon,
    dynamic colors,
    bool isDark,
  ) {
    final isSelected = _selectedType == type && _selectedAssetTypeId == null;
    if (type == null) {
      // "All" chip — selected when no type filter is active.
      return _buildChip(
        label: label,
        icon: icon,
        isSelected: _selectedType == null && _selectedAssetTypeId == null,
        colors: colors,
        isDark: isDark,
        onTap: () => setState(() {
          _selectedType = null;
          _selectedAssetTypeId = null;
        }),
      );
    }
    return _buildChip(
      label: label,
      icon: icon,
      isSelected: isSelected,
      colors: colors,
      isDark: isDark,
      onTap: () => setState(() {
        _selectedType = type;
        _selectedAssetTypeId = null;
      }),
    );
  }

  Widget _assetTypeChip(AssetTypeModel assetType, dynamic colors, bool isDark) {
    final isSelected = _selectedAssetTypeId == assetType.id;
    return _buildChip(
      label: assetType.name,
      icon: FontAwesomeIcons.chartLine,
      isSelected: isSelected,
      colors: colors,
      isDark: isDark,
      onTap: () => setState(() {
        _selectedType = 'custom';
        _selectedAssetTypeId = assetType.id;
      }),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required dynamic colors,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : colors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.5)
                : colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 12.w,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyleConstants.label2.copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
