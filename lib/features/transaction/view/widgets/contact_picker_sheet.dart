import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/contact_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih kontak hutang/piutang.
///
/// Menggabungkan dua sumber kontak:
/// - **Tersimpan**: kontak DB user yang sudah pernah dipakai.
/// - **Dari HP**: membaca phonebook via [flutter_contacts].
///
/// Mengembalikan [ContactModel] yang dipilih via `Navigator.pop`.
/// Upsert ke DB dilakukan di dalam sheet sebelum pop.
class ContactPickerSheet extends ConsumerStatefulWidget {
  const ContactPickerSheet({super.key});

  /// Tampilkan sheet dan tunggu pilihan user.
  static Future<ContactModel?> show(BuildContext context) {
    return showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ContactPickerSheet(),
    );
  }

  @override
  ConsumerState<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends ConsumerState<ContactPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Muat kontak tersimpan DB saat sheet dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactControllerProvider.notifier).loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Selection ───

  Future<void> _selectSavedContact(ContactModel contact) async {
    if (!mounted) return;
    Navigator.of(context).pop(contact);
  }

  Future<void> _selectPhonebookContact(Contact raw) async {
    if (!mounted) return;

    final name = raw.displayName.trim();
    if (name.isEmpty) return;

    final phone = raw.phones.isNotEmpty
        ? raw.phones.first.number.replaceAll(RegExp(r'\s+'), '')
        : null;

    // Upsert ke DB dan kembalikan ContactModel dengan id
    final contactModel = await ref
        .read(contactControllerProvider.notifier)
        .upsertContact(name: name, phone: phone);

    if (!mounted) return;

    Navigator.of(context).pop(contactModel);
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final contactState = ref.watch(contactControllerProvider);

    final normalizedQuery = _query.toLowerCase().trim();

    // Filter kontak tersimpan
    final savedContacts = normalizedQuery.isEmpty
        ? contactState.contacts
        : contactState.contacts
              .where(
                (c) =>
                    c.name.toLowerCase().contains(normalizedQuery) ||
                    (c.phone?.contains(normalizedQuery) ?? false),
              )
              .toList();

    // Filter phonebook
    final phonebookFiltered = contactState.phonebookContacts == null
        ? null
        : normalizedQuery.isEmpty
        ? contactState.phonebookContacts!
        : contactState.phonebookContacts!
              .where(
                (c) =>
                    c.displayName.toLowerCase().contains(normalizedQuery) ||
                    c.phones.any((p) => p.number.contains(normalizedQuery)),
              )
              .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                Text(
                  l10n.contactPickerTitle,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.contactPickerSearch,
                hintStyle: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18.w,
                  color: colors.textSecondary,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16.w,
                          color: colors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.background,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.h,
                  horizontal: 12.w,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Content list
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              children: [
                // ─── From Phonebook button ───
                if (contactState.phonebookContacts == null) ...[
                  _SectionHeader(label: l10n.contactPickerFromPhonebook),
                  if (contactState.phonebookDenied)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        l10n.contactPickerPhonePermissionDenied,
                        style: TextStyleConstants.b2.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    contactState.phonebookLoading
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: const Center(child: SakuLoadingIndicator()),
                          )
                        : GestureDetector(
                            onTap: () => ref
                                .read(contactControllerProvider.notifier)
                                .loadPhonebook(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              margin: EdgeInsets.only(bottom: 4.h),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.addressBook,
                                    size: 16.w,
                                    color: colors.primary,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    l10n.contactPickerFromPhonebook,
                                    style: TextStyleConstants.b2.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18.w,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  SizedBox(height: 8.h),
                ] else ...[
                  // ─── Phonebook list ───
                  _SectionHeader(label: l10n.contactPickerFromPhonebook),
                  if (phonebookFiltered!.isEmpty)
                    _EmptyHint(text: l10n.contactPickerEmpty)
                  else
                    ...phonebookFiltered.map(
                      (c) => _PhonebookItem(
                        contact: c,
                        noPhoneLabel: l10n.contactPickerNoPhone,
                        onTap: () => _selectPhonebookContact(c),
                      ),
                    ),
                  SizedBox(height: 12.h),
                ],

                // ─── Saved contacts ───
                _SectionHeader(label: l10n.contactPickerSaved),
                if (contactState.isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: const Center(child: SakuLoadingIndicator()),
                  )
                else if (savedContacts.isEmpty)
                  _EmptyHint(text: l10n.contactPickerEmpty)
                else
                  ...savedContacts.map(
                    (c) => _SavedContactItem(
                      contact: c,
                      onTap: () => _selectSavedContact(c),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Sub-widgets ───────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
      child: Text(
        label.toUpperCase(),
        style: TextStyleConstants.overline.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Text(
        text,
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _SavedContactItem extends StatelessWidget {
  const _SavedContactItem({required this.contact, required this.onTap});
  final ContactModel contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        margin: EdgeInsets.only(bottom: 4.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyleConstants.b1.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (contact.phone != null)
                    Text(
                      contact.phone!,
                      style: TextStyleConstants.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18.w, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PhonebookItem extends StatelessWidget {
  const _PhonebookItem({
    required this.contact,
    required this.noPhoneLabel,
    required this.onTap,
  });
  final Contact contact;
  final String noPhoneLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phoneDisplay = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : noPhoneLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        margin: EdgeInsets.only(bottom: 4.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colors.primaryLight.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyleConstants.b1.copyWith(
                    color: colors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    phoneDisplay,
                    style: TextStyleConstants.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18.w, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
