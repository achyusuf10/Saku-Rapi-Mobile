import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_detail_row.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Membangun daftar baris ringkasan untuk tabel detail OCR.
///
/// Urutan disesuaikan alur baca struk: merchant → tanggal → wallet transfer
/// atau orang (hutang/piutang) + metode bayar → **kategori di bawah pembayaran**
/// bila [rootCategoryDisplay] tidak null.
List<OcrDetailRow> buildOcrDetailRows({
  required WidgetRef ref,
  required OcrParseResultModel result,
  required dynamic l10n,
  required String? rootCategoryDisplay,
}) {
  // Resolver nama wallet dari UUID (fallback ke UUID jika tidak ketemu).
  String resolveWallet(String id) {
    final wallets = ref.read(walletListProvider);
    return wallets.where((w) => w.id == id).firstOrNull?.name ?? id;
  }

  final rows = <OcrDetailRow>[];

  // Merchant (opsional).
  if (result.merchantName != null && result.merchantName!.isNotEmpty) {
    rows.add(
      OcrDetailRow(
        icon: FontAwesomeIcons.store,
        label: l10n.ocrMerchant as String,
        value: result.merchantName!,
      ),
    );
  }

  // Tanggal transaksi (opsional).
  if (result.date != null) {
    rows.add(
      OcrDetailRow(
        icon: FontAwesomeIcons.calendar,
        label: l10n.ocrDate as String,
        value: result.date!.extToFormattedString(
          outputDateFormat: 'dd MMM yyyy, HH:mm',
        ),
      ),
    );
  }

  // Transfer: sumber dan tujuan dompet.
  if (result.type == 'transfer') {
    if (result.suggestedWalletId != null) {
      rows.add(
        OcrDetailRow(
          icon: FontAwesomeIcons.wallet,
          label: l10n.ocrSourceWallet as String,
          value: resolveWallet(result.suggestedWalletId!),
        ),
      );
    }
    if (result.destinationWalletId != null) {
      rows.add(
        OcrDetailRow(
          icon: FontAwesomeIcons.arrowRight,
          label: l10n.ocrDestWallet as String,
          value: resolveWallet(result.destinationWalletId!),
        ),
      );
    }
  } else {
    // Hutang/piutang: orang terkait (jika ada).
    if ((result.type == 'debt' || result.type == 'loan') &&
        result.withPerson != null) {
      rows.add(
        OcrDetailRow(
          icon: FontAwesomeIcons.user,
          label: l10n.ocrWithPerson as String,
          value: result.withPerson!,
        ),
      );
    }
    // Metode pembayaran / dompet sumber (non-transfer).
    if (result.suggestedWalletId != null) {
      rows.add(
        OcrDetailRow(
          icon: FontAwesomeIcons.creditCard,
          label: l10n.ocrPaymentMethod as String,
          value: resolveWallet(result.suggestedWalletId!),
        ),
      );
    }
  }

  // Kategori root setelah blok pembayaran / wallet.
  if (rootCategoryDisplay != null) {
    rows.add(
      OcrDetailRow(
        icon: FontAwesomeIcons.tag,
        label: l10n.transactionCategory as String,
        value: rootCategoryDisplay,
      ),
    );
  }

  return rows;
}
