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
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_multi_manual_coordinator.dart';
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

// ═══════════════════════════════════════════════════════════════════════════
//  TransactionFormActionsMixin — ringkasan
// ═══════════════════════════════════════════════════════════════════════════
//
// Mixin ini memisahkan **aksi pengguna** dari halaman form utama agar
// [transaction_form_page.dart] tidak membengkak dengan sheet, dialog, dan alur simpan.
//
// Pola umum di setiap aksi:
// - Tutup keyboard ([FocusScope.unfocus]) agar sheet tidak tertutup fokus aneh.
// - Baca [transactionFormControllerProvider] untuk state / notifier untuk mutasi.
// - Setelah async ([show]), cek [mounted] sebelum memanggil [setState] implisit lewat provider/context.
//
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin untuk semua **callback UI** pada form transaksi (picker, simpan, hapus).
///
/// **Di-mix ke:** [_TransactionFormPageState] (`transaction_form_page.dart`).
///
/// **Tanggung jawab:**
/// - Membuka bottom sheet (dompet, kategori, lampiran, referensi pelunasan).
/// - Menyimpan transaksi: validasi berlapis → upload lampiran → [submit] → refresh data → navigasi balik.
/// - Menghapus transaksi (mode edit) dengan konfirmasi.
/// - Helper warna tipe transaksi untuk konsistensi tampilan.
///
/// **Yang sengaja TIDAK ada di sini:** pembangunan widget [build], prefill dari OCR/suara,
/// dan logika murni bisnis di [TransactionFormController] — hanya jembatan antara UI dan controller.
///
/// **Callbacks yang dipasang dari [build] halaman:**
/// - [pickWallet], [pickCategory], [pickReferenceTransaction], [pickAttachment],
///   [pickAttachmentForMultiEntry]
/// - [onSave], [onConfirmDelete]
/// - [colorForType]
mixin TransactionFormActionsMixin on ConsumerState<TransactionFormPage> {
  // ─────────────────────────────────────────────
  // Getter abstrak — diisi oleh [TransactionFormPage]
  // ─────────────────────────────────────────────

  /// Kunci form untuk memanggil validasi [FormState.validate] sebelum simpan.
  GlobalKey<FormState> get formKey;

  // ═══════════════════════════════════════════════
  //  Aksi picker (bottom sheet)
  // ═══════════════════════════════════════════════

  /// Membuka pemilih dompet (bottom sheet).
  ///
  /// **Mode form tunggal:**
  /// - [isSource] = `true`  → dompet **sumber** pembayaran / potong saldo.
  /// - [isSource] = `false` → dompet **tujuan** (transfer); picker akan mengExclude dompet sumber agar tidak dobel.
  ///
  /// **Mode multi transaksi manual** ([manualMultiEntryIndex] tidak null):
  /// - Mengisi dompet untuk **satu baris entri** batch saja (indeks ke [manualMultiEntries]).
  /// - [isSource] diabaikan untuk exclusion pola yang sama; yang penting ID dompet terpilih per entri.
  ///
  /// Setelah user memilih, notifier controller di-update ([setWallet], [setDestinationWallet],
  /// atau [setManualMultiEntryWallet]).
  Future<void> pickWallet({
    required bool isSource,
    int? manualMultiEntryIndex,
  }) async {
    FocusScope.of(context).unfocus();
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    // Wallet yang ditampilkan sebagai terpilih di sheet: bedakan batch vs form biasa.
    final result = await SakuWalletPickerSheet.show(
      context,
      selectedWalletId: manualMultiEntryIndex != null
          ? (manualMultiEntryIndex < formState.manualMultiEntries.length
                ? formState.manualMultiEntries[manualMultiEntryIndex].wallet?.id
                : null)
          : (isSource ? formState.wallet?.id : formState.destinationWallet?.id),
      // Transfer: jangan pilih dompet tujuan yang sama dengan sumber.
      excludeWalletId: isSource ? null : formState.wallet?.id,
    );

    if (result != null) {
      if (manualMultiEntryIndex != null) {
        ctrl.setManualMultiEntryWallet(manualMultiEntryIndex, result);
      } else if (isSource) {
        ctrl.setWallet(result);
      } else {
        ctrl.setDestinationWallet(result);
      }
    }
  }

  /// Membuka pemilih kategori (bottom sheet).
  ///
  /// Daftar kategori difilter **expense vs income** mengikuti [TransactionFormState.type].
  /// Untuk entri batch ([manualMultiEntryIndex]), kategori yang di-highlight di sheet diambil dari
  /// entri tersebut (fallback ke [categoryId] pada item pertama jika entri punya multi-item).
  ///
  /// Hasil memanggil [setCategory] (form tunggal) atau [setManualMultiEntryCategory] (batch).
  Future<void> pickCategory({int? manualMultiEntryIndex}) async {
    FocusScope.of(context).unfocus();
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final catType = formState.type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;

    // Tentukan ID kategori untuk highlight — prioritas: entri batch → form tunggal → item pertama.
    String? selectedId;
    if (manualMultiEntryIndex != null &&
        manualMultiEntryIndex < formState.manualMultiEntries.length) {
      final e = formState.manualMultiEntries[manualMultiEntryIndex];
      selectedId =
          e.category?.id ??
          (e.items.isNotEmpty ? e.items.first.categoryId : null);
    } else {
      selectedId =
          formState.category?.id ??
          (formState.items.isNotEmpty
              ? formState.items.first.categoryId
              : null);
    }

    final result = await CategoryPickerSheet.show(
      context: context,
      type: catType,
      selectedId: selectedId,
    );

    if (result != null) {
      if (manualMultiEntryIndex != null) {
        ctrl.setManualMultiEntryCategory(manualMultiEntryIndex, result);
      } else {
        ctrl.setCategory(result);
      }
    }
  }

  /// Memilih gambar lampiran untuk **satu entri** dalam mode multi transaksi manual.
  ///
  /// File disimpan sebagai path lokal di state entri; upload ke storage baru pada [onSave].
  Future<void> pickAttachmentForMultiEntry(int entryIndex) async {
    FocusScope.of(context).unfocus();
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null || !mounted) return;
    ref
        .read(transactionFormControllerProvider.notifier)
        .setManualMultiEntryLocalAttachment(entryIndex, file.path);
  }

  /// Memilih transaksi **referensi** untuk mode pelunasan hutang / penerimaan piutang.
  ///
  /// Hanya relevan jika form dalam mode settlement ([DebtLoanKindEnum.isSettlement]).
  /// Sheet menampilkan daftar transaksi unpaid sesuai [referenceType] (hutang vs piutang).
  ///
  /// Guard di awal: tanpa [debtLoanKind] settlement → tidak membuka sheet (invalid state).
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

  /// Memilih lampiran gambar untuk form transaksi **tunggal** (bukan batch).
  ///
  /// Path lokal disimpan di controller; URL publik diisi setelah [ImageUploadService] pada simpan.
  Future<void> pickAttachment() async {
    FocusScope.of(context).unfocus();
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null || !mounted) return;

    ref
        .read(transactionFormControllerProvider.notifier)
        .setLocalAttachment(file.path);
  }

  // ═══════════════════════════════════════════════
  //  Simpan — alur validasi & submit
  // ═══════════════════════════════════════════════

  /// Menyimpan transaksi: validasi bertingkat, upload lampiran, submit, refresh, pop.
  ///
  /// **Urutan singkat:**
  /// 1. Validasi widget form ([formKey] → fields TextFormField dll.).
  /// 2. Validasi konteks: dompet wajib (kecuali batch yang divalidasi terpisah), transfer butuh tujuan,
  ///    settlement butuh referensi dan nominal ≤ sisa.
  /// 3. [showLoadingOverlay] — blok UI selama IO jaringan.
  /// 4. Upload lampiran (batch: loop per entri yang punya path lokal; tunggal: satu file).
  /// 5. [TransactionFormController.submit] — RPC / REST sesuai mode (edit, batch, tunggal, settlement).
  /// 6. Tutup overlay; sukses → refresh [wallet], [dashboard], [history], snackbar, [pop(true)].
  /// 7. Interstitial iklan (opsional) jika user eligible — tidak menghalangi navigasi sukses.
  ///
  /// **finally:** selalu coba [closeOverlay] agar loading tidak nyangkut setelah error.
  Future<void> onSave() async {
    if (!formKey.currentState!.validate()) return;

    final formState = ref.read(transactionFormControllerProvider);
    final l10n = context.l10n;
    final isMultiBatchSubmit =
        formState.isMultiManualMode && !formState.isEditing;

    // ── Batch create (beberapa transaksi sekaligus, expense/income) ──
    // Dompet/kategori per baris divalidasi di coordinator — pesan error sudah terlokalisasi.
    if (formState.isMultiManualMode && !formState.isEditing) {
      final batchErr = TransactionFormMultiManualCoordinator.validateBatch(
        formState,
        formState.type,
      );
      if (batchErr != null) {
        if (!mounted) return;
        context.showAppAlert(batchErr, alertType: AlertTypeEnum.error);
        return;
      }
    } else if (formState.wallet == null) {
      // Form tunggal / edit: dompet sumber wajib.
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    // ── Transfer: dompet tujuan wajib berbeda dari sumber (exclude sudah di picker). ──
    if (formState.type == TransactionTypeEnum.transfer &&
        formState.destinationWallet == null) {
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionDestWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    // ── Pelunasan hutang / penerimaan piutang: referensi + tidak boleh melebihi sisa ──
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
      // Upload lampiran batch dulu (setiap entri bisa punya file sendiri).
      if (formState.isMultiManualMode && !formState.isEditing) {
        final entries = ref
            .read(transactionFormControllerProvider)
            .manualMultiEntries;
        for (var i = 0; i < entries.length; i++) {
          final path = entries[i].localAttachmentPath;
          if (path == null) continue;
          final url = await _uploadLocalAttachment(path);
          if (!mounted) return;
          if (url != null) {
            ref
                .read(transactionFormControllerProvider.notifier)
                .setManualMultiEntryAttachmentUrl(i, url);
          }
        }
      } else if (formState.localAttachmentPath != null) {
        // Satu lampiran untuk form tunggal.
        final url = await _uploadLocalAttachment(
          formState.localAttachmentPath!,
        );
        if (!mounted) return;
        if (url != null) {
          ref
              .read(transactionFormControllerProvider.notifier)
              .setAttachmentUrl(url);
        }
      }

      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .submit();

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        // Sinkronkan layar lain yang menampilkan saldo / riwayat / ringkasan.
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();

        // Batch: tampilkan jumlah baris tersimpan jika backend mengembalikan count.
        if (isMultiBatchSubmit) {
          final payload = result.dataSuccess();
          final n = (payload != null && payload['count'] is num)
              ? (payload['count'] as num).toInt()
              : 0;
          context.showAppAlert(
            n > 0
                ? l10n.transactionSaveSuccessBatch(n)
                : l10n.transactionSaveSuccess,
            alertType: AlertTypeEnum.success,
          );
        } else {
          context.showAppAlert(
            l10n.transactionSaveSuccess,
            alertType: AlertTypeEnum.success,
          );
        }
        context.pop(true);

        // Iklan interstitial: tidak mem-block navigasi; dipanggil setelah pop.
        if (ref.read(adsEligibleProvider)) {
          await AdsService.instance.incrementAndMaybeShowInterstitial(context);
        }
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      // Jaga-jaga bila exception atau early return sebelum close di atas.
      if (mounted) context.closeOverlay();
    }
  }

  // ═══════════════════════════════════════════════
  //  Hapus transaksi (mode edit)
  // ═══════════════════════════════════════════════

  /// Menghapus transaksi yang sedang diedit setelah dialog konfirmasi.
  ///
  /// Memanggil [TransactionFormController.delete]. Sukses → sama seperti simpan:
  /// refresh provider terkait, snackbar, [pop(true)]. Gagal → pesan error, tetap di halaman.
  ///
  /// **finally:** tutup overlay loading agar tidak tertinggal.
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
  //  Helper upload lampiran
  // ═══════════════════════════════════════════════

  /// Mengompres gambar dari disk lalu mengunggahnya via [ImageUploadService].
  ///
  /// Dipanggil **hanya dari [onSave]** — tidak memblok UI pembukaan form.
  /// Mengembalikan URL publik untuk disimpan ke state sebelum [submit], atau `null` jika kompresi/upload gagal
  /// (submit tetap bisa dipanggil tanpa URL jika controller mengizinkan — perilaku detail ada di controller).
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
  //  Helper warna UI
  // ═══════════════════════════════════════════════

  /// Memetakan [TransactionTypeEnum] ke warna semantik di [AppColorScheme].
  ///
  /// Dipakai di header / FAB / chip agar expense selalu “merah keluar”, income “hijau masuk”, dll.
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
