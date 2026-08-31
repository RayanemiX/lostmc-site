# The Lost MC — Intranet

Site statique (GitHub Pages) + base de données/auth/realtime Supabase + bot Discord de synchro.

## Architecture

```
GitHub Pages (site statique)  <-->  Supabase (Postgres + Auth + Realtime)  <-->  Bot Discord (Render/Railway)
```

- Le **site** ne contient aucune donnée sensible : il utilise la clé publique **anon** de Supabase, protégée par des règles de sécurité (RLS) qui filtrent ce que chaque rôle peut voir/modifier.
- Le **bot Discord** tourne en continu ailleurs que sur GitHub Pages (GitHub Pages ne peut pas faire tourner de processus serveur) et utilise la clé **service_role**, secrète, pour écrire dans Supabase sans restriction — c'est lui qui répercute les rôles et les annonces Discord vers le site.

---

## 1. Créer le projet Supabase

1. Va sur [supabase.com](https://supabase.com) → *New project*.
2. Une fois créé, ouvre **SQL Editor** et exécute, **dans l'ordre**, le contenu de :
   - `sql/01_schema.sql`
   - `sql/02_policies.sql`
   - `sql/03_seed.sql`
3. Dans **Project Settings > API**, note :
   - `Project URL`
   - `anon public key`
   - `service_role key` (⚠️ à garder secrète, jamais dans le code du site)

## 2. Activer la connexion Discord (Supabase Auth)

1. Sur le [Discord Developer Portal](https://discord.com/developers/applications), crée une application (ou réutilise celle de ton bot).
2. Onglet **OAuth2** : ajoute cette Redirect URL :
   `https://<ton-projet>.supabase.co/auth/v1/callback`
3. Récupère le **Client ID** et le **Client Secret**.
4. Dans Supabase : **Authentication > Providers > Discord**, active-le et colle Client ID / Secret.
5. Dans **Authentication > URL Configuration**, mets ton URL GitHub Pages comme *Site URL* (ex. `https://tonpseudo.github.io/lostmc-site/`) et ajoute-la aux *Redirect URLs*.

## 3. Configurer le site

Modifie `js/config.js` :

```js
window.LOSTMC_CONFIG = {
  SUPABASE_URL: "https://TON-PROJET.supabase.co",
  SUPABASE_ANON_KEY: "ta_clé_anon_publique",
  SITE_URL: "https://tonpseudo.github.io/lostmc-site/",
};
```

## 4. Déployer sur GitHub Pages

```bash
# depuis le dossier du site (celui qui contient index.html)
git init
git add .
git commit -m "Site The Lost MC"
git branch -M main
git remote add origin https://github.com/TON-PSEUDO/lostmc-site.git
git push -u origin main
```

Puis sur GitHub : **Settings > Pages > Source : branche `main`, dossier `/ (root)`**. Le site sera en ligne à l'URL indiquée après quelques minutes.

⚠️ Le dépôt GitHub peut être **public**, ce n'est pas un problème de sécurité : le site n'embarque que la clé **anon**, dont l'usage est filtré par les règles RLS. Ne mets **jamais** la clé `service_role` dans ce dépôt.

## 5. Configurer les rôles

1. Connecte-toi une première fois au site avec un compte Discord ayant les droits d'admin sur le serveur (tu n'auras pas encore accès, c'est normal — voir étape 6).
2. Dans **Discord**, active le *Mode développeur* (Paramètres > Avancés), puis clic droit sur chaque rôle du serveur (`TheLostMC`, `La Table`, `Annonceur`, `Rapporteur`, `Recruteur`, etc.) > *Copier l'ID*.
3. Une fois le bot lancé et un premier membre "Table" synchronisé manuellement (étape 6), va dans **Paramètres** (menu Table du site) et colle chaque ID Discord en face du rôle logique correspondant.

## 6. Déployer le bot Discord (synchro rôles + annonces)

Le bot ne peut pas tourner sur GitHub Pages. Utilise un hébergeur qui garde un processus actif en continu (Render, Railway, Fly.io, un petit VPS...). Exemple avec **Render** (gratuit) :

1. Va dans `discord-bot/`, crée un dépôt Git séparé (ou un sous-dossier de ton repo) et pousse-le sur GitHub.
2. Sur [render.com](https://render.com) → *New > Background Worker* (ou *Web Service* si Render exige un port, peu importe pour un bot).
3. Build command : `npm install` — Start command : `npm start`.
4. Ajoute les variables d'environnement (voir `discord-bot/.env.example`) :
   - `DISCORD_TOKEN` (Developer Portal > Bot > Reset Token)
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GUILD_ID`
   - `ANNOUNCEMENTS_CHANNEL_ID`
5. Sur le Developer Portal, onglet **Bot** : active les intents privilégiés **Server Members Intent** et **Message Content Intent**.
6. Invite le bot sur ton serveur avec les permissions *Read Messages*, *View Channels* (scope `bot`).
7. Démarre le service : au premier lancement, le bot synchronise automatiquement les rôles de tous les membres déjà connectés au moins une fois au site.

### Étape de démarrage manuelle (première Table)

Tant que `role_definitions.discord_role_id` n'est pas rempli, le bot ne peut rien synchroniser automatiquement. Pour te donner accès une première fois :
1. Connecte-toi au site une fois (crée ta ligne dans `profiles`).
2. Dans Supabase **Table Editor > member_roles**, insère manuellement une ligne `profile_id = ton id / role_key = 'table'`.
3. Reconnecte-toi au site → tu as maintenant le menu Table, avec **Paramètres**, pour finir la configuration proprement depuis l'interface.

---

## Fonctionnement en temps réel

Chaque page utilise `supabase.channel(...).on('postgres_changes', ...)` pour s'abonner aux tables concernées : toute modification (site ou faite par le bot depuis Discord) apparaît instantanément chez tous les membres connectés, sans recharger la page.

## Structure du site

```
index.html              Accueil / dashboard
login.html               Connexion Discord
css/style.css             Style "intranet privé"
js/config.js               Clés Supabase (à remplir)
js/supabase-client.js
js/auth.js                  Session, profil, rôles
js/layout.js                Sidebar/topbar dynamiques selon les rôles
pages/
  annonces.html
  annonces-activite.html
  hierarchie.html
  tresorerie.html
  rapports.html
  demande-table.html
  table/
    annonces-admin.html
    membres.html
    dossier-membre.html
    banque.html
    armurie.html
    parametres.html
sql/                        Schéma + policies + seed Supabase
discord-bot/                Bot Node.js (hébergé séparément)
```

## Limites connues de cette V1

- La page Trésorerie / Armurie recalculent le stock côté client (deux requêtes) plutôt que par trigger SQL — suffisant à l'échelle d'un MC, mais un trigger `AFTER INSERT` serait plus robuste si le volume grossit beaucoup.
- La radio (page d'accueil) est un simple lecteur `<audio>` : ajoute l'URL de ton flux dans `index.html`.
- Aucune photo de fond n'a pu être intégrée (non reçue dans la conversation) : le style actuel est un thème sombre "intranet sécurisé" que tu peux ajuster dans `css/style.css`.
