-- ============================================================
-- THE LOST MC — SEED (données de départ)
-- Exécuter après 01_schema.sql et 02_policies.sql
-- ============================================================

insert into public.role_definitions (key, label, color) values
  ('the_lost_mc', 'TheLostMC', '#8a2418'),
  ('table', 'La Table', '#c99a2e'),
  ('annonceur', 'Annonceur', '#3a6ea5'),
  ('rapporteur', 'Rapporteur', '#5a8f5a'),
  ('recruteur', 'Recruteur', '#7a5a9a')
on conflict (key) do nothing;

-- Astuce : après création, va dans Paramètres > Rôles sur le site pour
-- coller l'ID du rôle Discord correspondant à chaque rôle logique
-- (clic droit sur le rôle dans Discord > Copier l'ID, avec le mode
-- développeur activé dans Discord).
