# Prompt 20 — Custom Task Template

Gunakan template ini jika kamu ingin membuat prompt tambahan di luar urutan utama.

Patuh penuh pada:
- `docs/prd/` (PRD per section — lihat `prd/00_INDEX.md`)
- `02_DATABASE.md`
- `03_COPILOT_RULES.md`
- `01_MASTER_SESSION_PROMPT.md`

## Task
[ISI TASK SPESIFIK]

## Tujuan
[ISI HASIL YANG DIINGINKAN]

## Batasan
- Jangan mengarang requirement di luar dokumen
- Jangan ubah schema tanpa alasan kuat
- Jika perlu SQL/RPC, sertakan migration dan alasan
- Tetap patuh pada ledger rule dan financial guardrails

## Output
Berikan:
1. ringkasan task
2. rule relevan
3. rencana implementasi
4. file yang dibuat/diubah
5. kode lengkap
6. test minimum
7. edge case
