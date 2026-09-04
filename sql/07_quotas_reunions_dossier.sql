-- ============================================================
-- MIGRATION : quotas hebdomadaires, demandes de réunion,
-- nom de code / id dans le dossier membre
-- À exécuter dans Supabase > SQL Editor
-- ============================================================

-- ---- 1. Quotas hebdomadaires (suivi par membre, par semaine) ----
create table if not exists public.quota_submissions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,              -- lundi de la semaine concernée
  materials_description text,            -- ce que le membre déclare avoir fourni
  status text not null default 'en_attente' check (status in ('en_attente','valide','manquant')),
  validated_by uuid references public.profiles(id),
  validated_at timestamptz,
  created_at timestamptz not null default now(),
  unique (profile_id, week_start)
);

alter table public.quota_submissions enable row level security;

create policy "quota_select" on public.quota_submissions for select
  using (profile_id = auth.uid() or public.is_table());
create policy "quota_insert_self" on public.quota_submissions for insert
  with check (profile_id = auth.uid() or public.is_table());
create policy "quota_update_self_pending" on public.quota_submissions for update
  using (profile_id = auth.uid() and status = 'en_attente');
create policy "quota_update_table" on public.quota_submissions for update
  using (public.is_table());
create policy "quota_delete_table" on public.quota_submissions for delete
  using (public.is_table());

alter publication supabase_realtime add table public.quota_submissions;

-- ---- 2. Demandes de réunion (Table -> relayées vers Discord par le bot) ----
create table if not exists public.meeting_requests (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid references public.profiles(id),
  requester_name text,
  reason text not null,
  proposed_time timestamptz,
  created_at timestamptz not null default now()
);

alter table public.meeting_requests enable row level security;

create policy "meeting_select_table" on public.meeting_requests for select
  using (public.is_table());
create policy "meeting_insert_table" on public.meeting_requests for insert
  with check (public.is_table());

alter publication supabase_realtime add table public.meeting_requests;

-- ---- 3. Dossier membre : nom de code + id ----
alter table public.member_files add column if not exists codename text;
alter table public.member_files add column if not exists member_code text;
