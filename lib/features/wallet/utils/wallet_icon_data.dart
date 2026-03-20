import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Mapping nama ikon yang disimpan di DB ke [IconData] FontAwesome.
///
/// Key = string yang disimpan di kolom `icon` tabel wallets.
/// Value = [IconData] FontAwesome yang sesuai.
const Map<String, IconData> walletIconMap = {
  'wallet': FontAwesomeIcons.wallet,
  'money-bill': FontAwesomeIcons.moneyBill,
  'money-bill-wave': FontAwesomeIcons.moneyBillWave,
  'credit-card': FontAwesomeIcons.creditCard,
  'piggy-bank': FontAwesomeIcons.piggyBank,
  'building-columns': FontAwesomeIcons.buildingColumns,
  'coins': FontAwesomeIcons.coins,
  'sack-dollar': FontAwesomeIcons.sackDollar,
  'vault': FontAwesomeIcons.vault,
  'landmark': FontAwesomeIcons.landmark,
  'hand-holding-dollar': FontAwesomeIcons.handHoldingDollar,
  'cash-register': FontAwesomeIcons.cashRegister,
  'chart-line': FontAwesomeIcons.chartLine,
  'mobile-screen': FontAwesomeIcons.mobileScreen,
  'gem': FontAwesomeIcons.gem,
  'gift': FontAwesomeIcons.gift,
};

/// Daftar warna hex yang tersedia untuk wallet.
const List<String> walletColorOptions = [
  '#10B981', // emerald
  '#3B82F6', // blue
  '#8B5CF6', // violet
  '#F59E0B', // amber
  '#EF4444', // red
  '#EC4899', // pink
  '#14B8A6', // teal
  '#F97316', // orange
  '#6366F1', // indigo
  '#84CC16', // lime
  '#06B6D4', // cyan
  '#A855F7', // purple
];

/// Mendapatkan [IconData] dari nama ikon string.
///
/// Fallback ke `FontAwesomeIcons.wallet` jika tidak ditemukan.
IconData getWalletIcon(String iconName) {
  return walletIconMap[iconName] ?? FontAwesomeIcons.wallet;
}
