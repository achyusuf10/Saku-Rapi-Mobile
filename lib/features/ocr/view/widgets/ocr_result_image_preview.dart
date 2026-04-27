import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Thumbnail gambar struk yang di-crop / dipilih user sebelum AI parse.
class OcrResultImagePreview extends StatelessWidget {
  const OcrResultImagePreview({super.key, required this.imageFile});

  /// File gambar lokal dari alur scan OCR.
  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.file(imageFile, height: 120.h, fit: BoxFit.cover),
      ),
    );
  }
}
