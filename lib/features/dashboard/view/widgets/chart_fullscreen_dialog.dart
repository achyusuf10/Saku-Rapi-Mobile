import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/utils/packages/graphify/view/graphify_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Dialog full-screen untuk menampilkan chart dengan dataZoom slider
/// dan tombol download (share) chart sebagai gambar PNG.
class ChartFullscreenDialog extends StatefulWidget {
  const ChartFullscreenDialog({
    super.key,
    required this.title,
    required this.chartOptions,
    required this.isDark,
  });

  final String title;
  final Map<String, dynamic> chartOptions;
  final bool isDark;

  /// Helper untuk membuka dialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> chartOptions,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => ChartFullscreenDialog(
        title: title,
        chartOptions: chartOptions,
        isDark: isDark,
      ),
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
    final isDark = widget.isDark;

    // Clone options and add dataZoom for fullscreen
    final opts = Map<String, dynamic>.from(widget.chartOptions);
    opts['dataZoom'] = [
      {'type': 'inside', 'start': 0, 'end': 100},
      {
        'type': 'slider',
        'start': 0,
        'end': 100,
        'height': 24,
        'bottom': '3%',
        'borderColor': 'transparent',
        'backgroundColor': isDark ? '#1A2420' : '#F3F4F6',
        'fillerColor': isDark ? '#1F2D2880' : '#D1D5DB80',
        'handleSize': '60%',
        'handleStyle': {'color': isDark ? '#34D399' : '#9CA3AF'},
        'textStyle': {'fontSize': 0},
      },
    ];

    // Adjust grid bottom for slider room
    if (opts['grid'] is Map) {
      final grid = Map<String, dynamic>.from(opts['grid'] as Map);
      grid['bottom'] = '18%';
      opts['grid'] = grid;
    }

    return Dialog.fullscreen(
      backgroundColor: colors.background,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
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
              child: GraphifyView(initialOptions: opts, isDarkMode: isDark),
            ),
          ),
        ),
      ),
    );
  }
}
