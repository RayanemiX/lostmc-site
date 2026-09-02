# The Lost MC — Guide de déploiement complet (étape par étape)

Ce guide t'emmène de zéro jusqu'à un site en ligne et fonctionnel. Suis les étapes **dans l'ordre**, sans en sauter. Prévois environ 45–60 minutes la première fois.

Tu vas utiliser 3 services, tous gratuits pour ce usage :
- **GitHub** → héberge le site (les pages web)
- **Supabase** → la base de données, les comptes, le temps réel
- **Render** (ou équivalent) → fait tourner le bot Discord en continu

---

## Sommaire

1. [Préparer les comptes](#1-préparer-les-comptes)
2. [Créer le projet Supabase](#2-créer-le-projet-supabase)
3. [Créer l'application Discord](#3-créer-lapplication-discord)
4. [Activer la connexion "Se connecter avec Discord"](#4-activer-la-connexion-se-connecter-avec-discord)
5. [Récupérer les fichiers du site et les configurer](#5-récupérer-les-fichiers-du-site-et-les-configurer)
6. [Mettre le site en ligne sur GitHub Pages](#6-mettre-le-site-en-ligne-sur-github-pages)
7. [Te donner l'accès "Table" une première fois](#7-te-donner-laccès-table-une-première-fois)
8. [Récupérer les ID des rôles Discord](#8-récupérer-les-id-des-rôles-discord)
9. [Déployer le bot Discord sur Render](#9-déployer-le-bot-discord-sur-render)
10. [Relier chaque rôle Discord à un rôle du site](#10-relier-chaque-rôle-discord-à-un-rôle-du-site)
11. [Tester le site de bout en bout](#11-tester-le-site-de-bout-en-bout)
12. [Dépannage (problèmes courants)](#12-dépannage-problèmes-courants)
13. [Maintenance et mises à jour](#13-maintenance-et-mises-à-jour)

---

## 1. Préparer les comptes

Crée un compte (gratuit) sur chacun de ces sites si tu n'en as pas déjà :

- [github.com](https://github.com) — pour héberger le site
- [supabase.com](https://supabase.com) — pour la base de données (tu peux te connecter avec ton compte GitHub)
- [render.com](https://render.com) — pour héberger le bot Discord (tu peux te connecter avec ton compte GitHub)

Tu dois aussi être **administrateur du serveur Discord** du Lost MC (ou avoir la permission "Gérer le serveur" / "Gérer les rôles").

Active le **mode développeur** sur ton compte Discord (utile plus tard pour copier des ID) :
`Paramètres utilisateur > Avancés > Mode développeur` → active le bouton.

---

## 2. Créer le projet Supabase

1. Va sur [supabase.com](https://supabase.com) → connecte-toi → clique **New project**.
2. Choisis un nom (ex : `lostmc`), un mot de passe de base de données (note-le quelque part), une région proche de toi. Clique **Create new project**. Patiente ~2 minutes que le projet s'initialise.
3. Une fois le projet ouvert, va dans le menu de gauche **SQL Editor** (icône `</>`).
4. Clique **New query**. Ouvre le fichier `sql/01_schema.sql` (fourni dans l'archive du site), copie tout son contenu, colle-le dans l'éditeur, puis clique **Run** (ou `Ctrl+Entrée`). Tu dois voir "Success. No rows returned".
5. Répète l'étape 4 avec `sql/02_policies.sql` (nouvelle query, copier-coller, Run).
6. Répète l'étape 4 avec `sql/03_seed.sql`.
7. Vérifie que tout s'est bien créé : menu de gauche **Table Editor** → tu dois voir une liste de tables (`profiles`, `announcements`, `treasury_items`, `armory_weapons`, etc.).
8. Va dans **Project Settings** (icône engrenage en bas à gauche) → **API**. Garde cette page ouverte dans un onglet, tu auras besoin dans quelques minutes de :
   - **Project URL**
   - **anon public** key
   - **service_role** key (clique sur "Reveal" pour la voir — ⚠️ ne la partage jamais, ne la mets jamais dans le site)

---

## 3. Créer l'application Discord

1. Va sur le [Discord Developer Portal](https://discord.com/developers/applications) → **New Application**.
2. Donne-lui un nom (ex : `Lost MC Intranet`) → **Create**.
3. Dans le menu de gauche, va sur **OAuth2 > General**. Note (ou garde l'onglet ouvert) :
   - **Client ID**
   - **Client Secret** (clique "Reset Secret" si besoin de le révéler, puis copie-le)
4. Toujours sur cette page, dans **Redirects**, clique **Add Redirect** (tu la complèteras à l'étape suivante avec ton URL Supabase exacte).
5. Dans le menu de gauche, va sur **Bot** :
   - Clique **Reset Token** → copie le token généré et garde-le de côté (tu en auras besoin à l'étape 9). ⚠️ Ne le partage à personne.
   - Active les deux interrupteurs **Privileged Gateway Intents** :
     - **Server Members Intent**
     - **Message Content Intent**
   - Sauvegarde.
6. Toujours dans **Bot**, désactive "Public Bot" si tu ne veux pas que d'autres serveurs puissent l'ajouter (optionnel).

---

## 4. Activer la connexion "Se connecter avec Discord"

1. Retourne sur ton projet **Supabase** → menu de gauche **Authentication > Providers**.
2. Trouve **Discord** dans la liste → active-le.
3. Colle le **Client ID** et le **Client Secret** récupérés à l'étape 3.
4. Supabase t'affiche une **Callback URL** du type `https://xxxxx.supabase.co/auth/v1/callback` → copie-la.
5. Retourne sur le **Discord Developer Portal > OAuth2 > General > Redirects** → colle cette URL dans le champ Redirect créé à l'étape 3.4 → **Save Changes**.
6. Toujours dans Supabase, va dans **Authentication > URL Configuration** :
   - **Site URL** : mets l'URL que ton site GitHub Pages aura (tu la connais déjà si tu choisis ton pseudo/nom de dépôt à l'avance) — format : `https://TON-PSEUDO.github.io/NOM-DU-DEPOT/`
   - **Redirect URLs** : ajoute la même URL.

*(Si tu ne connais pas encore le nom exact du dépôt, reviens ajuster ce champ après l'étape 6.)*

---

## 5. Récupérer les fichiers du site et les configurer

1. Télécharge et dézippe l'archive `lostmc-site.zip` fournie.
2. Ouvre le fichier `js/config.js` avec un éditeur de texte simple (Bloc-notes, VS Code, etc.).
3. Remplace les valeurs :

```js
window.LOSTMC_CONFIG = {
  SUPABASE_URL: "https://xxxxx.supabase.co",       // ton Project URL (étape 2.8)
  SUPABASE_ANON_KEY: "eyJ...",                       // ta clé anon public (étape 2.8)
  SITE_URL: "https://TON-PSEUDO.github.io/NOM-DU-DEPOT/",
};
```

4. Sauvegarde le fichier.

---

## 6. Mettre le site en ligne sur GitHub Pages

### Option A — via l'interface web GitHub (le plus simple, sans ligne de commande)

1. Va sur [github.com](https://github.com) → **New repository**.
2. Nom du dépôt : par exemple `lostmc-site` (note-le, il doit correspondre à `SITE_URL`) → coche **Public** → **Create repository**.
3. Sur la page du dépôt vide, clique **uploading an existing file**.
4. Glisse-dépose **tout le contenu du dossier** (le contenu du dossier `lostmc/`, pas le dossier lui-même) : `index.html`, `login.html`, `css/`, `js/`, `pages/`, `sql/`, `README.md`. (Le dossier `discord-bot/` peut aussi être inclus, il ne sera pas utilisé par GitHub Pages mais ne gêne pas.)
5. En bas de page, clique **Commit changes**.
6. Va dans l'onglet **Settings** du dépôt → menu de gauche **Pages**.
7. Sous **Build and deployment > Source**, choisis **Deploy from a branch**.
8. Sous **Branch**, choisis `main` et le dossier `/ (root)` → **Save**.
9. Patiente 1 à 2 minutes, rafraîchis la page : une bannière verte t'indique l'URL de ton site (`https://TON-PSEUDO.github.io/lostmc-site/`).

### Option B — via Git en ligne de commande

```bash
cd lostmc
git init
git add .
git commit -m "Site The Lost MC"
git branch -M main
git remote add origin https://github.com/TON-PSEUDO/lostmc-site.git
git push -u origin main
```
Puis fais les étapes 6–9 de l'option A pour activer Pages.

### Vérifie l'URL finale

Compare l'URL réelle donnée par GitHub Pages avec celle mise dans `js/config.js` (`SITE_URL`) et dans Supabase (`Site URL` / `Redirect URLs`, étape 4.6). **Elles doivent être identiques, slash final `/` inclus.** Si ce n'est pas le cas, corrige `js/config.js`, ré-upload le fichier sur GitHub (Settings > fichier > éditer > commit), et corrige aussi les URLs dans Supabase.

---

## 7. Te donner l'accès "Table" une première fois

Tant que la synchro Discord n'est pas branchée (étapes suivantes), personne n'a de rôle sur le site. Il faut te débloquer manuellement une fois :

1. Va sur ton site en ligne (`https://TON-PSEUDO.github.io/...`) → clique **Se connecter avec Discord** → autorise l'application.
2. Tu arrives sur `login.html?denied=1` (accès refusé, normal) — c'est OK, ça veut dire que ton compte est bien créé côté Supabase.
3. Retourne dans **Supabase > Table Editor > profiles** : tu dois voir une ligne avec ton `username` et ton `discord_id`. Note son `id` (uuid, colonne `id`).
4. Va dans **Table Editor > member_roles** → clique **Insert row** :
   - `profile_id` : colle l'uuid noté à l'étape précédente
   - `role_key` : `the_lost_mc`
   - Sauvegarde.
5. Refais **Insert row** une deuxième fois avec `role_key` : `table` (même `profile_id`).
6. Retourne sur le site, reconnecte-toi (ou rafraîchis) : tu dois maintenant voir le menu complet, y compris la section **La Table** avec **Paramètres**.

---

## 8. Récupérer les ID des rôles Discord

Sur ton serveur Discord (mode développeur déjà activé à l'étape 1) :

1. Ouvre **Paramètres du serveur > Rôles**.
2. Pour chaque rôle que tu veux relier au site (`TheLostMC`, `La Table`, `Annonceur`, `Rapporteur`, `Recruteur`, et tout rôle personnalisé que tu ajoutes), **clic droit sur le rôle > Copier l'ID du rôle**.
3. Colle chaque ID dans un fichier texte temporaire avec le nom du rôle en face, tu en auras besoin à l'étape 10.

Récupère aussi :
- **L'ID de ton serveur** : clic droit sur l'icône du serveur > Copier l'ID du serveur.
- **L'ID du salon Discord** où sont postées les annonces à relayer vers le site : clic droit sur le salon > Copier l'ID du salon.

---

## 9. Déployer le bot Discord sur Render

1. Sur [render.com](https://render.com), connecte-toi (avec GitHub c'est plus simple).
2. Tu as besoin que le dossier `discord-bot/` soit dans un dépôt GitHub. Deux options :
   - Ajoute-le dans le même dépôt `lostmc-site` que le site (aucun souci, GitHub Pages ignorera ce dossier).
   - Ou crée un second dépôt dédié `lostmc-bot` et mets-y uniquement le contenu de `discord-bot/`.
3. Sur Render, clique **New > Background Worker**.
4. Connecte ton dépôt GitHub, sélectionne le bon dépôt (et si besoin le sous-dossier `discord-bot` dans **Root Directory**).
5. Renseigne :
   - **Build Command** : `npm install`
   - **Start Command** : `npm start`
6. Descends jusqu'à **Environment Variables** → ajoute :

   | Clé | Valeur |
   |---|---|
   | `DISCORD_TOKEN` | le token du bot (étape 3.5) |
   | `SUPABASE_URL` | ton Project URL Supabase (étape 2.8) |
   | `SUPABASE_SERVICE_ROLE_KEY` | ta clé service_role (étape 2.8, ⚠️ secrète) |
   | `GUILD_ID` | l'ID de ton serveur Discord (étape 8) |
   | `ANNOUNCEMENTS_CHANNEL_ID` | l'ID du salon annonces Discord (étape 8) |

7. Clique **Create Background Worker**. Render installe les dépendances et démarre le bot — suis les logs dans l'onglet **Logs** : tu dois voir `Connecté en tant que ...` puis `Synchro initiale des rôles terminée.`

### Inviter le bot sur le serveur

S'il n'y est pas déjà (tu l'as créé à l'étape 3, mais il faut l'inviter) :

1. Discord Developer Portal → ton application → **OAuth2 > URL Generator**.
2. Coche les scopes : `bot`.
3. Coche les permissions : `View Channels`, `Read Message History`, `Send Messages`.
4. Copie l'URL générée en bas, ouvre-la dans ton navigateur, choisis ton serveur, **Autoriser**.

---

## 10. Relier chaque rôle Discord à un rôle du site

1. Retourne sur le site, connecté avec ton compte Table → menu **La Table > Paramètres**.
2. Les 5 rôles de base (`TheLostMC`, `La Table`, `Annonceur`, `Rapporteur`, `Recruteur`) existent déjà (créés par `03_seed.sql`) mais n'ont pas encore d'ID Discord.
3. Pour chacun, si tu veux modifier l'ID Discord lié : la façon la plus simple est via **Supabase > Table Editor > role_definitions** → clique sur la ligne → remplis la colonne `discord_role_id` avec l'ID copié à l'étape 8 → sauvegarde. (Le formulaire "Créer un rôle" de la page Paramètres du site sert surtout à ajouter de **nouveaux** rôles personnalisés plus tard.)
4. Une fois tous les `discord_role_id` renseignés, retourne dans les **logs Render** du bot : il rafraîchit sa correspondance toutes les 5 minutes, ou redémarre le service manuellement (**Manual Deploy > Restart**) pour forcer une resynchro immédiate.
5. Sur Discord, attribue/retire un rôle à un membre test : dans les logs Render tu dois voir une ligne `[roles] Pseudo#0000: +xxx -yyy`. Ce membre doit alors voir apparaître/disparaître les sections correspondantes sur le site (après rafraîchissement ou automatiquement si la page est ouverte, grâce au temps réel).

> Rappel : un membre doit **s'être connecté au moins une fois au site** pour que le bot puisse lui attribuer des rôles (le bot ne peut pas créer de compte, seulement synchroniser les rôles d'un compte déjà créé via la connexion Discord).

---

## 11. Tester le site de bout en bout

Checklist à parcourir avec un compte "membre normal" et un compte "Table" :

- [ ] Connexion Discord fonctionne, refus correct si pas de rôle `TheLostMC`
- [ ] La page d'accueil affiche les dernières annonces, annonces d'activité, devoirs de grade, quotas
- [ ] Ouvrir **Absences**, déclarer une absence, elle apparaît dans **Supabase > Table Editor > absences**
- [ ] Un membre avec le rôle `annonceur` peut publier une **Annonce Activité**, un membre lambda ne peut pas
- [ ] Un membre avec le rôle `rapporteur` peut créer un **Rapport**
- [ ] Un membre lambda peut envoyer une **Demande Table**, un compte Table peut l'accepter/refuser
- [ ] Un compte Table peut créer une ressource de **Trésorerie** (ex. "Minerai d'or") et enregistrer un mouvement
- [ ] Un compte Table peut enregistrer un mouvement dans **Banque du MC**
- [ ] Un compte Table peut ajouter une arme et un mouvement dans **Armurie**
- [ ] Un compte Table peut ouvrir un **Dossier membre** et y ajouter une entrée
- [ ] Poster un message dans le salon Discord "annonces" configuré → il apparaît sur la page **Annonces** du site en quelques secondes, sans recharger la page
- [ ] Ajouter/retirer un rôle Discord à un membre → ses accès sur le site changent en conséquence après resynchro du bot

---

## 12. Dépannage (problèmes courants)

**"Accès refusé" en boucle après connexion Discord**
→ Le compte n'a pas encore le rôle `the_lost_mc` dans `member_roles`. Vérifie l'étape 7 (attribution manuelle) ou l'étape 10 (synchro bot + `discord_role_id` bien renseigné).

**Erreur "Invalid Redirect URL" lors de la connexion Discord**
→ L'URL dans Discord Developer Portal (OAuth2 > Redirects) ne correspond pas exactement à celle donnée par Supabase, ou l'URL du site dans Supabase (`Site URL` / `Redirect URLs`) ne correspond pas exactement à l'URL réelle GitHub Pages (attention au `/` final).

**Le site charge mais rien ne s'affiche / erreurs dans la console**
→ Ouvre les outils développeur du navigateur (F12) > onglet Console. Une erreur `Failed to fetch` ou `Invalid API key` signifie que `js/config.js` contient encore les valeurs par défaut ou une clé incorrecte.

**"new row violates row-level security policy"**
→ Le compte connecté n'a pas le rôle requis pour l'action tentée (ex. essayer d'ajouter une arme sans le rôle `table`). C'est le comportement normal de sécurité — vérifie les rôles du compte concerné.

**Le bot est démarré sur Render mais rien ne se synchronise**
→ Vérifie dans les logs Render qu'il n'y a pas d'erreur d'intents (`Used disallowed intents`) : retourne dans Discord Developer Portal > Bot, et confirme que **Server Members Intent** et **Message Content Intent** sont bien activés, puis redémarre le service Render.

**Les annonces Discord n'apparaissent pas sur le site**
→ Vérifie que `ANNOUNCEMENTS_CHANNEL_ID` correspond bien au salon où tu postes, et que le bot a la permission de lire ce salon.

**Un membre a le bon rôle Discord mais rien ne change sur le site**
→ Il doit s'être connecté au moins une fois sur le site avant que le bot puisse le synchroniser (voir note à la fin de l'étape 10). Redémarre le bot pour forcer une resynchro immédiate au lieu d'attendre les 5 minutes automatiques.

---

## 13. Maintenance et mises à jour

- **Modifier une page du site** : édite le fichier `.html`/`.css`/`.js` concerné, puis sur GitHub, va dans le fichier > icône crayon (Edit) > colle le nouveau contenu > **Commit changes**. Le site se met à jour automatiquement en 1–2 minutes.
- **Ajouter un nouveau rôle** (ex. "Trésorier") : depuis le site, **Paramètres > Créer un rôle**, puis relie son `discord_role_id` (étape 10.3). Pense à adapter les policies SQL (`sql/02_policies.sql`) si ce rôle doit avoir des droits d'écriture particuliers quelque part — sinon il ne donne accès qu'à la lecture, sans droit spécial.
- **Le bot Render s'endort / a des limites sur le plan gratuit** : les workers gratuits Render peuvent se mettre en veille après une période d'inactivité selon le plan choisi ; si la synchro Discord devient lente, envisage un plan payant léger (quelques dollars/mois) ou un autre hébergeur "always-on" (Railway, VPS).
- **Sauvegarde** : Supabase conserve tes données, mais pense à exporter régulièrement (Table Editor > … > Export CSV, ou `pg_dump` via les paramètres avancés) si tu veux une copie de sécurité.
