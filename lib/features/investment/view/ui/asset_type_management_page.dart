import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/asset_type_controller.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/features/investment/view/ui/asset_type_form_page.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman kelola jenis aset kustom (CRUD).
///
/// Menampilkan daftar jenis aset yang aktif.
/// User bisa tambah, edit, atau soft-delete jenis aset dari sini.
class AssetTypeManagementPage extends ConsumerStatefulWidget {
  const AssetTypeManagementPage({super.key});

  @override
  ConsumerState<AssetTypeManagementPage> createState() =>
      _AssetTypeManagementPageState();
}

class _AssetTypeManagementPageState
    extends ConsumerState<AssetTypeManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(assetTypeControllerProvider.notifier).loadAssetTypes();
    });
  }

  void _onAddTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AssetTypeFormPage()));
  }

  void _onEditTap(AssetTypeModel assetType) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssetTypeFormPage(existingAssetType: assetType),
      ),
    );
  }

  Future<void> _onDeleteTap(AssetTypeModel assetType) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.assetTypeDeleteConfirmTitle,
      message: l10n.assetTypeDeleteConfirmMessage(assetType.name),
    );

    if (confirmed != true || !mounted) return;

    context.showLoadingOverlay();
    try {
      final result = await ref
          .read(assetTypeControllerProvider.notifier)
          .deleteAssetType(assetType.id);

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        context.showAppAlert(l10n.assetTypeSuccessDelete);
      } else {
        context.showAppAlert(l10n.assetTypeErrorDelete);
      }
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(assetTypeControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.assetTypeTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTap,
        backgroundColor: colors.primary,
        child: FaIcon(
          FontAwesomeIcons.plus,
          color: colors.onPrimary,
          size: 18.w,
        ),
      ),
      body: _buildBody(state, l10n),
    );
  }

  Widget _buildBody(AssetTypeState state, dynamic l10n) {
    if (state.isLoading && state.assetTypes.isEmpty) {
      return const Center(child: SakuLoadingIndicator());
    }

    if (state.status == AssetTypeStatus.error && state.assetTypes.isEmpty) {
      return Center(
        child: SakuErrorState(
          message: state.errorMessage ?? l10n.assetTypeErrorAdd,
          onRetry: () {
            ref.read(assetTypeControllerProvider.notifier).loadAssetTypes();
          },
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.layerGroup,
          title: l10n.assetTypeEmpty,
          message: l10n.assetTypeEmptyHint,
          actionLabel: l10n.assetTypeAdd,
          onAction: _onAddTap,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: state.assetTypes.length,
      itemBuilder: (context, index) {
        final assetType = state.assetTypes[index];
        return _AssetTypeCard(
          assetType: assetType,
          onEdit: () => _onEditTap(assetType),
          onDelete: () => _onDeleteTap(assetType),
        );
      },
    );
  }
}

/// Card untuk satu jenis aset.
class _AssetTypeCard extends StatelessWidget {
  const _AssetTypeCard({
    required this.assetType,
    required this.onEdit,
    required this.onDelete,
  });

  final AssetTypeModel assetType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SakuCard(
      onTap: onEdit,
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.chartLine,
                size: 18.w,
                color: colors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Name + Symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetType.name,
                  style: TextStyleConstants.b1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    if (assetType.symbol != null &&
                        assetType.symbol!.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          assetType.symbol!,
                          style: TextStyleConstants.label3.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      assetType.currentPrice.toCurrency(),
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onDelete,
            tooltip: l10n.investmentDelete,
            icon: FaIcon(
              FontAwesomeIcons.trash,
              size: 14.w,
              color: colors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
