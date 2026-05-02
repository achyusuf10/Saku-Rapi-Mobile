import 'package:flutter/material.dart';

/// Sistem warna kustom SakuRapi menggunakan [ThemeExtension].
///
/// Menggunakan palet **Financial Trust**:
/// navy untuk authority, gold untuk aksen premium,
/// dan slate netral agar dark mode tetap tenang (tidak neon).
///
/// Akses via `context.colors.primary`, `context.colors.background`, dll.
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.debt,
    required this.loan,
    required this.warning,
    required this.error,
    required this.onPrimary,
    required this.success,
    required this.info,
  });

  /// Warna utama brand.
  final Color primary;

  /// Versi lebih muda dari primary (untuk background chip, badge).
  final Color primaryLight;

  /// Versi lebih tua dari primary (untuk pressed state).
  final Color primaryDark;

  /// Warna aksen (amber/kuning untuk highlight).
  final Color accent;

  /// Warna background utama halaman.
  final Color background;

  /// Warna surface untuk Card, Container, dsb.
  final Color surface;

  /// Alternatif surface (untuk input field background).
  final Color surfaceVariant;

  /// Warna border/divider.
  final Color border;

  /// Warna teks utama (heading, body).
  final Color textPrimary;

  /// Warna teks sekunder (subtitle, hint).
  final Color textSecondary;

  /// Warna khusus pemasukan.
  final Color income;

  /// Warna khusus pengeluaran.
  final Color expense;

  /// Warna untuk transaksi transfer.
  final Color transfer;

  /// Warna untuk hutang.
  final Color debt;

  /// Warna untuk piutang.
  final Color loan;

  /// Warna warning (budget 80%).
  final Color warning;

  /// Warna error state.
  final Color error;

  /// Warna teks/ikon di atas primary background.
  final Color onPrimary;

  final Color success;
  final Color info;

  // ─────────────────────────────────────────────────────────────
  // Preset Light & Dark
  // ─────────────────────────────────────────────────────────────

  /// Skema warna untuk **Light Mode**.
  static const light = AppColorScheme(
    primary: Color(
      0xFF047857,
    ), // Emerald 700 (Hijau utama yang solid & kontras)
    primaryLight: Color(
      0xFFD1FAE5,
    ), // Emerald 100 (Untuk background chip, badge)
    primaryDark: Color(0xFF064E3B), // Emerald 900 (Untuk pressed state)
    accent: Color(
      0xFFCA8A04,
    ), // Yellow 600 (Premium Gold - tetap cocok dengan hijau)
    background: Color(0xFFF1F5F9), // Slate 100
    surface: Color(0xFFFFFFFF), // White
    surfaceVariant: Color(0xFFE2E8F0), // Slate 200
    border: Color(0xFFCBD5E1), // Slate 300
    textPrimary: Color(0xFF0F172A), // Slate 900
    textSecondary: Color(0xFF64748B), // Slate 500
    // Semantic Colors (Biarkan tetap sama)
    income: Color(
      0xFF10B981,
    ), // Emerald 500 (Sedikit dibedakan dari primary agar tetap stand-out)
    expense: Color(0xFFDC2626),
    transfer: Color(0xFF2563EB),
    debt: Color(0xFFEA580C),
    loan: Color(0xFF9333EA),
    warning: Color(0xFFCA8A04),
    error: Color(0xFFDC2626),
    success: Color(0xFF10B981),
    info: Color(0xFF2563EB),
    onPrimary: Color(
      0xFFFFFFFF,
    ), // Teks putih sangat kontras di atas Emerald 700
  );

  /// Skema warna untuk **Dark Mode**.
  static const dark = AppColorScheme(
    // ─────────────────────────────────────────────────────────────
    // Brand & Accent Colors
    // ─────────────────────────────────────────────────────────────
    primary: Color(
      0xFF34D399,
    ), // Emerald 400 (Hijau terang agar 'pop up' elegan)
    primaryLight: Color(
      0xFF064E3B,
    ), // Emerald 900 (Hijau gelap untuk latar chip/badge)
    primaryDark: Color(
      0xFF6EE7B7,
    ), // Emerald 300 (Hijau lebih terang untuk highlight)
    accent: Color(
      0xFFD4AF37,
    ), // Premium Gold (Aksen mewah yang sangat cocok dengan hijau)
    // ─────────────────────────────────────────────────────────────
    // Background & Surfaces (Netral Grey / Charcoal - BUKAN biru/Slate)
    // ─────────────────────────────────────────────────────────────
    background: Color(
      0xFF171717,
    ), // Neutral 900 (Abu-abu gelap murni yang elegan)
    surface: Color(
      0xFF262626,
    ), // Neutral 800 (Warna card/container agar terlihat menonjol)
    surfaceVariant: Color(0xFF404040), // Neutral 700 (Warna input field)
    border: Color(0xFF525252), // Neutral 600 (Garis pembatas yang soft)
    // ─────────────────────────────────────────────────────────────
    // Typography
    // ─────────────────────────────────────────────────────────────
    textPrimary: Color(
      0xFFF5F5F5,
    ), // Neutral 100 (Putih abu-abu agar nyaman di mata)
    textSecondary: Color(0xFFA3A3A3), // Neutral 400 (Abu-abu sekunder)
    onPrimary: Color(
      0xFF022C22,
    ), // Emerald 950 (Teks gelap di atas tombol primary hijau)
    // ─────────────────────────────────────────────────────────────
    // Semantic Colors
    // ─────────────────────────────────────────────────────────────
    income: Color(0xFF10B981), // Emerald 500
    expense: Color(0xFFFB7185), // Rose 400 (Merah premium)
    transfer: Color(0xFF60A5FA), // Blue 400
    debt: Color(0xFFFB923C), // Orange 400
    loan: Color(0xFFC084FC), // Purple 400
    warning: Color(0xFFFBBF24), // Amber 400
    error: Color(0xFFFB7185), // Rose 400
    success: Color(0xFF34D399), // Emerald 400
    info: Color(0xFF60A5FA), // Blue 400
  ); // ─────────────────────────────────────────────────────────────

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? income,
    Color? expense,
    Color? transfer,
    Color? debt,
    Color? loan,
    Color? warning,
    Color? error,
    Color? onPrimary,
    Color? success,
    Color? info,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      debt: debt ?? this.debt,
      loan: loan ?? this.loan,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      info: info ?? this.info,
    );
  }

  @override
  AppColorScheme lerp(covariant AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      loan: Color.lerp(loan, other.loan, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
