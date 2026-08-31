-- ============================================================
-- THE LOST MC — RLS POLICIES
-- Exécuter après 01_schema.sql
-- ============================================================

-- ------------------------------------------------------------
-- Fonctions utilitaires : a-t-on tel rôle ?
-- ------------------------------------------------------------
create or replace function public.has_role(role_key_param text)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.member_roles mr
    where mr.profile_id = auth.uid() and mr.role_key = role_key_param
  );
$$;

create or replace function public.is_member()
returns boolean language sql security definer stable as $$
  select public.has_role('the_lost_mc');
$$;

create or replace function public.is_table()
returns boolean language sql security definer stable as $$
  select public.has_role('table');
$$;

-- ------------------------------------------------------------
-- Activation RLS sur toutes les tables
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.role_definitions enable row level security;
alter table public.member_roles enable row level security;
alter table public.announcements enable row level security;
alter table public.activity_announcements enable row level security;
alter table public.hierarchy enable row level security;
alter table public.treasury_items enable row level security;
alter table public.treasury_transactions enable row level security;
alter table public.bank_transactions enable row level security;
alter table public.armory_weapons enable row level security;
alter table public.armory_transactions enable row level security;
alter table public.reports enable row level security;
alter table public.absences enable row level security;
alter table public.table_requests enable row level security;
alter table public.member_files enable row level security;
alter table public.member_file_entries enable row level security;
alter table public.quotas enable row level security;

-- ------------------------------------------------------------
-- PROFILES : chaque membre voit son profil + la Table voit tout
-- ------------------------------------------------------------
create policy "profiles_select_member" on public.profiles for select
  using (public.is_member());
create policy "profiles_update_self" on public.profiles for update
  using (id = auth.uid());
create policy "profiles_insert_self" on public.profiles for insert
  with check (id = auth.uid());
-- La synchro des rôles (member_roles) se fait via la clé service_role côté bot (bypass RLS)

-- ------------------------------------------------------------
-- ROLE_DEFINITIONS : lecture par tout membre, écriture par la Table
-- ------------------------------------------------------------
create policy "roles_select_member" on public.role_definitions for select
  using (public.is_member());
create policy "roles_write_table" on public.role_definitions for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- MEMBER_ROLES : lecture par tout membre (pour affichage), écriture Table
-- ------------------------------------------------------------
create policy "member_roles_select" on public.member_roles for select
  using (public.is_member());
create policy "member_roles_write_table" on public.member_roles for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- ANNOUNCEMENTS : lecture tout membre, écriture Table (les annonces
-- générales restent pilotées par la Table / Discord)
-- ------------------------------------------------------------
create policy "announcements_select" on public.announcements for select
  using (public.is_member());
create policy "announcements_write_table" on public.announcements for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- ACTIVITY_ANNOUNCEMENTS : lecture tout membre,
-- écriture par rôle 'annonceur' ou 'table'
-- ------------------------------------------------------------
create policy "activity_select" on public.activity_announcements for select
  using (public.is_member());
create policy "activity_write" on public.activity_announcements for all
  using (public.has_role('annonceur') or public.is_table())
  with check (public.has_role('annonceur') or public.is_table());

-- ------------------------------------------------------------
-- HIERARCHY : lecture tout membre, écriture Table
-- ------------------------------------------------------------
create policy "hierarchy_select" on public.hierarchy for select
  using (public.is_member());
create policy "hierarchy_write_table" on public.hierarchy for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- TRÉSORERIE : lecture tout membre, écriture uniquement Table
-- ------------------------------------------------------------
create policy "treasury_items_select" on public.treasury_items for select
  using (public.is_member());
create policy "treasury_items_write_table" on public.treasury_items for all
  using (public.is_table()) with check (public.is_table());

create policy "treasury_tx_select" on public.treasury_transactions for select
  using (public.is_member());
create policy "treasury_tx_write_table" on public.treasury_transactions for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- BANQUE DU MC : lecture tout membre, écriture uniquement Table
-- ------------------------------------------------------------
create policy "bank_select" on public.bank_transactions for select
  using (public.is_member());
create policy "bank_write_table" on public.bank_transactions for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- ARMURIE : lecture + écriture réservées à la Table uniquement
-- ------------------------------------------------------------
create policy "armory_weapons_all_table" on public.armory_weapons for all
  using (public.is_table()) with check (public.is_table());
create policy "armory_tx_all_table" on public.armory_transactions for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- RAPPORTS : lecture Table, écriture rôle 'rapporteur' ou Table
-- (un rapporteur peut aussi voir ses propres rapports)
-- ------------------------------------------------------------
create policy "reports_select" on public.reports for select
  using (public.is_table() or author_id = auth.uid());
create policy "reports_write" on public.reports for insert
  with check (public.has_role('rapporteur') or public.is_table());
create policy "reports_update" on public.reports for update
  using (public.is_table() or author_id = auth.uid());
create policy "reports_delete" on public.reports for delete
  using (public.is_table());

-- ------------------------------------------------------------
-- ABSENCES : chaque membre déclare/voit les siennes, Table voit tout
-- ------------------------------------------------------------
create policy "absences_select" on public.absences for select
  using (profile_id = auth.uid() or public.is_table());
create policy "absences_insert" on public.absences for insert
  with check (profile_id = auth.uid());
create policy "absences_update_own" on public.absences for update
  using (profile_id = auth.uid() or public.is_table());
create policy "absences_delete" on public.absences for delete
  using (profile_id = auth.uid() or public.is_table());

-- ------------------------------------------------------------
-- DEMANDES TABLE : tout membre crée, Table lit/traite tout,
-- l'auteur voit ses propres demandes
-- ------------------------------------------------------------
create policy "requests_select" on public.table_requests for select
  using (author_id = auth.uid() or public.is_table());
create policy "requests_insert" on public.table_requests for insert
  with check (author_id = auth.uid());
create policy "requests_update_table" on public.table_requests for update
  using (public.is_table());

-- ------------------------------------------------------------
-- DOSSIERS MEMBRES : réservés à la Table + rôle 'recruteur'
-- ------------------------------------------------------------
create policy "member_files_all" on public.member_files for all
  using (public.is_table() or public.has_role('recruteur'))
  with check (public.is_table() or public.has_role('recruteur'));
create policy "member_file_entries_all" on public.member_file_entries for all
  using (public.is_table() or public.has_role('recruteur'))
  with check (public.is_table() or public.has_role('recruteur'));

-- ------------------------------------------------------------
-- QUOTAS : lecture tout membre, écriture Table
-- ------------------------------------------------------------
create policy "quotas_select" on public.quotas for select
  using (public.is_member());
create policy "quotas_write_table" on public.quotas for all
  using (public.is_table()) with check (public.is_table());

-- ------------------------------------------------------------
-- Realtime : activer la réplication sur les tables clés
-- ------------------------------------------------------------
alter publication supabase_realtime add table public.announcements;
alter publication supabase_realtime add table public.activity_announcements;
alter publication supabase_realtime add table public.hierarchy;
alter publication supabase_realtime add table public.treasury_items;
alter publication supabase_realtime add table public.treasury_transactions;
alter publication supabase_realtime add table public.bank_transactions;
alter publication supabase_realtime add table public.armory_weapons;
alter publication supabase_realtime add table public.armory_transactions;
alter publication supabase_realtime add table public.table_requests;
alter publication supabase_realtime add table public.absences;
alter publication supabase_realtime add table public.member_roles;
