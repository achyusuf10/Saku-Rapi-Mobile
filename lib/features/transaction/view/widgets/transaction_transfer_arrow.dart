import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tombol swap antara dompet sumber dan tujuan pada form transfer.
///
/// Menampilkan dua panah (atas-bawah) di tengah sebagai indikator,
/// dan dapat di-tap untuk menukar posisi kedua dompet.
class TransactionTransferArrow extends StatelessWidget {
  const TransactionTransferArrow({super.key, required this.color, this.onSwap});

  final Color color;

  /// Callback saat tombol swap di-tap. Jika null, tombol tidak interaktif.
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Material(
          color: color.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onSwap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: FaIcon(
                FontAwesomeIcons.rightLeft,
                size: 14.sp,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
