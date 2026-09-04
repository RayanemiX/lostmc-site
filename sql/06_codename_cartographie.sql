-- ============================================================
-- MIGRATION : nom de code, cartographie, retrait trésorerie
-- À exécuter dans Supabase > SQL Editor
-- ============================================================

-- ---- 1. Nom de code (au lieu du pseudo Discord affiché) ----
alter table public.profiles add column if not exists codename text;
alter table public.profiles add column if not exists member_code text;

-- ---- 2. Cartographie (marqueurs emoji sur la carte GTA) ----
create table if not exists public.map_markers (
  id uuid primary key default gen_random_uuid(),
  x numeric not null,           -- position en % (0-100) depuis la gauche
  y numeric not null,           -- position en % (0-100) depuis le haut
  emoji text not null,
  label text,
  created_by uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

alter table public.map_markers enable row level security;

create policy "map_markers_select" on public.map_markers for select
  using (public.is_member());
create policy "map_markers_insert" on public.map_markers for insert
  with check (public.is_member());
create policy "map_markers_delete" on public.map_markers for delete
  using (created_by = auth.uid() or public.is_table());

alter publication supabase_realtime add table public.map_markers;

-- ---- 3. Retrait de la trésorerie ----
-- On ne supprime pas les données par sécurité, on retire juste l'accès.
-- Si tu veux vraiment tout effacer plus tard :
-- drop table if exists public.treasury_transactions;
-- drop table if exists public.treasury_items;
