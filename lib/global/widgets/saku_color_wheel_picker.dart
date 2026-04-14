import 'dart:math';

import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Color wheel picker HSV — custom tanpa dependency package.
///
/// Menampilkan:
/// 1. **Hue ring** — lingkaran luar untuk memilih hue (0°–360°)
/// 2. **SV area** — kotak di dalam ring untuk saturation (horizontal)
///    dan value/brightness (vertikal)
/// 3. **Hex input** — text field untuk input hex manual
///
/// ```dart
/// SakuColorWheelPicker(
///   color: Colors.blue,
///   onColorChanged: (color) => setState(() => _color = color),
/// )
/// ```
class SakuColorWheelPicker extends StatefulWidget {
  const SakuColorWheelPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.size,
    this.ringWidth = 24,
  });

  /// Warna saat ini.
  final Color color;

  /// Callback ketika warna berubah.
  final ValueChanged<Color> onColorChanged;

  /// Ukuran wheel (lebar = tinggi). Default mengikuti parent width.
  final double? size;

  /// Lebar ring hue.
  final double ringWidth;

  @override
  State<SakuColorWheelPicker> createState() => _SakuColorWheelPickerState();
}

enum _DragTarget { none, hueRing, svArea }

class _SakuColorWheelPickerState extends State<SakuColorWheelPicker> {
  late HSVColor _hsv;
  late TextEditingController _hexController;
  late FocusNode _hexFocusNode;
  bool _isEditingHex = false;
  bool _isInternalUpdate = false;
  _DragTarget _activeDrag = _DragTarget.none;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
    _hexController = TextEditingController(text: _colorToHex(widget.color));
    _hexFocusNode = FocusNode();
    _hexFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SakuColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      if (_isInternalUpdate) {
        // Perubahan dari gesture/hex internal — _hsv sudah benar.
        // Skip konversi Color→HSV karena akan kehilangan hue
        // saat value/saturation mendekati 0.
        _isInternalUpdate = false;
      } else {
        // Perubahan dari luar (preset, parent reset)
        _hsv = HSVColor.fromColor(widget.color);
      }
      if (!_isEditingHex) {
        _hexController.text = _colorToHex(widget.color);
      }
    }
  }

  @override
  void dispose() {
    _hexFocusNode.removeListener(_onFocusChange);
    _hexFocusNode.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_hexFocusNode.hasFocus) {
      _isEditingHex = true;
    } else {
      _onHexSubmitted(_hexController.text);
    }
  }

  void _updateColor(HSVColor hsv) {
    _isInternalUpdate = true;
    setState(() => _hsv = hsv);
    _hexController.text = _colorToHex(hsv.toColor());
    widget.onColorChanged(hsv.toColor());
  }

  void _onHexSubmitted(String text) {
    _isEditingHex = false;
    final hex = text.replaceFirst('#', '').trim();
    if (hex.length == 6 && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      final color = Color(int.parse('FF$hex', radix: 16));
      final hsv = HSVColor.fromColor(color);
      _updateColor(hsv);
    } else {
      _hexController.text = _colorToHex(_hsv.toColor());
    }
  }

  // ───────── Gesture Routing ─────────

  _DragTarget _hitTest(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - widget.ringWidth;
    final svHalfSide = (innerRadius - 6) * sqrt(2) / 2;

    // Cek SV area dulu (prioritas lebih tinggi karena di dalam)
    if ((position.dx - center.dx).abs() <= svHalfSide &&
        (position.dy - center.dy).abs() <= svHalfSide) {
      return _DragTarget.svArea;
    }

    // Cek ring area (dengan toleransi)
    if (dist >= innerRadius - 10 && dist <= outerRadius + 10) {
      return _DragTarget.hueRing;
    }

    return _DragTarget.none;
  }

  void _onGestureStart(Offset position, Size size) {
    _activeDrag = _hitTest(position, size);
    _processGesture(position, size);
  }

  void _onGestureUpdate(Offset position, Size size) {
    if (_activeDrag == _DragTarget.none) return;
    _processGesture(position, size);
  }

  void _processGesture(Offset position, Size size) {
    switch (_activeDrag) {
      case _DragTarget.hueRing:
        _processHue(position, size);
      case _DragTarget.svArea:
        _processSV(position, size);
      case _DragTarget.none:
        break;
    }
  }

  void _processHue(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final angle = atan2(dy, dx);
    final hue = ((angle * 180 / pi) + 360) % 360;
    _updateColor(_hsv.withHue(hue));
  }

  void _processSV(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = (size.width / 2) - widget.ringWidth - 6;
    final side = innerRadius * sqrt(2);

    final x = (position.dx - (center.dx - side / 2)).clamp(0, side);
    final y = (position.dy - (center.dy - side / 2)).clamp(0, side);

    final saturation = (x / side).clamp(0.0, 1.0);
    final value = (1 - y / side).clamp(0.0, 1.0);
    _updateColor(_hsv.withSaturation(saturation).withValue(value));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hue Ring + SV Area — single gesture handler
        LayoutBuilder(
          builder: (context, constraints) {
            final wheelSize = widget.size ?? constraints.maxWidth;
            return GestureDetector(
              onPanStart: (d) =>
                  _onGestureStart(d.localPosition, Size(wheelSize, wheelSize)),
              onPanUpdate: (d) =>
                  _onGestureUpdate(d.localPosition, Size(wheelSize, wheelSize)),
              onPanEnd: (_) => _activeDrag = _DragTarget.none,
              onTapDown: (d) =>
                  _onGestureStart(d.localPosition, Size(wheelSize, wheelSize)),
              onTapUp: (_) => _activeDrag = _DragTarget.none,
              child: SizedBox(
                width: wheelSize,
                height: wheelSize,
                child: CustomPaint(
                  size: Size(wheelSize, wheelSize),
                  painter: _WheelPainter(
                    hsv: _hsv,
                    ringWidth: widget.ringWidth,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 12.h),

        // Preview + Hex Input
        Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: _hsv.toColor(),
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 2),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SakuTextField(
                controller: _hexController,
                focusNode: _hexFocusNode,
                hint: 'FF5733',
                maxLength: 6,
                showCounter: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: _onHexSubmitted,
                prefixIcon: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: colors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────── Unified Painter ─────────────────

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.hsv, required this.ringWidth});

  final HSVColor hsv;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    _paintHueRing(canvas, size);
    _paintSVArea(canvas, size);
  }

  void _paintHueRing(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - ringWidth / 2;

    // Hue gradient ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..shader = SweepGradient(
        colors: List.generate(
          361,
          (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor(),
        ),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ringPaint);

    // Hue thumb
    final thumbAngle = hsv.hue * pi / 180;
    final thumbCenter = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );
    final thumbRadius = ringWidth / 2 + 2;

    canvas.drawCircle(thumbCenter, thumbRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      thumbCenter,
      thumbRadius - 3,
      Paint()..color = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
    );
  }

  void _paintSVArea(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = (size.width / 2) - ringWidth - 6;
    final side = innerRadius * sqrt(2);
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final borderRadius = BorderRadius.circular(4);
    final rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    // Layer 1: White → Hue (horizontal)
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );

    // Layer 2: Transparent → Black (vertical)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    canvas.restore();

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black12
        ..strokeWidth = 1,
    );

    // SV thumb
    final thumbX = rect.left + side * hsv.saturation;
    final thumbY = rect.top + side * (1 - hsv.value);
    final thumbCenter = Offset(thumbX, thumbY);

    canvas.drawCircle(thumbCenter, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumbCenter,
      8,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(thumbCenter, 5, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.hsv != hsv || old.ringWidth != ringWidth;
}

// ───────────────── Helpers ─────────────────

String _colorToHex(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
