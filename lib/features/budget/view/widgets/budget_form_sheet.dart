import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Form full-screen untuk membuat / mengedit budget.
///
/// Menampilkan field:
/// - Kategori (khusus expense)
/// - Jumlah anggaran
/// - Periode (mingguan / bulanan / kuartal / tahunan / kustom)
/// - Cakupan wallet (semua wallet atau spesifik)
/// - Toggle recurring (berulang otomatis)
/// - Toggle carry forward (sisa budget diteruskan ke periode berikut)
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.existingBudget});

  /// Budget yang akan diedit. `null` berarti mode tambah baru.
  final BudgetModel? existingBudget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  /// `true` jika sedang mode edit (ada [existingBudget]).
  bool get _isEditMode => widget.existingBudget != null;

  // ═══════════════ Form State ═══════════════
  // State yang diisi user melalui form.

  /// Kategori expense yang dipilih user untuk budget ini.
  CategoryModel? _pickedCategory;

  /// Wallet spesifik yang dipilih (null jika [_appliesToAllWallets] true).
  WalletModel? _pickedWallet;

  /// Apakah budget berlaku untuk semua wallet (global).
  bool _appliesToAllWallets = true;

  /// Nominal anggaran yang diisi user.
  double _budgetAmount = 0;

  /// Tanggal mulai periode budget.
  DateTime _periodStartDate = DateTime.now();

  /// Tanggal akhir periode budget.
  DateTime _periodEndDate = DateTime.now();

  /// Apakah budget ini berulang otomatis setiap periode.
  bool _isRecurring = false;

  /// Apakah sisa anggaran diteruskan ke periode berikutnya.
  bool _isCarryForward = false;

  /// Key periode yang dipilih ('this_week', 'this_month', 'this_quarter',
  /// 'this_year', atau 'custom').
  String _activePeriodKey = 'this_month';

  // ═══════════════ Snapshot Awal (Dirty Check) ═══════════════
  // Nilai awal saat form pertama kali dibuka, digunakan untuk mendeteksi
  // apakah user sudah mengubah sesuatu (dirty) — agar bisa tampilkan
  // konfirmasi discard saat close.

  late final String _snapshotCategoryId;
  late final String? _snapshotWalletId;
  late final double _snapshotAmount;
  late final DateTime _snapshotStartDate;
  late final DateTime _snapshotEndDate;
  late final bool _snapshotIsRecurring;
  late final bool _snapshotIsCarryForward;
  late final String _snapshotPeriodKey;

  /// Controller untuk text field jumlah anggaran.
  final _amountTextController = SakuCurrencyController();

  // ═══════════════ Lifecycle ═══════════════

  @override
  void initState() {
    super.initState();
    _setDefaultPeriodToCurrentMonth();
    _prefillFromExistingBudget();
    // Simpan snapshot SETELAH prefill agar initial values akurat
    _captureInitialSnapshot();
  }

  @override
  void dispose() {
    _amountTextController.dispose();
    super.dispose();
  }

  // ═══════════════ Inisialisasi ═══════════════

  /// Set default periode ke bulan ini (tanggal 1 s/d akhir bulan).
  void _setDefaultPeriodToCurrentMonth() {
    final now = DateTime.now();
    _periodStartDate = DateTime(now.year, now.month, 1);
    _periodEndDate = DateTime(now.year, now.month + 1, 0);
  }

  /// Isi semua field dari [existingBudget] jika mode edit.
  void _prefillFromExistingBudget() {
    final budget = widget.existingBudget;
    if (budget == null) return;

    _pickedCategory = budget.category;
    _pickedWallet = budget.wallet;
    _appliesToAllWallets = budget.walletId == null;
    _budgetAmount = budget.amount;
    _periodStartDate = budget.startDate;
    _periodEndDate = budget.endDate;
    _isRecurring = budget.isRecurring;
    _isCarryForward = budget.carryForward;

    // Format tampilan amount di text field
    if (_budgetAmount > 0) {
      _amountTextController.text = _budgetAmount.toInt().toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rawDigits = _amountTextController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        if (rawDigits.isNotEmpty) {
          final formatted = _formatThousands(int.tryParse(rawDigits) ?? 0);
          _amountTextController.text = formatted;
          _amountTextController.selection = TextSelection.collapsed(
            offset: formatted.length,
          );
        }
      });
    }

    _activePeriodKey = _detectPeriodKeyFromDates();
  }

  /// Simpan snapshot semua field saat ini untuk dirty check nanti.
  void _captureInitialSnapshot() {
    _snapshotCategoryId = _pickedCategory?.id ?? '';
    _snapshotWalletId = _appliesToAllWallets ? null : _pickedWallet?.id;
    _snapshotAmount = _budgetAmount;
    _snapshotStartDate = _periodStartDate;
    _snapshotEndDate = _periodEndDate;
    _snapshotIsRecurring = _isRecurring;
    _snapshotIsCarryForward = _isCarryForward;
    _snapshotPeriodKey = _activePeriodKey;
  }

  // ═══════════════ Dirty Check ═══════════════

  /// Cek apakah ada perubahan dibanding snapshot awal.
  bool get _hasUnsavedChanges {
    return (_pickedCategory?.id ?? '') != _snapshotCategoryId ||
        (_appliesToAllWallets ? null : _pickedWallet?.id) !=
            _snapshotWalletId ||
        _budgetAmount != _snapshotAmount ||
        _periodStartDate != _snapshotStartDate ||
        _periodEndDate != _snapshotEndDate ||
        _isRecurring != _snapshotIsRecurring ||
        _isCarryForward != _snapshotIsCarryForward ||
        _activePeriodKey != _snapshotPeriodKey;
  }

  // ═══════════════ Period Detection ═══════════════

  /// Deteksi period key dari tanggal start/end yang sudah di-set.
  ///
  /// Mencocokkan tanggal dengan batas-batas minggu / bulan / kuartal / tahun
  /// saat ini. Jika tidak cocok satupun, return 'custom'.
  String _detectPeriodKeyFromDates() {
    final now = DateTime.now();

    // Mingguan: Senin s/d Minggu minggu ini
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    if (_periodStartDate.year == weekStart.year &&
        _periodStartDate.month == weekStart.month &&
        _periodStartDate.day == weekStart.day &&
        _periodEndDate.year == weekEnd.year &&
        _periodEndDate.month == weekEnd.month &&
        _periodEndDate.day == weekEnd.day) {
      return 'this_week';
    }

    // Bulanan: tanggal 1 s/d akhir bulan ini
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    if (_periodStartDate == monthStart && _periodEndDate == monthEnd) {
      return 'this_month';
    }

    // Kuartal: awal kuartal s/d akhir kuartal
    final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final quarterStart = DateTime(now.year, quarterStartMonth, 1);
    final quarterEnd = DateTime(now.year, quarterStartMonth + 3, 0);
    if (_periodStartDate == quarterStart && _periodEndDate == quarterEnd) {
      return 'this_quarter';
    }

    // Tahunan: 1 Jan s/d 31 Des
    if (_periodStartDate == DateTime(now.year, 1, 1) &&
        _periodEndDate == DateTime(now.year, 12, 31)) {
      return 'this_year';
    }

    return 'custom';
  }

  // ═══════════════ Helpers ═══════════════

  /// Format angka menjadi string dengan pemisah ribuan titik.
  /// Contoh: 1500000 → "1.500.000"
  String _formatThousands(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Parse hex color string ke [Color]. Fallback ke abu-abu jika invalid.
  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF6B7280);
  }

  /// Validasi apakah form bisa disimpan (kategori & amount harus terisi).
  bool get _isFormValid => _pickedCategory != null && _budgetAmount > 0;

  /// Konversi [_activePeriodKey] ke label yang ditampilkan di UI.
  String _periodDisplayLabel(dynamic l10n) {
    return switch (_activePeriodKey) {
      'this_week' => l10n.budgetPeriodThisWeek,
      'this_month' => l10n.budgetPeriodThisMonth,
      'this_quarter' => l10n.budgetPeriodThisQuarter,
      'this_year' => l10n.budgetPeriodThisYear,
      _ => l10n.budgetPeriodCustom,
    };
  }

  // ═══════════════ UI ═══════════════

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context),
        ),
        title: Text(
          _isEditMode ? l10n.budgetFormTitleEdit : l10n.budgetFormTitleAdd,
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        children: [
          SizedBox(height: 8.h),

          // ─── Pilih Kategori Expense ───
          _BudgetFormSectionTile(
            icon: FontAwesomeIcons.circleQuestion,
            iconColor: colors.textSecondary,
            leading: _pickedCategory != null
                ? SakuCategoryIcon(
                    category: _pickedCategory!,
                    size: 36,
                    iconSize: 16,
                    borderRadius: 10,
                  )
                : null,
            title: _pickedCategory?.name ?? l10n.budgetFormCategorySelect,
            titleColor: _pickedCategory != null
                ? colors.textPrimary
                : colors.textSecondary,
            onTap: () => _openCategoryPicker(context),
          ),

          // ─── Input Jumlah Anggaran ───
          SizedBox(height: 4.h),
          SakuCurrencyField(
            controller: _amountTextController,
            label: l10n.budgetFormAmount,
            hint: '0',
            onChanged: (value) => setState(() => _budgetAmount = value),
          ),

          SizedBox(height: 16.h),

          // ─── Pilih Periode Budget ───
          _BudgetFormSectionTile(
            icon: FontAwesomeIcons.calendarDays,
            iconColor: colors.primary,
            title:
                '${_periodDisplayLabel(l10n)} (${_periodStartDate.extToFormattedString(outputDateFormat: 'dd/MM')} – ${_periodEndDate.extToFormattedString(outputDateFormat: 'dd/MM')})',
            onTap: () => _openPeriodPicker(context),
          ),

          SizedBox(height: 4.h),

          // ─── Pilih Cakupan Wallet ───
          _BudgetFormSectionTile(
            icon: FontAwesomeIcons.wallet,
            iconColor: _appliesToAllWallets
                ? colors.primary
                : _parseHexColor(_pickedWallet?.color),
            title: _appliesToAllWallets
                ? l10n.budgetAllWallets
                : (_pickedWallet?.name ?? l10n.budgetSpecificWallet),
            onTap: () => _openWalletScopePicker(context, wallets),
          ),

          SizedBox(height: 16.h),
          Divider(color: colors.border.withValues(alpha: 0.3)),
          SizedBox(height: 8.h),

          // ─── Toggle Budget Berulang ───
          _BudgetRecurringToggle(
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value),
          ),

          // ─── Toggle Carry Forward (hanya tampil jika recurring aktif) ───
          if (_isRecurring)
            _BudgetCarryForwardToggle(
              value: _isCarryForward,
              onChanged: (value) => setState(() => _isCarryForward = value),
            ),
        ],
      ),

      // ─── Tombol Simpan ───
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: SakuButton(
            text: l10n.budgetSave,
            onPressed: _isFormValid ? () => _handleSave(context) : null,
            isEnabled: _isFormValid,
          ),
        ),
      ),
    );
  }

  // ═══════════════ Actions ═══════════════

  /// Handle tombol close. Tampilkan konfirmasi discard jika ada perubahan.
  Future<void> _handleClose(BuildContext context) async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = context.l10n;
    final shouldDiscard = await context.showConfirmDialog(
      title: l10n.budgetFormDiscardTitle,
      message: l10n.budgetFormDiscardMessage,
      confirmLabel: l10n.budgetFormDiscardConfirm,
      cancelLabel: l10n.budgetCancel,
    );
    if (shouldDiscard == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Simpan budget dan pop result kembali ke caller.
  void _handleSave(BuildContext context) {
    final periodType = switch (_activePeriodKey) {
      'this_week' => BudgetPeriodType.weekly,
      'this_month' => BudgetPeriodType.monthly,
      'this_quarter' => BudgetPeriodType.quarterly,
      'this_year' => BudgetPeriodType.yearly,
      _ => BudgetPeriodType.custom,
    };

    Navigator.of(context).pop(<String, dynamic>{
      'categoryId': _pickedCategory!.id,
      'categoryName': _pickedCategory!.name,
      'walletId': _appliesToAllWallets ? null : _pickedWallet?.id,
      'walletName': _appliesToAllWallets ? null : _pickedWallet?.name,
      'amount': _budgetAmount,
      'startDate': _periodStartDate,
      'endDate': _periodEndDate,
      'isRecurring': _isRecurring,
      'carryForward': _isCarryForward,
      'periodType': periodType,
    });
  }

  // ═══════════════ Pickers ═══════════════

  /// Buka bottom sheet untuk memilih kategori expense.
  Future<void> _openCategoryPicker(BuildContext context) async {
    final result = await CategoryPickerSheet.show(
      context: context,
      type: CategoryType.expense,
      selectedId: _pickedCategory?.id,
    );
    if (result != null) setState(() => _pickedCategory = result);
  }

  /// Buka bottom sheet untuk memilih periode budget.
  ///
  /// Pilihan: Minggu Ini, Bulan Ini, Kuartal Ini, Tahun Ini, Kustom.
  /// Jika user pilih Kustom, buka [showDateRangePicker].
  void _openPeriodPicker(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final now = DateTime.now();

    // Daftar periode preset beserta tanggal start/end-nya
    final presetPeriods = [
      _BudgetPeriodPreset(
        key: 'this_week',
        label: l10n.budgetPeriodThisWeek,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(Duration(days: 7 - now.weekday)),
      ),
      _BudgetPeriodPreset(
        key: 'this_month',
        label: l10n.budgetPeriodThisMonth,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      ),
      _BudgetPeriodPreset(
        key: 'this_quarter',
        label: l10n.budgetPeriodThisQuarter,
        startDate: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1),
        endDate: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0),
      ),
      _BudgetPeriodPreset(
        key: 'this_year',
        label: l10n.budgetPeriodThisYear,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
      ),
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // Judul
                Text(
                  l10n.budgetPeriodTitle,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),

                // Daftar pilihan periode preset
                ...presetPeriods.map(
                  (preset) => ListTile(
                    title: Text(
                      preset.label,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: _activePeriodKey == preset.key
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: _activePeriodKey == preset.key
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${preset.startDate.extToFormattedString(outputDateFormat: 'dd MMM')} – ${preset.endDate.extToFormattedString(outputDateFormat: 'dd MMM yyyy')}',
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: _activePeriodKey == preset.key
                        ? FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 18.w,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _activePeriodKey = preset.key;
                        _periodStartDate = preset.startDate;
                        _periodEndDate = preset.endDate;
                      });
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),

                // Pilihan "Kustom" — buka date range picker
                ListTile(
                  title: Text(
                    l10n.budgetPeriodCustom,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: _activePeriodKey == 'custom'
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: _activePeriodKey == 'custom'
                          ? colors.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: DateTimeRange(
                        start: _periodStartDate,
                        end: _periodEndDate,
                      ),
                    );
                    if (dateRange != null) {
                      setState(() {
                        _activePeriodKey = 'custom';
                        _periodStartDate = dateRange.start;
                        _periodEndDate = dateRange.end;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Buka bottom sheet untuk memilih cakupan wallet.
  ///
  /// User bisa pilih "Semua Wallet" (global) atau wallet tertentu.
  void _openWalletScopePicker(BuildContext context, List<WalletModel> wallets) {
    final colors = context.colors;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // Judul
                Text(
                  l10n.budgetFormWalletScope,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),

                // Opsi: Semua Wallet (global)
                ListTile(
                  leading: FaIcon(
                    FontAwesomeIcons.globe,
                    size: 18.w,
                    color: colors.primary,
                  ),
                  title: Text(
                    l10n.budgetAllWallets,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: _appliesToAllWallets
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: _appliesToAllWallets
                          ? colors.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: _appliesToAllWallets
                      ? FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 18.w,
                          color: colors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _appliesToAllWallets = true;
                      _pickedWallet = null;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
                Divider(color: colors.border.withValues(alpha: 0.2)),

                // Opsi: Wallet spesifik
                ...wallets.map((wallet) {
                  final isSelected =
                      !_appliesToAllWallets && _pickedWallet?.id == wallet.id;
                  return ListTile(
                    leading: SakuCategoryIcon.raw(
                      iconName: wallet.icon,
                      colorHex: wallet.color,
                      size: 32,
                      iconSize: 14,
                      borderRadius: 8,
                    ),
                    title: Text(
                      wallet.name,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 18.w,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _appliesToAllWallets = false;
                        _pickedWallet = wallet;
                      });
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Private Widgets — Komponen UI khusus untuk BudgetFormSheet
// ═══════════════════════════════════════════════════════════════

/// Tile navigasi generik untuk form budget (kategori, periode, wallet).
///
/// Menampilkan ikon + label + chevron right.
class _BudgetFormSectionTile extends StatelessWidget {
  const _BudgetFormSectionTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.onTap,
    this.leading,
  });

  /// Ikon yang ditampilkan di leading (fallback jika [leading] null).
  final IconData icon;

  /// Widget custom leading (override icon + iconColor).
  final Widget? leading;

  /// Label utama yang ditampilkan.
  final String title;

  /// Warna ikon (default: textSecondary).
  final Color? iconColor;

  /// Warna teks label (default: textPrimary).
  final Color? titleColor;

  /// Callback saat tile di-tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading:
          leading ??
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: (iconColor ?? colors.textSecondary).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 16.w,
                color: iconColor ?? colors.textSecondary,
              ),
            ),
          ),
      title: Text(
        title,
        style: TextStyleConstants.b1.copyWith(
          color: titleColor ?? colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 14.w,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

/// Toggle checkbox untuk mengaktifkan budget berulang (recurring).
class _BudgetRecurringToggle extends StatelessWidget {
  const _BudgetRecurringToggle({required this.value, required this.onChanged});

  /// Apakah recurring aktif.
  final bool value;

  /// Callback saat value berubah.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: SizedBox(
        width: 28.w,
        height: 28.w,
        child: Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
      title: Text(
        l10n.budgetFormRecurringTitle,
        style: TextStyleConstants.b2.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        l10n.budgetFormRecurringSubtitle,
        style: TextStyleConstants.label2.copyWith(color: colors.textSecondary),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// Toggle checkbox untuk meneruskan sisa anggaran ke periode berikutnya.
///
/// Hanya ditampilkan ketika recurring aktif.
class _BudgetCarryForwardToggle extends StatelessWidget {
  const _BudgetCarryForwardToggle({
    required this.value,
    required this.onChanged,
  });

  /// Apakah carry forward aktif.
  final bool value;

  /// Callback saat value berubah.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: SizedBox(
        width: 28.w,
        height: 28.w,
        child: Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
      title: Text(
        l10n.budgetFormCarryForwardTitle,
        style: TextStyleConstants.b2.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        l10n.budgetFormCarryForwardSubtitle,
        style: TextStyleConstants.label2.copyWith(color: colors.textSecondary),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// Data untuk satu opsi preset periode di period picker.
class _BudgetPeriodPreset {
  const _BudgetPeriodPreset({
    required this.key,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  /// Key identifikasi periode ('this_week', 'this_month', dll).
  final String key;

  /// Label tampilan di UI.
  final String label;

  /// Tanggal mulai periode.
  final DateTime startDate;

  /// Tanggal akhir periode.
  final DateTime endDate;
}
