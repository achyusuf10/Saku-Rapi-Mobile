import 'dart:math';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/utils/packages/flash/src/flash.dart';
import 'package:app_saku_rapi/utils/packages/flash/src/flash_controller.dart';
import 'package:app_saku_rapi/utils/services/screen_util_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ekstensi pada [BuildContext] untuk overlay, alert, dan dialog konfirmasi.
///
/// Sesuai aturan SakuRapi:
/// - Loading: `context.showLoadingOverlay()` + `context.closeOverlay()`
/// - Alert: `context.showAppAlert(message)`
/// - Konfirmasi: `context.showConfirmDialog(title, message)`
extension ContextExt on BuildContext {
  /// Akses cepat ke [AppColorScheme] kustom SakuRapi.
  ///
  /// Contoh: `context.colors.primary`, `context.colors.income`.
  AppColorScheme get colors => Theme.of(this).extension<AppColorScheme>()!;

  // ───────────────────── Loading Overlay ─────────────────────

  /// Menampilkan loading overlay fullscreen yang memblokir interaksi UI.
  ///
  /// Panggil [closeOverlay] di blok `finally` untuk menutup overlay.
  void showLoadingOverlay() {
    final OverlayState overlay = Overlay.of(this);
    final OverlayEntry entry = OverlayEntry(
      builder: (_) => const _LoadingOverlayWidget(),
    );

    // Simpan entry ke _OverlayStore agar bisa di-remove nanti.
    _OverlayStore.instance.push(entry);
    overlay.insert(entry);
  }

  /// Menutup overlay terakhir yang dibuka (LIFO).
  void closeOverlay() {
    _OverlayStore.instance.pop();
  }

  // ───────────────────── App Alert ─────────────────────

  /// Menampilkan alert bar modern di bagian bawah layar.
  ///
  /// Gunakan ini sebagai pengganti `ScaffoldMessenger.showSnackBar`.
  void showAppAlert(
    String message, {
    Widget Function(FlashController)? customActionWidget,
    int flashDuration = 3, // in s
    FlashPosition position = FlashPosition.top,

    /// * Jika ingin tidak menampilkan title, biarkan null
    String? customTitle,

    AlertTypeEnum alertType = AlertTypeEnum.info,
  }) {
    showFlash(
      context: this,
      duration: Duration(seconds: flashDuration),
      builder: (context, controller) {
        String title = customTitle ?? alertType.title;
        return Flash(
          controller: controller,
          position: position,
          child: FlashBar(
            controller: controller,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: alertType.color, width: 1),
            ),
            margin: EdgeInsets.symmetric(
              vertical: 20.w,
              horizontal: context.getValueByLayout(
                phonePortrait: 20.w,
                phoneLandscape: min(40.w, 1.sw / 6),
                tabletPortrait: min(40.w, 1.sw / 6),
                tabletLandscape: 1.sw / 5,
              ),
            ),
            position: position,
            padding: EdgeInsets.symmetric(vertical: 14.w, horizontal: 16.w),
            behavior: FlashBehavior.floating,
            backgroundColor: alertType.bgColor,
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: alertType.color,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: alertType.icon,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      if (title.isNotEmpty) SizedBox(height: 4.w),
                      Text(
                        message
                            .replaceAll('Exception:', '')
                            .replaceAll('Exception :', ''),
                        style: TextStyleConstants.caption.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (customActionWidget == null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.dismiss();
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(Icons.close, size: 16.w, color: Colors.black),
                    ),
                  )
                else
                  customActionWidget(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────── Confirm Dialog ─────────────────────

  /// Menampilkan dialog konfirmasi modern.
  ///
  /// Mengembalikan `true` jika user menekan tombol konfirmasi,
  /// `false` atau `null` jika dibatalkan.
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
  }) {
    final appColors = colors;

    return showGeneralDialog<bool>(
      context: this,
      barrierDismissible: true,
      barrierLabel: 'ConfirmDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, Animation<double> anim, __, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (_, __, ___) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 340.w),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon header
                    Container(
                      width: 56.r,
                      height: 56.r,
                      decoration: BoxDecoration(
                        color: appColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: appColors.primary,
                        size: 28.r,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Title
                    Text(
                      title,
                      style: TextStyleConstants.h6.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),

                    // Message
                    Text(
                      message,
                      style: TextStyleConstants.b2.copyWith(
                        color: appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(this).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              side: BorderSide(
                                color: appColors.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              cancelLabel,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(this).pop(true),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              backgroundColor: appColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              confirmLabel,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Private helpers
// ═══════════════════════════════════════════════════════════════

/// Singleton store untuk mengelola [OverlayEntry] secara LIFO.
class _OverlayStore {
  _OverlayStore._();
  static final _OverlayStore instance = _OverlayStore._();

  final List<OverlayEntry> _entries = [];

  void push(OverlayEntry entry) => _entries.add(entry);

  void pop() {
    if (_entries.isNotEmpty) {
      _entries.removeLast().remove();
    }
  }
}

/// Widget loading overlay dengan animasi modern.
class _LoadingOverlayWidget extends StatelessWidget {
  const _LoadingOverlayWidget();

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          width: 88.r,
          height: 88.r,
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 36.r,
              height: 36.r,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: appColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
