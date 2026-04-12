import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/voice/controllers/ai_quota_provider.dart';
import 'package:app_saku_rapi/features/voice/models/ai_quota_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget ringkas yang menampilkan sisa kuota AI untuk mode tertentu.
///
/// Ditampilkan di bagian atas bottom sheet (Voice/Text/OCR).
/// Menampilkan "Sisa X dari Y kali hari ini" atau "Batas harian tercapai".
class AiQuotaInfoRow extends ConsumerWidget {
  const AiQuotaInfoRow({super.key, required this.mode});

  /// Mode quota: `'text'`, `'voice'`, atau `'ocr'`.
  final String mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final quotaAsync = ref.watch(aiQuotaProvider);

    return quotaAsync.when(
      loading: () => _buildRow(
        icon: FontAwesomeIcons.spinner,
        iconColor: colors.textSecondary,
        text: '...',
        textColor: colors.textSecondary,
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (allQuotas) {
        final quota = allQuotas.quotaForMode(mode);

        if (quota.isExhausted) {
          return _buildRow(
            icon: FontAwesomeIcons.circleExclamation,
            iconColor: colors.expense,
            text: l10n.aiQuotaExhausted,
            textColor: colors.expense,
          );
        }

        return _buildRow(
          icon: FontAwesomeIcons.bolt,
          iconColor: colors.info,
          text: l10n.aiQuotaRemaining(quota.remaining, quota.limit),
          textColor: colors.textSecondary,
        );
      },
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 12.w, color: iconColor),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyleConstants.label2.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  /// Check apakah kuota habis (helper statis untuk disable tombol dari luar).
  static bool isExhausted(AllAiQuotasModel? quotas, String mode) {
    if (quotas == null) return false;
    return quotas.quotaForMode(mode).isExhausted;
  }
}

