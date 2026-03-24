import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Indikator panah transfer antara dompet sumber dan tujuan.
///
/// Digunakan di form transaksi tipe transfer, di antara dua
/// [TransactionWalletPickerTile].
class TransactionTransferArrow extends StatelessWidget {
  const TransactionTransferArrow({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.arrowDown,
          size: 14.w,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
