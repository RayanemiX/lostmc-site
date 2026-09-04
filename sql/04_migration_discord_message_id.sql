-- ============================================================
-- MIGRATION : lien annonce <-> message Discord (pour permettre
-- au bot de supprimer le message Discord quand l'annonce est
-- supprimée depuis le site, et inversement).
-- À exécuter dans Supabase > SQL Editor
-- ============================================================

alter table public.announcements
  add column if not exists discord_message_id text;

-- Nécessaire pour que les événements Realtime DELETE contiennent
-- la ligne complète (dont discord_message_id), pas seulement l'id.
alter table public.announcements replica identity full;
