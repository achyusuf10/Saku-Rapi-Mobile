-- ============================================================================
-- SakuRapi Migration 007: pg_cron Jobs & Storage
-- ============================================================================
-- 1. auto_renew_budgets: Daily job untuk clone recurring budgets (§3.1)
-- 2. Storage bucket untuk attachments
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
-- 1. auto_renew_budgets() — Clone expired recurring budgets
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.auto_renew_budgets()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_budget record;
  v_new_start date;
  v_new_end date;
  v_duration interval;
begin
  -- Find all recurring budgets that have ended
  for v_budget in
    select *
    from public.budgets
    where is_recurring = true
      and end_date < current_date
      -- Don't create if a renewal already exists for the next period
      and not exists (
        select 1 from public.budgets b2
        where b2.user_id = budgets.user_id
          and b2.category_id = budgets.category_id
          and b2.wallet_id is not distinct from budgets.wallet_id
          and b2.start_date = budgets.end_date + interval '1 day'
      )
  loop
    -- Calculate same duration for the new period
    v_duration := v_budget.end_date - v_budget.start_date;
    v_new_start := v_budget.end_date + interval '1 day';
    v_new_end := v_new_start + v_duration;

    insert into public.budgets (
      user_id, category_id, wallet_id, amount,
      start_date, end_date, is_recurring
    ) values (
      v_budget.user_id, v_budget.category_id, v_budget.wallet_id,
      v_budget.amount, v_new_start, v_new_end, true
    );
  end loop;
end;
$$;

-- Schedule: run daily at 00:05 Asia/Jakarta (17:05 UTC previous day)
-- NOTE: pg_cron harus di-enable dulu di Supabase Dashboard > Database > Extensions
-- Uncomment setelah pg_cron extension aktif:
--
-- select cron.schedule(
--   'auto-renew-budgets',
--   '5 17 * * *',  -- 00:05 WIB
--   $$ select public.auto_renew_budgets() $$
-- );


-- ════════════════════════════════════════════════════════════════════════════
-- 2. Storage bucket for transaction attachments
-- ════════════════════════════════════════════════════════════════════════════
-- Bucket dibuat via Supabase Dashboard atau SQL:
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'attachments',
  'attachments',
  false,
  5242880,  -- 5MB max
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do nothing;

-- Storage RLS: owner-only access
create policy "attachments_select_own"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "attachments_insert_own"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "attachments_delete_own"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text);

-- Avatar bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,  -- public readable for profile display
  2097152,  -- 2MB max
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "avatars_select_public"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars');

create policy "avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
