import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/features/ocr/view/widgets/ocr_detail_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tabel dua kolom tanpa border: label + ikon di kiri, nilai di kanan.
///
/// Dipakai pada sheet hasil OCR untuk merapikan merchant, tanggal, wallet, kategori, dll.
class OcrDetailTable extends StatelessWidget {
  /// [colors] adalah token tema aplikasi (`context.colors`).
  const OcrDetailTable({
    super.key,
    required this.colors,
    required this.rows,
  });

  /// Token warna tema (surface, textPrimary, textSecondary, …).
  final dynamic colors;

  /// Daftar baris; jika kosong widget ini tidak menampilkan apa pun.
  final List<OcrDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: 2.w),
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(1.05),
          1: const FlexColumnWidth(1.35),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (var i = 0; i < rows.length; i++)
            TableRow(
              children: [
                // Sel kiri: ikon + label.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < rows.length - 1 ? 10.h : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: FaIcon(
                          rows[i].icon,
                          size: 13.w,
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          rows[i].label,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Sel kanan: nilai teks.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < rows.length - 1 ? 10.h : 0,
                    left: 6.w,
                  ),
                  child: Text(
                    rows[i].value,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
