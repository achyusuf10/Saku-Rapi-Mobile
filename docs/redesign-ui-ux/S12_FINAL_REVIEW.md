# S12 — Final Review & Polish

**Dependency:** S3–S11 (semua section selesai)

---

## Review Checklist

### Visual Consistency
- [ ] Semua halaman menggunakan color dari `context.colors` (tidak ada hardcoded)
- [ ] Semua teks menggunakan `TextStyleConstants` (tidak ada inline TextStyle)
- [ ] Semua spacing menggunakan ScreenUtil `.w`, `.h`, `.r`, `.sp`
- [ ] Semua currency display menggunakan `extToRupiah()` / `toCurrency()`
- [ ] Semua date display menggunakan extension methods
- [ ] Semua string dari `.arb` localization

### Dark Mode Audit
- [ ] Background: #0F172A (neutral, NO green tint)
- [ ] Surface: #1E293B (neutral slate)
- [ ] Tidak ada warna neon (semua muted/desaturated)
- [ ] Tidak ada glow effect (text-shadow, boxShadow dengan primary color)
- [ ] Text contrast minimal 4.5:1 (WCAG AA)
- [ ] Cards visible dengan border atau subtle elevation difference
- [ ] Charts readable di dark mode

### Light Mode Audit
- [ ] Background: #F8FAFC (clean off-white)
- [ ] Cards: white dengan subtle shadow atau border
- [ ] Text contrast: textPrimary #0F172A on #F8FAFC → 15.4:1 ✓
- [ ] TextSecondary #64748B on #F8FAFC → 4.6:1 ✓ (WCAG AA)
- [ ] Tidak ada gradient (kecuali chart area fills)

### Typography Audit
- [ ] Hanya IBM Plex Sans digunakan
- [ ] Tidak ada Plus Jakarta Sans atau Nunito Sans tersisa
- [ ] Font weight hierarchy jelas: 400 (body), 500 (emphasis), 600 (labels/buttons), 700 (headings)

### Widget Consistency
- [ ] SakuCard: 12.r radius konsisten
- [ ] SakuButton: primary = navy (light) / slate-200 (dark)
- [ ] SakuTextField: surfaceVariant fill, primary focus border
- [ ] SakuDialog: 16.r radius, neutral shadow
- [ ] SakuEmptyState/ErrorState: proper icon + text colors
- [ ] ShimmerWidget: visible di kedua mode

### Shadow & Elevation
- [ ] Tidak ada primary-tinted shadow
- [ ] Shadow menggunakan `Colors.black.withValues(alpha:)` saja
- [ ] Light mode: subtle shadow (alpha 0.04–0.08)
- [ ] Dark mode: minimal/no shadow (rely on border or surface difference)

### Functional Verification
- [ ] `fvm flutter analyze` — zero errors
- [ ] `fvm flutter test` — all tests pass
- [ ] Semua informasi yang ada sebelumnya tetap ditampilkan
- [ ] Navigation flow tidak berubah
- [ ] Form validation tetap berfungsi
- [ ] Loading states (shimmer) terlihat proper
- [ ] Empty states terlihat proper
- [ ] Error states + retry berfungsi
- [ ] Theme switch (light ↔ dark) smooth via lerp

### Performance
- [ ] Tidak ada widget rebuild berlebihan dari theme change
- [ ] Font loading tidak memperlambat startup
- [ ] Shadow rendering tidak berat (gunakan blurRadius kecil)

---

## Post-Redesign Notes

Setelah S12 selesai, update file berikut jika diperlukan:
- `docs/03_COPILOT_RULES.md` — update UI conventions section
- `README.md` — update screenshots jika ada
- `.github/copilot-instructions.md` — update color/typography references
