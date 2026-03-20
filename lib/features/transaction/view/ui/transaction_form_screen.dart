import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/extensions/string_ext.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_settings_controller.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_amount_field.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_date_picker.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_list.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_optional_fields.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_type_tab_bar.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_wallet_picker.dart';
import 'package:app_saku_rapi/global/services/notification_service.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Layar form input transaksi manual.
///
/// Mendukung semua tipe transaksi:
/// - Expense (single & multi-item)
/// - Income
/// - Transfer
/// - Debt / Loan
///
/// Dapat menerima [initialState] untuk pre-fill dari Voice/OCR.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.initialState});

  /// State awal form (dari Voice/OCR pipeline atau edit transaksi).
  final TransactionFormState? initialState;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();

    // Pre-fill dari Voice/OCR jika ada
    if (widget.initialState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(transactionFormControllerProvider.notifier)
            .initialize(widget.initialState!);
        final initialAmt = widget.initialState!.singleAmount;
        if (initialAmt != null && initialAmt > 0) {
          _amountCtrl.text = initialAmt.toInt().toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Color helper
  // ─────────────────────────────────────────────────────────────

  Color _typeColor(BuildContext ctx, String type) {
    final c = ctx.colors;
    return switch (type) {
      'expense' => c.expense,
      'income' => c.income,
      'transfer' => c.transfer,
      'debt' || 'loan' => c.debt,
      'adjustment' => c.primary,
      _ => c.primary,
    };
  }

  // ─────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    final l10n = context.l10n;

    // Sync single amount if in single-item mode
    final state = ref.read(transactionFormControllerProvider);
    if (!state.isMultiItem) {
      final amt = double.tryParse(_amountCtrl.text.trim());
      notifier.updateItemAmount(0, amt);
    }

    final error = notifier.validate();
    if (error != null) {
      context.showAppAlert(_errorMessage(context.l10n, error));
      return;
    }

    context.showLoadingOverlay();
    try {
      final result = await notifier.save();
      result.map(
        success: (savedData) {
          context.closeOverlay();
          // Jadwalkan debt reminder jika tipe loan dengan due_date
          _scheduleDebtReminderIfNeeded(savedData.data);
          context.showAppAlert(l10n.transactionSaveSuccess);
          Navigator.of(context).pop(true);
        },
        error: (err) {
          context.closeOverlay();
          context.showAppAlert(
            err.message.extEmptyNullReplacement(
              replacement: l10n.transactionErrorSave,
            ),
            alertType: AlertTypeEnum.error,
          );
        },
      );
    } catch (_) {
      context.closeOverlay();
      context.showAppAlert(
        l10n.transactionErrorSave,
        alertType: AlertTypeEnum.error,
      );
    }
  }

  String _errorMessage(dynamic l10n, String key) {
    return switch (key) {
      'walletRequired' => l10n.transactionWalletRequired,
      'destWalletRequired' => l10n.transactionDestWalletRequired,
      'sameWallet' => l10n.transactionSameWalletError,
      'withPersonRequired' => l10n.transactionWithPersonRequired,
      'amountRequired' => l10n.transactionAmountRequired,
      _ => key,
    };
  }

  // ─────────────────────────────────────────────────────────────
  // Debt Reminder
  // ─────────────────────────────────────────────────────────────

  /// Jadwalkan pengingat piutang jika transaksi adalah tipe `loan`
  /// dan memiliki `due_date`.
  void _scheduleDebtReminderIfNeeded(TransactionModel savedTransaction) {
    final formState = ref.read(transactionFormControllerProvider);
    if (formState.type != 'loan') return;
    final dueDate = formState.dueDate;
    if (dueDate == null) return;
    final personName = formState.withPerson ?? '';
    final amount = formState.totalAmount;
    final transactionId = savedTransaction.id;

    // Ambil settings menggunakan valueOrNull agar tidak blocking
    final notifSettings = ref
        .read(notificationSettingsControllerProvider)
        .value;
    final isEnabled = notifSettings?.debtReminderEnabled ?? true;
    if (!isEnabled) return;

    final daysBefore = notifSettings?.debtReminderDaysBefore ?? 3;

    NotificationService().scheduleDebtReminder(
      transactionId: transactionId,
      personName: personName,
      amount: amount,
      dueDate: dueDate,
      daysBefore: daysBefore,
      title: 'Pengingat Piutang',
      body: 'Piutang ke $personName jatuh tempo $daysBefore hari lagi',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Wallet picker callbacks
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickSourceWallet() async {
    final state = ref.read(transactionFormControllerProvider);
    final wallet = await TransactionWalletPicker.show(
      context,
      selectedId: state.walletId,
    );
    if (!mounted || wallet == null) return;
    ref
        .read(transactionFormControllerProvider.notifier)
        .setWallet(wallet.id, wallet.name);
  }

  Future<void> _pickDestWallet() async {
    final state = ref.read(transactionFormControllerProvider);
    final wallet = await TransactionWalletPicker.show(
      context,
      selectedId: state.destinationWalletId,
      excludeWalletId: state.walletId,
    );
    if (!mounted || wallet == null) return;
    ref
        .read(transactionFormControllerProvider.notifier)
        .setDestinationWallet(wallet.id, wallet.name);
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormControllerProvider);
    final categoriesAsync = ref.watch(transactionCategoriesProvider);
    final appColors = context.colors;
    final l10n = context.l10n;
    final typeColor = _typeColor(context, state.type);

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(l10n.transactionNewTitle),
        centerTitle: true,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.xmark,
            size: 18.r,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pre-fill badge ───────────────────────────────────
            if (state.prefillSource != null) ...[
              _PrefillBadge(source: state.prefillSource!),
              SizedBox(height: 10.h),
            ],

            // ── Type tabs ────────────────────────────────────────
            TransactionTypeTabBar(
              currentType: state.type,
              onTypeChanged: (type) {
                ref
                    .read(transactionFormControllerProvider.notifier)
                    .setType(type);
              },
            ),
            SizedBox(height: 16.h),

            // ── Amount (single-item or hidden for multi-item) ─────
            if (!state.isMultiItem) ...[
              TransactionAmountField(
                controller: _amountCtrl,
                typeColor: typeColor,
                onChanged: (v) {
                  final amt = double.tryParse(v);
                  ref
                      .read(transactionFormControllerProvider.notifier)
                      .updateItemAmount(0, amt);
                },
              ),
              SizedBox(height: 12.h),

              // ── Single item category picker ──────────────────
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => _SingleCategoryRow(
                  categories: categories,
                  state: state,
                  typeColor: typeColor,
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // ── Source wallet ─────────────────────────────────────
            _WalletRow(
              label: state.isTransfer
                  ? l10n.transactionSourceWallet
                  : l10n.transactionWallet,
              walletName: state.walletName,
              icon: FontAwesomeIcons.wallet,
              onTap: _pickSourceWallet,
            ),
            SizedBox(height: 10.h),

            // ── Destination wallet (transfer only) ────────────────
            if (state.isTransfer) ...[
              _WalletRow(
                label: l10n.transactionDestWallet,
                walletName: state.destinationWalletName,
                icon: FontAwesomeIcons.arrowRight,
                onTap: _pickDestWallet,
              ),
              SizedBox(height: 10.h),
            ],

            // ── Date picker ───────────────────────────────────────
            TransactionDatePicker(
              selectedDate: state.date,
              onDateSelected: (date) => ref
                  .read(transactionFormControllerProvider.notifier)
                  .setDate(date),
            ),
            SizedBox(height: 12.h),

            // ── Multi-item toggle (expense only) ──────────────────
            if (state.type == 'expense') ...[
              _MultiItemToggle(typeColor: typeColor),
              SizedBox(height: 12.h),
            ],

            // ── Multi-item list ───────────────────────────────────
            if (state.isMultiItem)
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => TransactionMultiItemList(
                  categories: categories,
                  typeColor: typeColor,
                ),
              ),

            SizedBox(height: 8.h),

            // ── Optional fields (note, attachment, debt fields) ───
            const TransactionOptionalFields(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: SizedBox(
            width: double.infinity,
            child: SakuButton(text: l10n.transactionSave, onPressed: _onSave),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────

/// Badge kecil yang menampilkan sumber pre-fill (Voice / OCR).
class _PrefillBadge extends StatelessWidget {
  const _PrefillBadge({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final label = source == 'voice'
        ? l10n.transactionPrefilledFromVoice
        : l10n.transactionPrefilledFromOcr;
    final icon = source == 'voice'
        ? FontAwesomeIcons.microphone
        : FontAwesomeIcons.fileImage;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: appColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: appColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12.r, color: appColors.accent),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyleConstants.label2.copyWith(
              color: appColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip kategori single-item di bawah amount field.
class _SingleCategoryRow extends ConsumerWidget {
  const _SingleCategoryRow({
    required this.categories,
    required this.state,
    required this.typeColor,
  });

  final List<CategoryModel> categories;
  final TransactionFormState state;
  final Color typeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final hasCategory =
        state.items.isNotEmpty && state.items.first.categoryId != null;
    final item = state.items.isNotEmpty ? state.items.first : null;

    Color catColor = const Color(0xFF6B7280);
    if (item?.categoryColor != null) {
      final hex = item!.categoryColor!.replaceAll('#', '');
      if (hex.length == 6) {
        catColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    return GestureDetector(
      onTap: () async {
        final cat = await TransactionCategoryPicker.show(
          context,
          categories: categories,
          selectedId: state.items.isNotEmpty
              ? state.items.first.categoryId
              : null,
          filterType: state.type == 'income' || state.type == 'expense'
              ? state.type
              : null,
        );
        if (cat == null) return;
        ref
            .read(transactionFormControllerProvider.notifier)
            .updateItemCategory(
              0,
              categoryId: cat.id,
              categoryName: cat.name,
              categoryColor: cat.color,
              categoryIcon: cat.icon,
            );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: hasCategory
              ? catColor.withValues(alpha: 0.1)
              : appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: hasCategory ? catColor : appColors.border),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.tag,
              size: 14.r,
              color: hasCategory ? catColor : appColors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                item?.categoryName ?? l10n.transactionSelectCategory,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: hasCategory ? FontWeight.w600 : FontWeight.w400,
                  color: hasCategory
                      ? appColors.textPrimary
                      : appColors.textSecondary,
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris pemilih dompet dengan label, nama wallet, dan chevron.
class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.label,
    required this.walletName,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? walletName;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final hasWallet = walletName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: hasWallet
              ? appColors.primary.withValues(alpha: 0.06)
              : appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasWallet ? appColors.primary : appColors.border,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 16.r,
              color: hasWallet ? appColors.primary : appColors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyleConstants.label2.copyWith(
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    walletName ?? context.l10n.transactionSelectWallet,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: hasWallet ? FontWeight.w600 : FontWeight.w400,
                      color: hasWallet
                          ? appColors.textPrimary
                          : appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.r,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle antara single-item dan multi-item (hanya untuk expense).
class _MultiItemToggle extends ConsumerWidget {
  const _MultiItemToggle({required this.typeColor});

  final Color typeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider);
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    final appColors = context.colors;
    final l10n = context.l10n;

    return InkWell(
      onTap: () {
        if (state.isMultiItem) {
          // Reset ke single item
          notifier.removeItem(state.items.length - 1);
          for (var i = state.items.length - 2; i > 0; i--) {
            notifier.removeItem(i);
          }
        } else {
          notifier.addItem();
        }
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20.r,
            height: 20.r,
            decoration: BoxDecoration(
              color: state.isMultiItem ? typeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(
                color: state.isMultiItem ? typeColor : appColors.border,
                width: 1.5,
              ),
            ),
            child: state.isMultiItem
                ? FaIcon(
                    FontAwesomeIcons.check,
                    size: 10.r,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: 8.w),
          Text(
            l10n.transactionMultiItemToggle,
            style: TextStyleConstants.b2.copyWith(
              color: appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
