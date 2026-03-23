import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tombol utama SakuRapi yang sudah anti double-tap.
///
/// Gunakan widget ini untuk semua tombol aksi di aplikasi.
/// Memiliki proteksi duplikasi tap bawaan (debounce 500ms).
class SakuButton extends StatefulWidget {
  const SakuButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  /// Teks yang ditampilkan di tombol.
  final String text;

  /// Callback saat tombol ditekan.
  final VoidCallback? onPressed;

  /// Jika `true`, tampilkan indikator loading dan blokir tap.
  final bool isLoading;

  /// Jika `false`, tombol disabled.
  final bool isEnabled;

  /// Jika `true`, tampilkan sebagai tombol outlined (tanpa fill).
  final bool isOutlined;

  /// Icon opsional di sebelah kiri teks.
  final Widget? icon;

  /// Lebar tombol. Default: full width.
  final double? width;

  /// Tinggi tombol.
  final double? height;

  /// Warna background kustom.
  final Color? backgroundColor;

  /// Warna teks kustom.
  final Color? textColor;

  /// Border radius kustom.
  final double? borderRadius;

  @override
  State<SakuButton> createState() => _SakuButtonState();
}

class _SakuButtonState extends State<SakuButton> {
  bool _isProcessing = false;

  Future<void> _handleTap() async {
    if (_isProcessing || widget.isLoading || !widget.isEnabled) return;
    _isProcessing = true;

    try {
      widget.onPressed?.call();
    } finally {
      // Debounce 500ms untuk mencegah double-tap.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = widget.backgroundColor ?? colors.primary;
    final fgColor = widget.textColor ?? colors.onPrimary;
    final radius = widget.borderRadius ?? 12.r;
    final enabled = widget.isEnabled && !widget.isLoading;

    if (widget.isOutlined) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 48.h,
        child: OutlinedButton(
          onPressed: enabled ? _handleTap : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: enabled ? bgColor : colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _buildChild(bgColor),
        ),
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 48.h,
      child: ElevatedButton(
        onPressed: enabled ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: colors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
        ),
        child: _buildChild(fgColor),
      ),
    );
  }

  Widget _buildChild(Color foreground) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(strokeWidth: 2.w, color: foreground),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              widget.text,
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyleConstants.b2.copyWith(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}
