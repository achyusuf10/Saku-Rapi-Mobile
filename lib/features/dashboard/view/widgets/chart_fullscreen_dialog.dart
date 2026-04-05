import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Dialog full-screen untuk menampilkan chart (Syncfusion widget)
/// dengan tombol download (share) chart sebagai gambar PNG.
class ChartFullscreenDialog extends StatefulWidget {
  const ChartFullscreenDialog({
    super.key,
    required this.title,
    required this.chartWidget,
  });

  final String title;
  final Widget chartWidget;

  /// Helper untuk membuka dialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget chartWidget,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) =>
          ChartFullscreenDialog(title: title, chartWidget: chartWidget),
    );
  }

  @override
  State<ChartFullscreenDialog> createState() => _ChartFullscreenDialogState();
}

class _ChartFullscreenDialogState extends State<ChartFullscreenDialog> {
  final _repaintKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _downloadChart() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog.fullscreen(
      backgroundColor: colors.background,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: _isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(Icons.download_rounded, color: colors.primary),
              onPressed: _isSaving ? null : _downloadChart,
              tooltip: 'Download',
            ),
            SizedBox(width: 4.w),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: RepaintBoundary(
            key: _repaintKey,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(12.w),
              child: widget.chartWidget,
            ),
          ),
        ),
      ),
    );
  }
}
