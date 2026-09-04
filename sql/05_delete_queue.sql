-- ============================================================
-- MIGRATION : file d'attente de suppression Discord
-- (contournement fiable — Realtime n'envoie pas toujours les
-- colonnes complètes sur un DELETE, même avec replica identity full)
-- À exécuter dans Supabase > SQL Editor
-- ============================================================

create table if not exists public.discord_delete_queue (
  id uuid primary key default gen_random_uuid(),
  discord_message_id text not null,
  created_at timestamptz not null default now()
);

alter table public.discord_delete_queue enable row level security;

create policy "delete_queue_insert_table" on public.discord_delete_queue for insert
  with check (public.is_table());

-- Le bot (clé service_role) peut tout lire/supprimer, RLS bypass automatique.

alter publication supabase_realtime add table public.discord_delete_queue;
