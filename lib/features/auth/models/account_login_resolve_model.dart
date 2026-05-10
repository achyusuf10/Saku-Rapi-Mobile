/// Hasil RPC [resolve_account_login_state] untuk gerbang akses setelah sesi ada.
///
/// Dipetakan dari JSON `{ allowed, reason, days_remaining }`.
class AccountLoginResolveModel {
  const AccountLoginResolveModel({
    required this.allowed,
    required this.reason,
    this.daysRemaining,
  });

  /// Apakah user boleh melanjutkan ke aplikasi.
  final bool allowed;

  /// Alasan ketika [allowed] false, misalnya `account_cooldown`.
  final String? reason;

  /// Sisa hari sampai cooldown berakhir; hanya bermakna jika diblok `account_cooldown`.
  final int? daysRemaining;

  factory AccountLoginResolveModel.fromRpcJson(Map<String, dynamic> json) {
    return AccountLoginResolveModel(
      allowed: json['allowed'] == true,
      reason: json['reason'] as String?,
      daysRemaining: json['days_remaining'] != null
          ? (json['days_remaining'] as num).toInt()
          : null,
    );
  }
}
