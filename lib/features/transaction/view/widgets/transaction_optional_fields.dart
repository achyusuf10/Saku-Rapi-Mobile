import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Bagian "Detail Tambahan" yang dapat diperluas/diciutkan di form transaksi.
///
/// Berisi field-field opsional:
/// - Catatan (note)
/// - Nama merchant
/// - Lampiran foto struk / bukti
///
/// Untuk tipe **debt/loan** juga menampilkan:
/// - Dengan siapa (withPerson) — WAJIB diisi
/// - Status (unpaid / paid)
/// - Tanggal jatuh tempo (due_date)
///
/// Untuk tipe **debt/loan** juga menampilkan toggle Hutang ↔ Piutang.
class TransactionOptionalFields extends ConsumerStatefulWidget {
  const TransactionOptionalFields({super.key});

  @override
  ConsumerState<TransactionOptionalFields> createState() =>
      _TransactionOptionalFieldsState();
}

class _TransactionOptionalFieldsState
    extends ConsumerState<TransactionOptionalFields> {
  final _noteCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _withPersonCtrl = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _merchantCtrl.dispose();
    _withPersonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    ref
        .read(transactionFormControllerProvider.notifier)
        .setAttachmentLocalPath(file.path);
  }

  Future<void> _pickDueDate() async {
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    final current = ref.read(transactionFormControllerProvider).dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) notifier.setDueDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(transactionFormControllerProvider);
    final notifier = ref.read(transactionFormControllerProvider.notifier);
    final isDebtOrLoan = state.isDebtOrLoan;

    // Sync external controller texts only on first reveal or type change
    // (one-way: controller → UI, UI → notifier)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Debt/Loan sub-type toggle ──────────────────────────────
        if (isDebtOrLoan) ...[
          _buildDebtTypeToggle(appColors, l10n, state, notifier),
          SizedBox(height: 10.h),
          _buildWithPersonField(appColors, l10n, state, notifier),
          SizedBox(height: 10.h),
          _buildStatusRow(appColors, l10n, state, notifier),
          SizedBox(height: 10.h),
          _buildDueDateRow(appColors, l10n, state),
          SizedBox(height: 10.h),
        ],

        // ── Expandable optional section ────────────────────────────
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: appColors.border),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.sliders,
                  size: 14.r,
                  color: appColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    l10n.transactionOptionalFields,
                    style: TextStyleConstants.b2.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: FaIcon(
                    FontAwesomeIcons.chevronDown,
                    size: 12.r,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expanded content ────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Note field
                _buildLabeledField(
                  appColors,
                  label: l10n.transactionNote,
                  child: TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (v) => notifier.setNote(v.isEmpty ? null : v),
                    style: TextStyleConstants.b2.copyWith(
                      color: appColors.textPrimary,
                    ),
                    decoration: _inputDeco(appColors, l10n.transactionNote),
                  ),
                ),
                SizedBox(height: 10.h),
                // Merchant name
                _buildLabeledField(
                  appColors,
                  label: l10n.transactionMerchant,
                  child: TextField(
                    controller: _merchantCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) =>
                        notifier.setMerchantName(v.isEmpty ? null : v),
                    style: TextStyleConstants.b2.copyWith(
                      color: appColors.textPrimary,
                    ),
                    decoration: _inputDeco(
                      appColors,
                      l10n.transactionMerchantHint,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                // Attachment
                _buildAttachmentRow(appColors, l10n, state, notifier),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDebtTypeToggle(
    dynamic appColors,
    dynamic l10n,
    dynamic state,
    dynamic notifier,
  ) {
    final isDebt = state.type == 'debt';
    return Row(
      children: [
        Expanded(
          child: _debtTypeChip(
            label: l10n.transactionDebt,
            isSelected: isDebt,
            appColors: appColors,
            onTap: () => notifier.setType('debt'),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _debtTypeChip(
            label: l10n.transactionLoan,
            isSelected: !isDebt,
            appColors: appColors,
            onTap: () => notifier.setType('loan'),
          ),
        ),
      ],
    );
  }

  Widget _debtTypeChip({
    required String label,
    required bool isSelected,
    required dynamic appColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.debt.withValues(alpha: 0.15)
              : appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? appColors.debt : appColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? appColors.debt : appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithPersonField(
    dynamic appColors,
    dynamic l10n,
    dynamic state,
    dynamic notifier,
  ) {
    // Sync initial value once
    if (_withPersonCtrl.text.isEmpty &&
        (state.withPerson?.isNotEmpty ?? false)) {
      _withPersonCtrl.text = state.withPerson!;
    }
    return _buildLabeledField(
      appColors,
      label: '${l10n.transactionWithPerson} *',
      child: TextField(
        controller: _withPersonCtrl,
        textCapitalization: TextCapitalization.words,
        onChanged: (v) => notifier.setWithPerson(v.isEmpty ? null : v),
        style: TextStyleConstants.b2.copyWith(color: appColors.textPrimary),
        decoration: _inputDeco(appColors, l10n.transactionWithPersonHint),
      ),
    );
  }

  Widget _buildStatusRow(
    dynamic appColors,
    dynamic l10n,
    dynamic state,
    dynamic notifier,
  ) {
    final isUnpaid = (state.status ?? 'unpaid') == 'unpaid';
    return _buildLabeledField(
      appColors,
      label: l10n.transactionDebtStatus,
      child: Row(
        children: [
          Expanded(
            child: _statusChip(
              appColors: appColors,
              label: l10n.transactionUnpaid,
              isSelected: isUnpaid,
              onTap: () => notifier.setStatus('unpaid'),
              selectedColor: appColors.expense,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _statusChip(
              appColors: appColors,
              label: l10n.transactionPaid,
              isSelected: !isUnpaid,
              onTap: () => notifier.setStatus('paid'),
              selectedColor: appColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required dynamic appColors,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.12)
              : appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? selectedColor : appColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? selectedColor : appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateRow(dynamic appColors, dynamic l10n, dynamic state) {
    final dueDate = state.dueDate;
    return _buildLabeledField(
      appColors,
      label: l10n.transactionDueDate,
      child: InkWell(
        onTap: _pickDueDate,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: appColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: appColors.border),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.calendarCheck,
                size: 14.r,
                color: dueDate != null
                    ? appColors.primary
                    : appColors.textSecondary,
              ),
              SizedBox(width: 8.w),
              Text(
                dueDate != null
                    ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
                    : '-',
                style: TextStyleConstants.b2.copyWith(
                  color: dueDate != null
                      ? appColors.textPrimary
                      : appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentRow(
    dynamic appColors,
    dynamic l10n,
    dynamic state,
    dynamic notifier,
  ) {
    final hasAttachment = state.attachmentLocalPath != null;
    return _buildLabeledField(
      appColors,
      label: l10n.transactionAttachment,
      child: GestureDetector(
        onTap: _pickAttachment,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: hasAttachment
                ? appColors.primary.withValues(alpha: 0.08)
                : appColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: hasAttachment ? appColors.primary : appColors.border,
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.image,
                size: 14.r,
                color: hasAttachment
                    ? appColors.primary
                    : appColors.textSecondary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  hasAttachment
                      ? l10n.transactionAttachmentChange
                      : l10n.transactionAttachmentAdd,
                  style: TextStyleConstants.b2.copyWith(
                    color: hasAttachment
                        ? appColors.primary
                        : appColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasAttachment)
                GestureDetector(
                  onTap: () => notifier.setAttachmentLocalPath(null),
                  child: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 12.r,
                    color: appColors.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    dynamic appColors, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }

  InputDecoration _inputDeco(dynamic appColors, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyleConstants.b2.copyWith(
        color: appColors.textSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: appColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      isDense: true,
    );
  }
}
