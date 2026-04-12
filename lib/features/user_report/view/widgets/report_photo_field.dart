import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/user_report/controllers/send_report_controller.dart';
import 'package:app_saku_rapi/global/widgets/image_source_picker_sheet.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget field foto lampiran untuk form kirim laporan.
///
/// Flow:
/// 1. Tap "Tambah Foto" → [ImageSourcePickerSheet]
/// 2. Pilih file → crop dengan croppy
/// 3. Simpan ke local state controller
///
/// Menampilkan thumbnail foto jika sudah ada, lengkap dengan
/// tombol ganti (edit) dan hapus (x).
class ReportPhotoField extends ConsumerWidget {
  const ReportPhotoField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final croppedFile = ref.watch(
      sendReportControllerProvider.select((s) => s.croppedFile),
    );
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.sendReportPhoto,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        if (croppedFile == null)
          _AddPhotoPlaceholder(onTap: () => _pickAndCrop(context, ref))
        else
          _PhotoPreview(
            file: croppedFile,
            onEdit: () => _pickAndCrop(context, ref),
            onRemove: () =>
                ref.read(sendReportControllerProvider.notifier).removePhoto(),
          ),
      ],
    );
  }

  Future<void> _pickAndCrop(BuildContext context, WidgetRef ref) async {
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null) return;
    if (!context.mounted) return;

    final result = await showAdaptiveImageCropper(
      appContext ?? context,
      imageProvider: FileImage(file),
    );
    if (result == null) return;

    final byteData = await result.uiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return;

    final tempFile = File(
      '${file.parent.path}/report_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    ref.read(sendReportControllerProvider.notifier).setPhoto(tempFile);
  }
}

// ─────────────────────────────────────────────────────────────

/// Placeholder "Tambah Foto" saat belum ada foto.
class _AddPhotoPlaceholder extends StatelessWidget {
  const _AddPhotoPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: colors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.image,
                  size: 18.w,
                  color: colors.primary,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.sendReportAddPhoto,
              style: TextStyleConstants.b2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Preview thumbnail foto yang sudah dipilih.
///
/// Menampilkan gambar penuh dengan tombol edit dan hapus di pojok kanan atas.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.file,
    required this.onEdit,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        children: [
          // Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // Action buttons (top-right)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Row(
              children: [
                _ActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  tooltip: l10n.sendReportChangePhoto,
                  onTap: onEdit,
                  color: colors.info,
                ),
                SizedBox(width: 8.w),
                _ActionButton(
                  icon: FontAwesomeIcons.xmark,
                  tooltip: l10n.sendReportRemovePhoto,
                  onTap: onRemove,
                  color: colors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol aksi kecil di atas foto (edit / hapus).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(icon, size: 14.w, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
