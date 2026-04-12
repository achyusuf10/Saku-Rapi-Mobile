-- ============================================================================
-- SakuRapi Migration 020: User-local day sync for AI quota and budget renewals
-- ============================================================================
-- Goals:
-- 1. Keep timestamps in UTC timestamptz
-- 2. Count AI quota by the user's local calendar day from client-provided date
-- 3. Allow recurring budgets to sync against client local date on demand
-- ============================================================================

alter table public.ai_usage_logs
  add column if not exists usage_date date;

update public.ai_usage_logs
set usage_date = (created_at at time zone 'Asia/Jakarta')::date
where usage_date is null;

alter table public.ai_usage_logs
  alter column usage_date set default current_date,
  alter column usage_date set not null;

create index if not exists idx_ai_usage_logs_user_mode_usage_date
  on public.ai_usage_logs (user_id, mode, usage_date);

drop function if exists public.check_ai_quota(text);

create function public.check_ai_quota(
  p_mode text,
  p_usage_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_daily_limit integer;
  v_today_count integer;
  v_usage_date date := coalesce(p_usage_date, current_date);
begin
  select tier, tier_expires_at
  into v_tier, v_expires_at
  from public.users
  where id = v_user_id;

  if v_tier is null then
    v_tier := 'free';
  end if;

  if v_tier <> 'free' and v_expires_at is not null and v_expires_at < now() then
    update public.users
    set tier = 'free', tier_expires_at = null
    where id = v_user_id;
    v_tier := 'free';
  end if;

  select daily_limit
  into v_daily_limit
  from public.ai_usage_quotas
  where tier = v_tier and mode = p_mode;

  if v_daily_limit is null then
    v_daily_limit := 0;
  end if;

  select count(*)
  into v_today_count
  from public.ai_usage_logs
  where user_id = v_user_id
    and mode = p_mode
    and usage_date = v_usage_date;

  return jsonb_build_object(
    'allowed', v_today_count < v_daily_limit,
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', greatest(v_daily_limit - v_today_count, 0),
    'tier', v_tier
  );
end;
$$;

drop function if exists public.log_ai_usage(text, text);

create function public.log_ai_usage(
  p_mode text,
  p_provider text default 'gemini',
  p_usage_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tier text;
  v_daily_limit integer;
  v_today_count integer;
  v_usage_date date := coalesce(p_usage_date, current_date);
begin
  insert into public.ai_usage_logs (user_id, mode, provider, usage_date)
  values (v_user_id, p_mode, p_provider, v_usage_date);

  select tier
  into v_tier
  from public.users
  where id = v_user_id;

  if v_tier is null then
    v_tier := 'free';
  end if;

  select daily_limit
  into v_daily_limit
  from public.ai_usage_quotas
  where tier = v_tier and mode = p_mode;

  if v_daily_limit is null then
    v_daily_limit := 0;
  end if;

  select count(*)
  into v_today_count
  from public.ai_usage_logs
  where user_id = v_user_id
    and mode = p_mode
    and usage_date = v_usage_date;

  return jsonb_build_object(
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', greatest(v_daily_limit - v_today_count, 0)
  );
end;
$$;

drop function if exists public.get_all_ai_quotas();

create function public.get_all_ai_quotas(
  p_usage_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_result jsonb := '{}';
  v_mode text;
  v_daily_limit integer;
  v_today_count integer;
  v_usage_date date := coalesce(p_usage_date, current_date);
begin
  select tier, tier_expires_at
  into v_tier, v_expires_at
  from public.users
  where id = v_user_id;

  if v_tier is null then
    v_tier := 'free';
  end if;

  if v_tier <> 'free' and v_expires_at is not null and v_expires_at < now() then
    update public.users
    set tier = 'free', tier_expires_at = null
    where id = v_user_id;
    v_tier := 'free';
  end if;

  for v_mode, v_daily_limit in
    select q.mode, q.daily_limit
    from public.ai_usage_quotas q
    where q.tier = v_tier
  loop
    select count(*)
    into v_today_count
    from public.ai_usage_logs
    where user_id = v_user_id
      and mode = v_mode
      and usage_date = v_usage_date;

    v_result := v_result || jsonb_build_object(
      v_mode,
      jsonb_build_object(
        'used', v_today_count,
        'limit', v_daily_limit,
        'remaining', greatest(v_daily_limit - v_today_count, 0)
      )
    );
  end loop;

  v_result := v_result || jsonb_build_object('tier', v_tier);

  return v_result;
end;
$$;

drop function if exists public.auto_renew_budgets();

create function public.auto_renew_budgets(
  p_today date default current_date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_budget record;
  v_new_start date;
  v_new_end date;
  v_new_amount numeric;
  v_remaining numeric;
  v_is_end_of_month boolean;
  v_duration integer;
  v_today date := coalesce(p_today, current_date);
begin
  for v_budget in
    select *
    from public.budgets
    where is_recurring = true
      and end_date < v_today
      and not exists (
        select 1
        from public.budgets b2
        where b2.user_id = budgets.user_id
          and b2.category_id = budgets.category_id
          and b2.wallet_id is not distinct from budgets.wallet_id
          and b2.start_date = budgets.end_date + interval '1 day'
      )
  loop
    case v_budget.period_type
      when 'weekly' then
        v_new_start := v_budget.start_date + interval '7 days';
        v_new_end := v_budget.end_date + interval '7 days';
      when 'monthly' then
        v_new_start := v_budget.start_date + interval '1 month';
        v_new_end := (date_trunc('month', v_new_start) + interval '1 month' - interval '1 day')::date;
      when 'quarterly' then
        v_new_start := v_budget.start_date + interval '3 months';
        v_new_end := (date_trunc('month', v_new_start) + interval '3 months' - interval '1 day')::date;
      when 'yearly' then
        v_new_start := v_budget.start_date + interval '1 year';
        v_new_end := v_budget.end_date + interval '1 year';
      when 'custom' then
        v_is_end_of_month := v_budget.end_date = (
          date_trunc('month', v_budget.end_date) + interval '1 month' - interval '1 day'
        )::date;
        v_duration := v_budget.end_date - v_budget.start_date;
        v_new_start := v_budget.end_date + interval '1 day';

        if v_is_end_of_month then
          v_new_end := (
            date_trunc('month', v_new_start + (v_duration || ' days')::interval)
            + interval '1 month'
            - interval '1 day'
          )::date;
        else
          v_new_end := v_new_start + (v_duration || ' days')::interval;
        end if;
      else
        v_duration := v_budget.end_date - v_budget.start_date;
        v_new_start := v_budget.end_date + interval '1 day';
        v_new_end := v_new_start + (v_duration || ' days')::interval;
    end case;

    v_new_amount := v_budget.amount;
    if v_budget.carry_forward then
      v_remaining := v_budget.amount - v_budget.used_amount;
      if v_remaining > 0 then
        v_new_amount := v_budget.amount + v_remaining;
      end if;
    end if;

    insert into public.budgets (
      user_id,
      category_id,
      wallet_id,
      amount,
      start_date,
      end_date,
      is_recurring,
      period_type,
      carry_forward
    ) values (
      v_budget.user_id,
      v_budget.category_id,
      v_budget.wallet_id,
      v_new_amount,
      v_new_start,
      v_new_end,
      true,
      v_budget.period_type,
      v_budget.carry_forward
    );

  end loop;
end;
$$;
