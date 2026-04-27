import 'package:app_saku_rapi/core/ads/ads_eligibility_provider.dart';
import 'package:app_saku_rapi/core/ads/ads_service.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/unpaid_transaction_picker_sheet.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/services/image_upload_service.dart';
import 'package:app_saku_rapi/global/widgets/image_source_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_sheet.dart';
import 'package:app_saku_rapi/utils/function/compress_image_func.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'transaction_form_page.dart';

// ═══════════════════════════════════════════════
//  TransactionFormActionsMixin
// ═══════════════════════════════════════════════

/// Mixin yang menangani seluruh aksi pengguna pada form transaksi.
///
/// Di-mix ke [_TransactionFormPageState] agar kelas utama tetap
/// fokus pada [build] dan lifecycle — bukan logika bisnis UI.
///
/// Aksi yang tersedia (dipakai sebagai callback di [build]):
/// - [pickWallet]               — buka picker dompet sumber / tujuan
/// - [pickCategory]             — buka picker kategori
/// - [pickReferenceTransaction] — buka picker transaksi referensi (settlement)
/// - [pickAttachment]           — pilih gambar lampiran dari kamera/galeri
/// - [onSave]                   — validasi + submit form
/// - [onConfirmDelete]          — konfirmasi + hapus transaksi
/// - [colorForType]             — mapping tipe → warna tema
mixin TransactionFormActionsMixin on ConsumerState<TransactionFormPage> {
  // ─── Abstract getters ───
  // Harus diimplementasikan oleh class yang menggunakan mixin ini.

  /// GlobalKey form untuk memanggil [FormState.validate].
  GlobalKey<FormState> get formKey;

  // ═══════════════════════════════════════════════
  //  Picker Actions
  // ═══════════════════════════════════════════════

  /// Buka bottom sheet picker dompet.
  ///
  /// [isSource] = true  → picker dompet sumber (exclude dompet tujuan).
  /// [isSource] = false → picker dompet tujuan (exclude dompet sumber).
  Future<void> pickWallet({required bool isSource}) async {
    FocusScope.of(context).unfocus();
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final result = await SakuWalletPickerSheet.show(
      context,
      selectedWalletId: isSource
          ? formState.wallet?.id
          : formState.destinationWallet?.id,
      // Cegah memilih dompet yang sama untuk sumber & tujuan
      excludeWalletId: isSource ? null : formState.wallet?.id,
    );

    if (result != null) {
      if (isSource) {
        ctrl.setWallet(result);
      } else {
        ctrl.setDestinationWallet(result);
      }
    }
  }

  /// Buka bottom sheet picker kategori.
  ///
  /// Tipe kategori (expense/income) mengikuti tipe transaksi aktif.
  /// Kategori yang sedang terpilih di-highlight sebagai selected.
  Future<void> pickCategory() async {
    FocusScope.of(context).unfocus();
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final catType = formState.type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;

    // Gunakan kategori yang sudah dipilih, atau fallback dari item pertama
    final selectedId =
        formState.category?.id ??
        (formState.items.isNotEmpty ? formState.items.first.categoryId : null);

    final result = await CategoryPickerSheet.show(
      context: context,
      type: catType,
      selectedId: selectedId,
    );

    if (result != null) ctrl.setCategory(result);
  }

  /// Buka bottom sheet picker transaksi yang belum dilunasi (mode settlement).
  ///
  /// Hanya aktif jika [TransactionFormState.isSettlementMode] = true.
  /// Tipe transaksi yang ditampilkan mengikuti [DebtLoanKindEnum.referenceType].
  Future<void> pickReferenceTransaction(TransactionFormState formState) async {
    FocusScope.of(context).unfocus();
    final subCat = formState.debtLoanKind;
    if (subCat == null || !subCat.isSettlement) return;

    final result = await UnpaidTransactionPickerSheet.show(
      context,
      type: subCat.referenceType,
      selectedId: formState.referenceTransaction?.id,
    );

    if (result != null && mounted) {
      ref
          .read(transactionFormControllerProvider.notifier)
          .setReferenceTransaction(result);
    }
  }

  /// Pilih gambar lampiran dari kamera atau galeri.
  ///
  /// Gambar disimpan sebagai local path — upload dilakukan lazy saat simpan.
  Future<void> pickAttachment() async {
    FocusScope.of(context).unfocus();
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null || !mounted) return;

    ref
        .read(transactionFormControllerProvider.notifier)
        .setLocalAttachment(file.path);
  }

  // ═══════════════════════════════════════════════
  //  Save Action
  // ═══════════════════════════════════════════════

  /// Validasi form lalu submit ke backend via controller.
  ///
  /// Urutan proses:
  /// 1. Validasi form widget ([FormState.validate])
  /// 2. Validasi UI (wallet wajib, dest wallet wajib untuk transfer)
  /// 3. Validasi settlement (referensi wajib, amount ≤ sisa)
  /// 4. Upload lampiran lokal jika ada
  /// 5. Submit via [TransactionFormController.submit]
  /// 6. Refresh wallet/dashboard/history lalu pop halaman
  /// 7. Tampilkan interstitial ad jika eligible
  Future<void> onSave() async {
    if (!formKey.currentState!.validate()) return;

    final formState = ref.read(transactionFormControllerProvider);
    final l10n = context.l10n;

    // ── Validasi: wallet sumber wajib ──
    if (formState.wallet == null) {
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    // ── Validasi: wallet tujuan wajib untuk transfer ──
    if (formState.type == TransactionTypeEnum.transfer &&
        formState.destinationWallet == null) {
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionDestWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    // ── Validasi khusus settlement ──
    if (formState.isSettlementMode) {
      if (formState.referenceTransaction == null) {
        if (!mounted) return;
        context.showAppAlert(
          l10n.debtLoanFormPickTransaction,
          alertType: AlertTypeEnum.error,
        );
        return;
      }

      final remaining = formState.referenceTransaction!.remaining;
      if (formState.totalAmount > remaining) {
        if (!mounted) return;
        context.showAppAlert(
          l10n.debtLoanFormAmountExceedsRemaining(remaining.toCurrency()),
          alertType: AlertTypeEnum.error,
        );
        return;
      }
    }

    context.showLoadingOverlay();

    try {
      // Upload lampiran lokal jika ada (lazy upload sebelum simpan)
      if (formState.localAttachmentPath != null) {
        final url = await _uploadLocalAttachment(
          formState.localAttachmentPath!,
        );
        if (!mounted) return;
        if (url != null) {
          // Update URL di state sebelum submit agar tersimpan ke DB
          ref
              .read(transactionFormControllerProvider.notifier)
              .setAttachmentUrl(url);
        }
        // Jika upload gagal, tetap lanjut simpan tanpa lampiran
      }

      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .submit();

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        // Refresh semua data yang terpengaruh oleh transaksi baru/edit
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();

        context.showAppAlert(
          l10n.transactionSaveSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);

        // Tampilkan interstitial ad setiap N simpan, hanya jika eligible
        if (ref.read(adsEligibleProvider)) {
          await AdsService.instance.incrementAndMaybeShowInterstitial(context);
        }
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      // Pastikan overlay selalu ditutup meski terjadi error
      if (mounted) context.closeOverlay();
    }
  }

  // ═══════════════════════════════════════════════
  //  Delete Action
  // ═══════════════════════════════════════════════

  /// Tampilkan dialog konfirmasi lalu hapus transaksi (mode edit saja).
  ///
  /// Setelah hapus berhasil: refresh wallet/dashboard/history dan pop halaman.
  Future<void> onConfirmDelete() async {
    if (!mounted) return;
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.transactionDeleteConfirmTitle,
      message: l10n.transactionDeleteConfirmMessage,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .delete();

      if (!mounted) return;

      if (result.isSuccess()) {
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();
        context.closeOverlay();
        context.showAppAlert(
          l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);
      } else {
        context.closeOverlay();
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  // ═══════════════════════════════════════════════
  //  Upload Helper
  // ═══════════════════════════════════════════════

  /// Kompres gambar lalu upload ke Supabase Storage.
  ///
  /// Mengembalikan URL publik jika berhasil, atau null jika gagal.
  /// Dipanggil dari [onSave] sebelum submit transaksi ke DB.
  Future<String?> _uploadLocalAttachment(String localPath) async {
    final compressed = await CompressImageFunc.call(filePath: localPath);
    if (compressed == null) return null;

    final service = ImageUploadService();
    final result = await service.uploadImage(
      imageBytes: compressed,
      fileName: 'attachment.jpg',
    );

    if (result.isSuccess()) return result.dataSuccess()!;
    return null;
  }

  // ═══════════════════════════════════════════════
  //  UI Helper
  // ═══════════════════════════════════════════════

  /// Kembalikan warna tema yang sesuai untuk tipe transaksi yang diberikan.
  ///
  /// Digunakan di [build] untuk konsistensi warna tombol, ikon, dan aksen.
  Color colorForType(TransactionTypeEnum type, AppColorScheme colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}
