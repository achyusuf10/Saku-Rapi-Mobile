import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// FAB utama SakuRapi yang jika ditekan membuka 3 tombol aksi kecil
/// di atasnya dengan animasi fade + slide-up.
///
/// Tombol aksi:
/// 1. **Mic** (🎙️) — Voice Input
/// 2. **Camera** (📷) — Scan Struk
/// 3. **Edit** (📝) — Input Manual
///
/// FAB utama berwarna `context.colors.primary`, sedangkan tombol anak
/// menggunakan `context.colors.surface` dengan ikon `primary`.
class SakuExpandableFab extends StatefulWidget {
  const SakuExpandableFab({
    super.key,
    required this.onVoiceTapped,
    required this.onScanTapped,
    required this.onManualTapped,
  });

  /// Callback ketika tombol voice input ditekan.
  final VoidCallback onVoiceTapped;

  /// Callback ketika tombol scan struk ditekan.
  final VoidCallback onScanTapped;

  /// Callback ketika tombol input manual ditekan.
  final VoidCallback onManualTapped;

  @override
  State<SakuExpandableFab> createState() => _SakuExpandableFabState();
}

class _SakuExpandableFabState extends State<SakuExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleAction(VoidCallback callback) {
    _toggle();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return SizedBox(
      width: 56.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Tombol aksi anak (muncul dari bawah ke atas) ──
          _buildChildAction(
            icon: FontAwesomeIcons.microphone,
            onTap: () => _handleAction(widget.onVoiceTapped),
            index: 2, // Paling atas → delay terbesar
          ),
          SizedBox(height: 12.h),
          _buildChildAction(
            icon: FontAwesomeIcons.camera,
            onTap: () => _handleAction(widget.onScanTapped),
            index: 1,
          ),
          SizedBox(height: 12.h),
          _buildChildAction(
            icon: FontAwesomeIcons.penToSquare,
            onTap: () => _handleAction(widget.onManualTapped),
            index: 0, // Paling dekat FAB → muncul duluan
          ),
          SizedBox(height: 16.h),

          // ── FAB utama ──
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: FloatingActionButton(
              heroTag: 'saku_expandable_fab',
              onPressed: _toggle,
              backgroundColor: appColors.primary,
              elevation: 4,
              shape: const CircleBorder(),
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0, // 45 derajat
                duration: const Duration(milliseconds: 250),
                child: FaIcon(
                  FontAwesomeIcons.plus,
                  color: Colors.white,
                  size: 22.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun satu tombol aksi anak dengan animasi fade + slide-up.
  ///
  /// [index] menentukan stagger delay; nilai lebih besar = muncul lebih lambat.
  Widget _buildChildAction({
    required IconData icon,
    required VoidCallback onTap,
    required int index,
  }) {
    final appColors = context.colors;

    // Stagger: offset interval berdasarkan index.
    final double begin = (index * 0.15).clamp(0.0, 0.6);
    final double end = (begin + 0.5).clamp(0.0, 1.0);

    final Animation<double> staggered = CurvedAnimation(
      parent: _expandAnimation,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: staggered,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(staggered),
        child: SizedBox(
          width: 44.r,
          height: 44.r,
          child: FloatingActionButton(
            heroTag: 'fab_child_$index',
            onPressed: onTap,
            backgroundColor: appColors.surface,
            elevation: 3,
            shape: const CircleBorder(),
            child: FaIcon(icon, color: appColors.primary, size: 18.r),
          ),
        ),
      ),
    );
  }
}
