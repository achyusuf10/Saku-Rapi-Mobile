import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Shows a full-screen image preview dialog with pinch-to-zoom support.
///
/// At least one of [localPath] or [networkUrl] must be provided.
/// Optional [heroTag] enables a Hero animation from the source widget.
void showSakuImagePreview(
  BuildContext context, {
  String? localPath,
  String? networkUrl,
  String? heroTag,
}) {
  assert(
    localPath != null || networkUrl != null,
    'Provide at least localPath or networkUrl',
  );
  showDialog<void>(
    context: context,
    builder: (_) => SakuImagePreviewDialog(
      localPath: localPath,
      networkUrl: networkUrl,
      heroTag: heroTag,
    ),
  );
}

/// Full-screen image preview dialog.
///
/// Supports:
/// - [localPath]: local file path (e.g. freshly picked photo)
/// - [networkUrl]: remote URL (e.g. uploaded attachment)
/// - [heroTag]: optional Hero animation tag from the thumbnail
///
/// Features pinch-to-zoom via [InteractiveViewer] and a close button.
class SakuImagePreviewDialog extends StatelessWidget {
  const SakuImagePreviewDialog({
    super.key,
    this.localPath,
    this.networkUrl,
    this.heroTag,
  }) : assert(
          localPath != null || networkUrl != null,
          'Provide at least localPath or networkUrl',
        );

  final String? localPath;
  final String? networkUrl;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();
    final zoomChild =
        heroTag != null ? Hero(tag: heroTag!, child: imageWidget) : imageWidget;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: zoomChild,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _ErrorView(),
      );
    }
    return CachedNetworkImage(
      imageUrl: networkUrl!,
      fit: BoxFit.contain,
      placeholder: (_, _) => const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      ),
      errorWidget: (_, _, _) => _ErrorView(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 40.w,
            color: Colors.white54,
          ),
          SizedBox(height: 12.h),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
