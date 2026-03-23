-- ============================================================================
-- SakuRapi Migration 006: Seed Default Categories
-- ============================================================================
-- Replace placeholder seed_default_categories() dengan implementasi lengkap.
-- Sesuai 02_DATABASE.md §7 (Expense, Income, System categories).
--
-- Categories dibuat sebagai is_default=true, user_id=NEW.id (per user).
-- System categories juga per user agar RLS sederhana.
-- ============================================================================

create or replace function public.seed_default_categories()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := new.id;

  -- ── Expense parent IDs ──
  v_rumah_tangga uuid;
  v_kesehatan uuid;
  v_transportasi uuid;
  v_tagihan uuid;
  v_teknologi uuid;
  v_keluarga uuid;
  v_lainnya_exp uuid;

  -- ── Income parent IDs ──
  v_gaji uuid;
  v_pendapatan_tambahan uuid;
  v_lainnya_inc uuid;
begin

  -- ════════════════════════════════════════════════════════════════════════
  -- EXPENSE CATEGORIES
  -- ════════════════════════════════════════════════════════════════════════

  -- ── Kebutuhan Rumah Tangga ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Kebutuhan Rumah Tangga', 'house', '#F59E0B', 'expense', true, 1)
  returning id into v_rumah_tangga;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Belanja Dapur / Bahan Makanan', 'cartShopping', '#F59E0B', 'expense', v_rumah_tangga, true, 1),
    (v_user_id, 'Perlengkapan Rumah', 'couch', '#F59E0B', 'expense', v_rumah_tangga, true, 2),
    (v_user_id, 'Makan di Luar / Jajan', 'utensils', '#F59E0B', 'expense', v_rumah_tangga, true, 3);

  -- ── Kesehatan & Kebugaran ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Kesehatan & Kebugaran', 'heartPulse', '#EF4444', 'expense', true, 2)
  returning id into v_kesehatan;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Olahraga / Gym', 'dumbbell', '#EF4444', 'expense', v_kesehatan, true, 1),
    (v_user_id, 'Suplemen & Nutrisi', 'capsules', '#EF4444', 'expense', v_kesehatan, true, 2),
    (v_user_id, 'Medis / Dokter / Obat', 'stethoscope', '#EF4444', 'expense', v_kesehatan, true, 3);

  -- ── Transportasi ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Transportasi', 'car', '#3B82F6', 'expense', true, 3)
  returning id into v_transportasi;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Bensin / Tol / Parkir', 'gasPump', '#3B82F6', 'expense', v_transportasi, true, 1),
    (v_user_id, 'Transportasi Umum / Ojol', 'motorcycle', '#3B82F6', 'expense', v_transportasi, true, 2),
    (v_user_id, 'Servis Kendaraan', 'wrench', '#3B82F6', 'expense', v_transportasi, true, 3);

  -- ── Tagihan & Kewajiban ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Tagihan & Kewajiban', 'fileInvoiceDollar', '#8B5CF6', 'expense', true, 4)
  returning id into v_tagihan;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Listrik & Air', 'bolt', '#8B5CF6', 'expense', v_tagihan, true, 1),
    (v_user_id, 'Internet & Pulsa', 'wifi', '#8B5CF6', 'expense', v_tagihan, true, 2),
    (v_user_id, 'Cicilan / Asuransi', 'shieldHalved', '#8B5CF6', 'expense', v_tagihan, true, 3);

  -- ── Teknologi & Edukasi ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Teknologi & Edukasi', 'laptop', '#06B6D4', 'expense', true, 5)
  returning id into v_teknologi;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Langganan Digital', 'tv', '#06B6D4', 'expense', v_teknologi, true, 1),
    (v_user_id, 'Kursus / Buku', 'graduationCap', '#06B6D4', 'expense', v_teknologi, true, 2),
    (v_user_id, 'Server & Hosting', 'server', '#06B6D4', 'expense', v_teknologi, true, 3);

  -- ── Keluarga & Sosial ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Keluarga & Sosial', 'peopleGroup', '#EC4899', 'expense', true, 6)
  returning id into v_keluarga;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Kebutuhan Pasangan', 'heart', '#EC4899', 'expense', v_keluarga, true, 1),
    (v_user_id, 'Kondangan / Donasi', 'handHoldingHeart', '#EC4899', 'expense', v_keluarga, true, 2),
    (v_user_id, 'Nongkrong / Hiburan', 'champagneGlasses', '#EC4899', 'expense', v_keluarga, true, 3);

  -- ── Lain-lain (Expense) ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Lain-lain', 'ellipsis', '#6B7280', 'expense', true, 7)
  returning id into v_lainnya_exp;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Biaya Admin / Pajak / Selisih', 'receipt', '#6B7280', 'expense', v_lainnya_exp, true, 1),
    (v_user_id, 'Pengeluaran Tak Terduga', 'triangleExclamation', '#6B7280', 'expense', v_lainnya_exp, true, 2);


  -- ════════════════════════════════════════════════════════════════════════
  -- INCOME CATEGORIES
  -- ════════════════════════════════════════════════════════════════════════

  -- ── Gaji & Pendapatan Utama ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Gaji & Pendapatan Utama', 'briefcase', '#10B981', 'income', true, 1)
  returning id into v_gaji;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Gaji Bulanan', 'moneyBill', '#10B981', 'income', v_gaji, true, 1),
    (v_user_id, 'Bonus / THR', 'gift', '#10B981', 'income', v_gaji, true, 2);

  -- ── Pendapatan Tambahan ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Pendapatan Tambahan', 'circlePlus', '#10B981', 'income', true, 2)
  returning id into v_pendapatan_tambahan;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Pekerjaan Sampingan / Freelance', 'laptopCode', '#10B981', 'income', v_pendapatan_tambahan, true, 1),
    (v_user_id, 'Hasil Investasi / Dividen', 'chartLine', '#10B981', 'income', v_pendapatan_tambahan, true, 2),
    (v_user_id, 'Pencairan Dana', 'moneyBillTransfer', '#10B981', 'income', v_pendapatan_tambahan, true, 3);

  -- ── Lain-lain (Income) ──
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values (v_user_id, 'Lain-lain', 'ellipsis', '#6B7280', 'income', true, 3)
  returning id into v_lainnya_inc;

  insert into public.categories (user_id, name, icon, color, type, parent_id, is_default, sort_order)
  values
    (v_user_id, 'Hadiah / Pemberian', 'handHoldingHeart', '#6B7280', 'income', v_lainnya_inc, true, 1);


  -- ════════════════════════════════════════════════════════════════════════
  -- SYSTEM CATEGORIES
  -- ════════════════════════════════════════════════════════════════════════
  insert into public.categories (user_id, name, icon, color, type, is_default, sort_order)
  values
    (v_user_id, 'Penyesuaian Saldo', 'scaleBalanced', '#9CA3AF', 'system', true, 1),
    (v_user_id, 'Transfer ke Aset', 'rightLeft', '#9CA3AF', 'system', true, 2);

  return new;
end;
$$;
