-- ============================================================
-- THE LOST MC — SCHEMA SUPABASE
-- À exécuter dans Supabase > SQL Editor, dans l'ordre des fichiers
-- 01_schema.sql -> 02_policies.sql -> 03_seed.sql
-- ============================================================

-- Extension utile pour UUID
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1. PROFILS (miroir des comptes Discord connectés)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  discord_id text unique not null,
  username text not null,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. RÔLES — définis sur Discord, reflétés ici par le bot
--    (correspondance discord_role_id <-> rôle logique du site)
-- ------------------------------------------------------------
create table if not exists public.role_definitions (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,          -- ex: 'the_lost_mc', 'table', 'annonceur', 'rapporteur', 'recruteur'
  label text not null,               -- ex: 'La Table'
  discord_role_id text,              -- id du rôle Discord correspondant (rempli côté site dans Paramètres)
  color text default '#8a2418',
  created_at timestamptz not null default now()
);

create table if not exists public.member_roles (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role_key text not null references public.role_definitions(key) on delete cascade,
  granted_at timestamptz not null default now(),
  primary key (profile_id, role_key)
);

-- ------------------------------------------------------------
-- 3. ANNONCES (générales) — peuvent venir du site ou de Discord
-- ------------------------------------------------------------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  author_id uuid references public.profiles(id),
  author_name text,
  source text not null default 'site',  -- 'site' | 'discord'
  pinned boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4. ANNONCES ACTIVITÉ (gérées par rôle "annonceur"/table)
-- ------------------------------------------------------------
create table if not exists public.activity_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  event_date timestamptz,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 5. HIÉRARCHIE
-- ------------------------------------------------------------
create table if not exists public.hierarchy (
  id uuid primary key default gen_random_uuid(),
  grade_label text not null,          -- ex: "Président", "Sergent d'armes"...
  grade_order int not null default 0, -- pour l'ordre d'affichage
  profile_id uuid references public.profiles(id),
  member_name text,                   -- fallback si profil pas encore lié
  duties text,                        -- devoirs / responsabilités du grade
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 6. TRÉSORERIE — items dynamiques + mouvements
-- ------------------------------------------------------------
create table if not exists public.treasury_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,                 -- ex: "Minerai d'or"
  unit text default 'unité',
  quantity numeric not null default 0,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.treasury_transactions (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.treasury_items(id) on delete cascade,
  type text not null check (type in ('entree','sortie')),
  quantity numeric not null check (quantity > 0),
  note text,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 7. BANQUE DU MC — argent (entrées/sorties), gérée par la Table
-- ------------------------------------------------------------
create table if not exists public.bank_transactions (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('entree','sortie')),
  amount numeric not null check (amount > 0),
  reason text not null,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 8. ARMURIE — stock d'armes, géré par la Table
-- ------------------------------------------------------------
create table if not exists public.armory_weapons (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  quantity numeric not null default 0,
  unit_price numeric,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.armory_transactions (
  id uuid primary key default gen_random_uuid(),
  weapon_id uuid not null references public.armory_weapons(id) on delete cascade,
  type text not null check (type in ('entree','sortie','vente')),
  quantity numeric not null check (quantity > 0),
  amount numeric,          -- montant si vente
  note text,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 9. RAPPORTS
-- ------------------------------------------------------------
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  concerned_member text,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 10. ABSENCES
-- ------------------------------------------------------------
create table if not exists public.absences (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  member_name text,
  start_date date not null,
  end_date date not null,
  reason text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 11. DEMANDES À LA TABLE
-- ------------------------------------------------------------
create table if not exists public.table_requests (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  status text not null default 'en_attente', -- en_attente | acceptee | refusee
  author_id uuid references public.profiles(id),
  author_name text,
  handled_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 12. DOSSIERS MEMBRES (casier judiciaire interne)
-- ------------------------------------------------------------
create table if not exists public.member_files (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id),
  member_name text not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.member_file_entries (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.member_files(id) on delete cascade,
  entry_type text not null default 'note', -- note | sanction | avertissement | felicitation
  content text not null,
  author_id uuid references public.profiles(id),
  author_name text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 13. QUOTAS (rappel sur la home)
-- ------------------------------------------------------------
create table if not exists public.quotas (
  id uuid primary key default gen_random_uuid(),
  grade_label text not null,
  description text not null,
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Trigger générique updated_at
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_hierarchy_updated on public.hierarchy;
create trigger trg_hierarchy_updated before update on public.hierarchy
  for each row execute function public.set_updated_at();

drop trigger if exists trg_requests_updated on public.table_requests;
create trigger trg_requests_updated before update on public.table_requests
  for each row execute function public.set_updated_at();
