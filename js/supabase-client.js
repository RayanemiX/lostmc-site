// Initialise le client Supabase (chargé via CDN dans chaque page avant ce fichier)
window.sb = supabase.createClient(
  window.LOSTMC_CONFIG.SUPABASE_URL,
  window.LOSTMC_CONFIG.SUPABASE_ANON_KEY
);
