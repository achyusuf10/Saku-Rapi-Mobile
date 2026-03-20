import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AlertTypeEnum {
  info,
  success,
  warning,
  error;

  Widget get icon {
    switch (this) {
      case AlertTypeEnum.info:
        return Icon(Icons.info_outline, size: 24.w, color: Colors.white);
      case AlertTypeEnum.success:
        return Icon(Icons.check, size: 24.w, color: Colors.white);
      case AlertTypeEnum.warning:
        return Icon(Icons.info_outline, size: 24.w, color: Colors.white);
      case AlertTypeEnum.error:
        return Icon(
          Icons.highlight_remove_rounded,
          size: 24.w,
          color: Colors.white,
        );
    }
  }

  Color get bgColor {
    return appContext?.colors.background ?? Colors.blue.shade50;
    // switch (this) {
    //   case AlertTypeEnum.info:
    //     return color.withValues(alpha: 0.12);
    //   case AlertTypeEnum.success:
    //     return appContext?.colors.success.withValues(alpha: 0.12) ??
    //         Colors.green.shade50;
    //   case AlertTypeEnum.warning:
    //     return appContext?.colors.warning.withValues(alpha: 0.12) ??
    //         Colors.orange.shade50;
    //   case AlertTypeEnum.error:
    //     return appContext?.colors.error.withValues(alpha: 0.12) ??
    //         Colors.red.shade50;
    // }
  }

  Color get color {
    switch (this) {
      case AlertTypeEnum.info:
        return appContext?.colors.info ?? Colors.blue;
      case AlertTypeEnum.success:
        return appContext?.colors.success ?? Colors.green;
      case AlertTypeEnum.warning:
        return appContext?.colors.warning ?? Colors.orange;
      case AlertTypeEnum.error:
        return appContext?.colors.error ?? Colors.red;
    }
  }

  String get title {
    switch (this) {
      case AlertTypeEnum.info:
        return '';
      case AlertTypeEnum.success:
        return 'Selamat!';
      case AlertTypeEnum.warning:
        return 'Peringatan!';
      case AlertTypeEnum.error:
        return 'Upss...';
    }
  }
}
