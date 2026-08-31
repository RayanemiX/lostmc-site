// ============================================================
// THE LOST MC — BOT DE SYNCHRO DISCORD <-> SUPABASE
// À héberger en continu (Render / Railway / VPS), PAS sur GitHub Pages.
//
// Ce bot :
// 1) Synchronise les rôles Discord -> table Supabase member_roles
//    (dès qu'un membre reçoit/perd un rôle sur Discord)
// 2) Relaie les messages postés dans un salon "annonces" Discord
//    -> table Supabase announcements (source = 'discord')
// ============================================================

const { Client, GatewayIntentBits, Partials } = require("discord.js");
const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const {
  DISCORD_TOKEN,
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY, // clé service_role (secrète, jamais côté site !)
  GUILD_ID,
  ANNOUNCEMENTS_CHANNEL_ID,
} = process.env;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMembers,   // nécessite l'intent privilégié "Server Members" activé sur le portail Discord
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent, // nécessite l'intent privilégié "Message Content" activé
  ],
  partials: [Partials.GuildMember, Partials.Message, Partials.Channel],
});

// ---- Cache des rôles configurés côté site (key <-> discord_role_id) ----
let roleMap = []; // [{ key, discord_role_id }]
async function refreshRoleMap() {
  const { data, error } = await supabase.from("role_definitions").select("key, discord_role_id");
  if (error) { console.error("Erreur chargement role_definitions:", error.message); return; }
  roleMap = (data || []).filter(r => r.discord_role_id);
}

// ---- S'assure qu'un profil existe dans Supabase pour ce membre Discord ----
async function ensureProfile(member) {
  // On cherche un profil déjà lié (créé au premier login via OAuth Discord sur le site)
  const { data: existing } = await supabase
    .from("profiles")
    .select("id")
    .eq("discord_id", member.id)
    .maybeSingle();

  if (existing) return existing.id;

  // Si le membre ne s'est jamais connecté au site, on ne peut pas créer sa ligne
  // auth.users (réservé à Supabase Auth). On attend simplement sa première connexion.
  return null;
}

// ---- Synchronise les rôles d'un membre Discord vers member_roles ----
async function syncMemberRoles(member) {
  const profileId = await ensureProfile(member);
  if (!profileId) return; // pas encore connecté au site, rien à synchroniser

  const memberRoleIds = member.roles.cache.map(r => r.id);
  const desiredKeys = roleMap
    .filter(r => memberRoleIds.includes(r.discord_role_id))
    .map(r => r.key);

  const { data: currentRows } = await supabase
    .from("member_roles").select("role_key").eq("profile_id", profileId);
  const currentKeys = (currentRows || []).map(r => r.role_key);

  const toAdd = desiredKeys.filter(k => !currentKeys.includes(k));
  const toRemove = currentKeys.filter(k => !desiredKeys.includes(k));

  if (toAdd.length) {
    await supabase.from("member_roles").insert(toAdd.map(role_key => ({ profile_id: profileId, role_key })));
  }
  for (const role_key of toRemove) {
    await supabase.from("member_roles").delete().eq("profile_id", profileId).eq("role_key", role_key);
  }
  if (toAdd.length || toRemove.length) {
    console.log(`[roles] ${member.user.tag}: +${toAdd.join(",")||"-"} -${toRemove.join(",")||"-"}`);
  }
}

client.once("ready", async () => {
  console.log(`Connecté en tant que ${client.user.tag}`);
  await refreshRoleMap();

  // Sync initiale de tous les membres du serveur
  const guild = await client.guilds.fetch(GUILD_ID);
  const members = await guild.members.fetch();
  for (const [, member] of members) {
    await syncMemberRoles(member);
  }
  console.log("Synchro initiale des rôles terminée.");

  // Rafraîchit la table de correspondance des rôles toutes les 5 minutes
  setInterval(refreshRoleMap, 5 * 60 * 1000);
});

// Déclenché à chaque changement de rôle sur un membre
client.on("guildMemberUpdate", async (oldMember, newMember) => {
  await refreshRoleMap();
  await syncMemberRoles(newMember);
});

// Nouveau membre arrivé (au cas où il a déjà des rôles auto-attribués)
client.on("guildMemberAdd", async (member) => {
  await syncMemberRoles(member);
});

// Relaie les annonces postées dans le salon Discord dédié
client.on("messageCreate", async (message) => {
  if (message.author.bot) return;
  if (message.channelId !== ANNOUNCEMENTS_CHANNEL_ID) return;
  if (!message.content?.trim()) return;

  const { data: profile } = await supabase
    .from("profiles").select("id, username").eq("discord_id", message.author.id).maybeSingle();

  const firstLine = message.content.split("\n")[0].slice(0, 80);

  await supabase.from("announcements").insert({
    title: firstLine || "Annonce Discord",
    content: message.content,
    author_id: profile?.id || null,
    author_name: profile?.username || message.author.username,
    source: "discord",
  });
  console.log(`[annonce] relayée depuis Discord (#${message.channelId})`);
});

client.login(DISCORD_TOKEN);
