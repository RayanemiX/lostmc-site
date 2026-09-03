// ============================================================
// AUTH — connexion Discord via Supabase Auth, gating par rôle
// ============================================================

const LostMCAuth = {
  session: null,
  profile: null,
  roles: [], // ex: ['the_lost_mc', 'table', 'annonceur']

  async signInWithDiscord() {
    await sb.auth.signInWithOAuth({
      provider: "discord",
      options: { redirectTo: window.LOSTMC_CONFIG.SITE_URL + "index.html" },
    });
  },

  async signOut() {
    await sb.auth.signOut();
    window.location.href = window.LOSTMC_CONFIG.SITE_URL + "login.html";
  },

  // Charge la session + le profil + les rôles depuis Supabase.
  // Crée le profil au premier login (upsert).
  async loadCurrentUser() {
    const { data: { session } } = await sb.auth.getSession();
    this.session = session;
    if (!session) return null;

    const u = session.user;
    const discordId = u.user_metadata?.provider_id || u.user_metadata?.sub || u.id;
    const username = u.user_metadata?.full_name || u.user_metadata?.name || u.user_metadata?.custom_claims?.global_name || "Membre";
    const avatar = u.user_metadata?.avatar_url || null;

    // upsert profil (autorisé par la policy profiles_insert_self / update_self)
    await sb.from("profiles").upsert({
      id: u.id,
      discord_id: discordId,
      username,
      avatar_url: avatar,
    }, { onConflict: "id" });

    const { data: profile } = await sb.from("profiles").select("*").eq("id", u.id).single();
    this.profile = profile;

    const { data: roleRows } = await sb.from("member_roles").select("role_key").eq("profile_id", u.id);
    this.roles = (roleRows || []).map(r => r.role_key);

    return { session, profile, roles: this.roles };
  },

  hasRole(key) { return this.roles.includes(key); },
  isMember() { return this.hasRole("the_lost_mc"); },
  isTable() { return this.hasRole("table"); },

  // Nom affiché partout sur le site : le "nom de code" choisi par le membre,
  // ou son pseudo Discord tant qu'il n'en a pas encore défini un.
  displayName() {
    return this.profile?.codename || this.profile?.username || "Membre";
  },

  // Ouvre une fenêtre obligatoire pour choisir un nom de code si absent.
  async ensureCodename() {
    if (this.profile?.codename) return;
    await new Promise((resolve) => {
      LostMC_editModal("Choisis ton nom de code", [
        { key: "codename", label: "Nom de code (visible sur le site)", required: true },
        { key: "member_code", label: "Code membre / ID (optionnel)" },
      ], async (values) => {
        const { error } = await sb.from("profiles").update({
          codename: values.codename,
          member_code: values.member_code || null,
        }).eq("id", this.profile.id);
        if (!error) {
          this.profile.codename = values.codename;
          this.profile.member_code = values.member_code || null;
        }
        resolve();
      }, { hideCancel: true, intro: "Ce nom sera affiché à la place de ton pseudo Discord partout sur le site." });
    });
  },

  // Protège une page : redirige vers login si pas connecté ou pas membre.
  // requiredRoles (optionnel) : tableau — il faut au moins un de ces rôles en plus d'être membre.
  async guardPage(requiredRoles = []) {
    const result = await this.loadCurrentUser();
    if (!result) {
      window.location.href = window.LOSTMC_CONFIG.SITE_URL + "login.html";
      return null;
    }
    if (!this.isMember()) {
      window.location.href = window.LOSTMC_CONFIG.SITE_URL + "login.html?denied=1";
      return null;
    }
    if (requiredRoles.length && !this.isTable() && !requiredRoles.some(r => this.hasRole(r))) {
      document.getElementById("app").innerHTML =
        `<div class="access-denied"><h2>Accès refusé</h2><p>Cette section nécessite un rôle spécifique que tu ne possèdes pas.</p></div>`;
      return null;
    }
    await this.ensureCodename();
    return result;
  },
};

window.LostMCAuth = LostMCAuth;
