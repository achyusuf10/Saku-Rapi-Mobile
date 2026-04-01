import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/asset_type_controller.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman form tambah/edit jenis aset kustom.
///
/// Mode tambah: form kosong.
/// Mode edit: form terisi data existing.
class AssetTypeFormPage extends ConsumerStatefulWidget {
  const AssetTypeFormPage({super.key, this.existingAssetType});

  /// Jika diisi, form masuk mode edit.
  final AssetTypeModel? existingAssetType;

  @override
  ConsumerState<AssetTypeFormPage> createState() => _AssetTypeFormPageState();
}

class _AssetTypeFormPageState extends ConsumerState<AssetTypeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _symbolCtrl;
  double _currentPrice = 0;

  bool get _isEditing => widget.existingAssetType != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAssetType;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _symbolCtrl = TextEditingController(text: existing?.symbol ?? '');
    _currentPrice = existing?.currentPrice ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symbolCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final symbol = _symbolCtrl.text.trim();
    final l10n = context.l10n;

    context.showLoadingOverlay();

    try {
      if (_isEditing) {
        final result = await ref
            .read(assetTypeControllerProvider.notifier)
            .updateAssetType(
              id: widget.existingAssetType!.id,
              name: name,
              symbol: symbol.isEmpty ? null : symbol,
              currentPrice: _currentPrice,
            );

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.assetTypeSuccessEdit);
          Navigator.of(context).pop(result.dataSuccess());
        } else {
          final msg = result.dataError()?.$1 ?? '';
          if (msg.startsWith('DUPLICATE:')) {
            final dupName = msg.substring('DUPLICATE:'.length);
            context.showAppAlert(
              l10n.assetTypeErrorDuplicateName(dupName),
              alertType: AlertTypeEnum.error,
            );
          } else {
            context.showAppAlert(l10n.assetTypeErrorEdit);
          }
        }
      } else {
        final result = await ref
            .read(assetTypeControllerProvider.notifier)
            .createAssetType(
              name: name,
              symbol: symbol.isEmpty ? null : symbol,
              currentPrice: _currentPrice,
            );

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.assetTypeSuccessAdd);
          Navigator.of(context).pop(result.dataSuccess());
        } else {
          final msg = result.dataError()?.$1 ?? '';
          if (msg.startsWith('DUPLICATE:')) {
            final dupName = msg.substring('DUPLICATE:'.length);
            context.showAppAlert(
              l10n.assetTypeErrorDuplicateName(dupName),
              alertType: AlertTypeEnum.error,
            );
          } else {
            context.showAppAlert(l10n.assetTypeErrorAdd);
          }
        }
      }
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_isEditing ? l10n.assetTypeEdit : l10n.assetTypeAdd),
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ──
                      SakuTextField(
                        controller: _nameCtrl,
                        label: l10n.assetTypeFormName,
                        hint: l10n.assetTypeFormNameHint,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 50,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.assetTypeFormName;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // ── Symbol ──
                      SakuTextField(
                        controller: _symbolCtrl,
                        label: l10n.assetTypeFormSymbol,
                        hint: l10n.assetTypeFormSymbolHint,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        maxLength: 10,
                      ),
                      SizedBox(height: 16.h),

                      // ── Current Price ──
                      SakuCurrencyField(
                        label: l10n.assetTypeFormCurrentPrice,
                        hint: l10n.assetTypeFormCurrentPriceHint,
                        initialValue: _currentPrice > 0 ? _currentPrice : null,
                        onChanged: (value) {
                          _currentPrice = value;
                        },
                        validator: (value) {
                          if (_currentPrice <= 0) {
                            return l10n.assetTypeFormCurrentPrice;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Save button ──
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: SakuButton(text: l10n.assetTypeSave, onPressed: _onSave),
            ),
          ],
        ),
      ),
    );
  }
}
