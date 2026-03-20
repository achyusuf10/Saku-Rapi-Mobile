import 'package:flutter/material.dart';

/// Sistem warna kustom SakuRapi menggunakan [ThemeExtension].
///
/// Menggunakan palet **Soft Emerald Green** sebagai primary,
/// *Off-White* untuk Light Mode, dan *Soft Dark Hijau* untuk Dark Mode.
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

  /// Warna utama brand (Emerald 500).
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
    primary: Color(0xFF10B981), // Emerald 500
    primaryLight: Color(0xFFD1FAE5), // Emerald 100
    primaryDark: Color(0xFF059669), // Emerald 600
    accent: Color(0xFFF59E0B), // Amber 500
    background: Color(0xFFF8FAF9), // Hijau off-white soft
    surface: Color(0xFFFFFFFF), // Pure White
    surfaceVariant: Color(0xFFF0FDF4), // Emerald 50
    border: Color(0xFFE5E7EB), // Gray 200
    textPrimary: Color(0xFF111827), // Gray 900
    textSecondary: Color(0xFF6B7280), // Gray 500
    income: Color(0xFF10B981), // Emerald 500
    expense: Color(0xFFEF4444), // Red 500
    transfer: Color(0xFF3B82F6), // Blue 500
    debt: Color(0xFFF97316), // Orange 500
    loan: Color(0xFFA855F7), // Purple 500
    warning: Color(0xFFEAB308), // Yellow 500
    error: Color(0xFFDC2626), // Red 600
    success: Color(0xFF10B981), // Emerald 500
    info: Color(0xFF3B82F6), // Blue 500
    onPrimary: Color(0xFFFFFFFF), // White
  );

  /// Skema warna untuk **Dark Mode**.
  static const dark = AppColorScheme(
    primary: Color(0xFF10B981), // Emerald 500 (konsisten)
    primaryLight: Color(0xFF064E3B), // Emerald 900
    primaryDark: Color(0xFF34D399), // Emerald 400
    accent: Color(0xFFFBBF24), // Amber 400
    background: Color(0xFF0F1412), // Dark hijau sangat gelap
    surface: Color(0xFF1A2420), // Dark surface hint hijau
    surfaceVariant: Color(0xFF1F2D28), // Dark surface variant
    border: Color(0xFF374151), // Gray 700
    textPrimary: Color(0xFFF9FAFB), // Gray 50
    textSecondary: Color(0xFF9CA3AF), // Gray 400
    income: Color(0xFF34D399), // Emerald 400
    expense: Color(0xFFF87171), // Red 400
    transfer: Color(0xFF60A5FA), // Blue 400
    debt: Color(0xFFFB923C), // Orange 400
    loan: Color(0xFFC084FC), // Purple 400
    warning: Color(0xFFFCD34D), // Yellow 300
    error: Color(0xFFF87171), // Red 400
    onPrimary: Color(0xFFFFFFFF), // White
    success: Color(0xFF34D399), // Emerald 400
    info: Color(0xFF60A5FA), // Blue 400
  );

  // ─────────────────────────────────────────────────────────────
  // ThemeExtension overrides
  // ─────────────────────────────────────────────────────────────

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
