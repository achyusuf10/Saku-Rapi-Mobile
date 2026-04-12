-- ============================================================
-- Migration 016: Remove Parsing Dictionaries
-- Alasan: Manual/local parsing fallback dihapus dari Flutter.
--         Tabel parsing_dictionaries tidak lagi diperlukan.
-- CASCADE otomatis hapus:
--   - idx_parsing_dictionaries_keyword (index)
--   - trg_parsing_dictionaries_updated_at (trigger)
--   - parsing_dictionaries_select_all (RLS policy)
-- ============================================================

DROP TABLE IF EXISTS public.parsing_dictionaries CASCADE;
