import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animasi lingkaran berdenyut (pulse) di sekitar ikon mikrofon.
///
/// Saat [isListening] = true, lingkaran berdenyut dengan skala 1.0 → 1.4.
/// Warna lingkaran menggunakan `context.colors.primary`.
class VoiceMicVisualizer extends StatefulWidget {
  const VoiceMicVisualizer({super.key, required this.isListening});

  /// `true` saat sedang merekam suara.
  final bool isListening;

  @override
  State<VoiceMicVisualizer> createState() => _VoiceMicVisualizerState();
}

class _VoiceMicVisualizerState extends State<VoiceMicVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isListening) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceMicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final size = 100.r;

    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulse ring ──
            if (widget.isListening)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appColors.primary.withValues(
                          alpha: _opacityAnimation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ── Mic circle ──
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? appColors.primary
                    : appColors.primary.withValues(alpha: 0.3),
                boxShadow: widget.isListening
                    ? [
                        BoxShadow(
                          color: appColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(Icons.mic, color: Colors.white, size: 40.r),
            ),
          ],
        ),
      ),
    );
  }
}
