# SakuRapi Prompt Pack — Urutan Eksekusi Copilot

Paket ini berisi prompt yang sudah diurutkan dari awal sampai akhir agar implementasi SakuRapi lebih konsisten dengan:
- `01_PRD.md`
- `02_DATABASE.md`
- `03_COPILOT_RULES.md`

## Cara pakai
1. Buka repository SakuRapi di Copilot Chat / agent mode.
2. Upload atau tempel context dokumen:
   - `01_PRD.md`
   - `02_DATABASE.md`
   - `03_COPILOT_RULES.md`
3. Jalankan prompt **berurutan** dari `01_...` sampai `19_...`.
4. Jangan lompat ke prompt berikutnya sebelum hasil prompt sebelumnya selesai dan sudah kamu review.
5. Bila Copilot mulai mengarang atau keluar dari rule, kirim ulang `01_MASTER_SESSION_PROMPT.md`.

## Saran workflow
- Untuk prompt besar, jalankan per 1 prompt lalu commit.
- Gunakan branch terpisah:
  - `feat/foundation`
  - `feat/database`
  - `feat/auth`
  - dst.
- Setelah tiap prompt selesai:
  1. review diff
  2. jalankan test/analyze
  3. commit
  4. lanjut prompt berikutnya

## Urutan prompt
1. `01_MASTER_SESSION_PROMPT.md`
2. `02_REPO_FOUNDATION_AND_ARCHITECTURE.md`
3. `03_DATABASE_SCHEMA_RLS_RPC.md`
4. `04_AUTH_AND_PROFILE.md`
5. `05_CATEGORY_SYSTEM_AND_SEEDING.md`
6. `06_WALLET_MODULE.md`
7. `07_TRANSACTION_CORE_LEDGER.md`
8. `08_DASHBOARD_HOME.md`
9. `09_HISTORY_FILTERS_AND_DETAIL.md`
10. `10_SETTINGS_THEME_LANGUAGE_ENTRYPOINT.md`
11. `11_MULTI_ITEM_AND_SPLIT_BILL.md`
12. `12_VOICE_INPUT_AI_PREFILL.md`
13. `13_OCR_RECEIPT_AI_PREFILL.md`
14. `14_BUDGETING_MODULE.md`
15. `15_REPORTS_AND_ANALYTICS.md`
16. `16_LOCAL_NOTIFICATIONS_AND_REMINDERS.md`
17. `17_INVESTMENT_AND_WEALTH.md`
18. `18_TESTING_HARDENING_AND_REFACTOR.md`
19. `19_FINAL_REVIEW_AND_RELEASE_CHECKLIST.md`

## Catatan penting
- Semua prompt ini mengasumsikan single currency `IDR`.
- Semua saldo wallet harus berasal dari ledger `transactions`.
- AI Voice/OCR hanya prefill; user tetap konfirmasi sebelum save.
- Jika implementasi saat ini berbeda dengan dokumen, prioritaskan dokumen.
