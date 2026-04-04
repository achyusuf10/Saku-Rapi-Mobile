import 'package:flutter/material.dart';

/// Parses a hex color string (with or without `#`) into a [Color].
///
/// Returns [fallback] (default `#6B7280` gray) when [hex] is `null`, empty,
/// or cannot be parsed.
Color parseHexColor(String? hex, {Color fallback = const Color(0xFF6B7280)}) {
  if (hex == null || hex.isEmpty) return fallback;
  final clean = hex.replaceFirst('#', '');
  if (clean.length == 6) {
    final value = int.tryParse('FF$clean', radix: 16);
    if (value != null) return Color(value);
  }
  return fallback;
}
