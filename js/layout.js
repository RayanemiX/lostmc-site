// ============================================================
// LAYOUT — construit la sidebar / topbar en fonction des rôles
// ============================================================

function LostMCLayout_render(activePage, pageTitle) {
  const auth = window.LostMCAuth;
  const p = auth.profile;
  const isTable = auth.isTable();

  const baseLinks = [
    { key: "home", label: "Accueil", href: "index.html" },
    { key: "annonces", label: "Annonces", href: "pages/annonces.html" },
    { key: "annonces-activite", label: "Annonces Activité", href: "pages/annonces-activite.html" },
    { key: "hierarchie", label: "Hiérarchie", href: "pages/hierarchie.html" },
    { key: "rapports", label: "Rapports", href: "pages/rapports.html" },
    { key: "cartographie", label: "Cartographie", href: "pages/cartographie.html" },
    { key: "demande-table", label: "Demande Table", href: "pages/demande-table.html" },
  ];

  const tableLinks = [
    { key: "table-annonces", label: "Annonces (gestion)", href: "pages/table/annonces-admin.html" },
    { key: "membres", label: "Liste des membres", href: "pages/table/membres.html" },
    { key: "dossier-membre", label: "Dossier membre", href: "pages/table/dossier-membre.html" },
    { key: "banque", label: "Banque du MC", href: "pages/table/banque.html" },
    { key: "armurie", label: "Armurie", href: "pages/table/armurie.html" },
    { key: "parametres", label: "Paramètres", href: "pages/table/parametres.html" },
  ];

  // Résolution des chemins relatifs selon la profondeur du dossier courant.
  // Tous les hrefs ci-dessus sont exprimés "depuis la racine" du site
  // (ex: "index.html", "pages/annonces.html", "pages/table/parametres.html").
  const depth = location.pathname.includes("/pages/table/") ? 2
              : location.pathname.includes("/pages/") ? 1
              : 0;
  const rel = (href) => {
    if (depth === 0) return href;
    if (depth === 1) return href.startsWith("pages/") ? href.replace("pages/", "") : "../" + href;
    if (depth === 2) {
      if (href.startsWith("pages/table/")) return href.replace("pages/table/", "");
      if (href.startsWith("pages/")) return "../" + href.replace("pages/", "");
      return "../../" + href;
    }
  };

  const roleTags = auth.roles.map(r => `<span class="tag">${r}</span>`).join(" ");

  document.getElementById("app").innerHTML = `
    <div class="app-shell">
      <aside class="sidebar">
        <div class="sidebar-brand">
          <img src="${depth === 0 ? "assets/logo.jpg" : depth === 1 ? "../assets/logo.jpg" : "../../assets/logo.jpg"}" alt="Logo The Lost MC">
          <div class="name">THE <span>LOST</span> MC</div>
        </div>
        <div class="sidebar-section-label">Intranet</div>
        <nav>
          ${baseLinks.map(l => `<a class="side-link ${activePage===l.key?'active':''}" href="${rel(l.href)}">${l.label}</a>`).join("")}
          <a class="side-link" href="javascript:void(0)" id="openAbsenceModal">Absences</a>
        </nav>
        ${isTable ? `
          <div class="sidebar-divider"></div>
          <div class="sidebar-section-label">La Table</div>
          <nav>
            ${tableLinks.map(l => `<a class="side-link ${activePage===l.key?'active':''}" href="${rel(l.href)}">${l.label}</a>`).join("")}
          </nav>
        ` : ""}
        <div class="sidebar-user">
          <img src="${p?.avatar_url || 'https://api.dicebear.com/7.x/identicon/svg?seed=' + (p?.username||'x')}" alt="">
          <div>
            <div id="codenameDisplay" style="cursor:pointer" title="Cliquer pour modifier">${auth.displayName()}${p?.member_code ? ` <span class="tag">#${p.member_code}</span>` : ''}</div>
            <div class="roles">${roleTags}</div>
          </div>
          <a class="logout-link" href="javascript:void(0)" id="logoutBtn">Déconnexion</a>
        </div>
      </aside>
      <div class="main">
        <div class="topbar">
          <h1>${pageTitle}</h1>
          <div class="realtime-badge"><span class="dot"></span> Temps réel actif</div>
        </div>
        <div id="content" class="content"></div>
      </div>
    </div>

    <div class="modal-overlay hidden" id="absenceModal">
      <div class="modal-box">
        <h3>Déclarer une absence</h3>
        <form id="absenceForm">
          <label>Date de début</label>
          <input type="date" id="absStart" required>
          <label>Date de fin</label>
          <input type="date" id="absEnd" required>
          <label>Raison</label>
          <textarea id="absReason" rows="3" required></textarea>
          <div class="form-actions">
            <button type="submit" class="btn-primary">Envoyer</button>
            <button type="button" id="cancelAbsence">Annuler</button>
          </div>
        </form>
      </div>
    </div>
  `;

  document.getElementById("logoutBtn").onclick = () => auth.signOut();

  document.getElementById("codenameDisplay").onclick = () => {
    LostMC_editModal("Modifier mon nom de code", [
      { key: "codename", label: "Nom de code", value: auth.profile.codename || "", required: true },
      { key: "member_code", label: "Code membre / ID (optionnel)", value: auth.profile.member_code || "" },
    ], async (values) => {
      const { error } = await sb.from("profiles").update({
        codename: values.codename, member_code: values.member_code || null,
      }).eq("id", auth.profile.id);
      if (!error) {
        auth.profile.codename = values.codename;
        auth.profile.member_code = values.member_code || null;
        document.getElementById("codenameDisplay").innerHTML =
          auth.displayName() + (auth.profile.member_code ? ` <span class="tag">#${auth.profile.member_code}</span>` : "");
      }
    });
  };

  const modal = document.getElementById("absenceModal");
  document.getElementById("openAbsenceModal").onclick = () => modal.classList.remove("hidden");
  document.getElementById("cancelAbsence").onclick = () => modal.classList.add("hidden");
  document.getElementById("absenceForm").onsubmit = async (e) => {
    e.preventDefault();
    const { error } = await sb.from("absences").insert({
      profile_id: auth.profile.id,
      member_name: auth.displayName(),
      start_date: document.getElementById("absStart").value,
      end_date: document.getElementById("absEnd").value,
      reason: document.getElementById("absReason").value,
    });
    if (error) { alert("Erreur : " + error.message); return; }
    modal.classList.add("hidden");
    e.target.reset();
    alert("Absence déclarée.");
  };
}

window.LostMCLayout_render = LostMCLayout_render;

// ============================================================
// Fenêtre d'édition générique réutilisable sur toutes les pages
// ============================================================
function LostMC_editModal(title, fields, onSave, options = {}) {
  const existing = document.getElementById("editModalOverlay");
  if (existing) existing.remove();

  const overlay = document.createElement("div");
  overlay.className = "modal-overlay";
  overlay.id = "editModalOverlay";

  const fieldHtml = fields.map(f => {
    const id = "edit_" + f.key;
    if (f.type === "textarea") {
      return `<label>${f.label}</label><textarea id="${id}" rows="${f.rows || 3}" ${f.required ? "required" : ""}>${f.value ?? ""}</textarea>`;
    }
    if (f.type === "checkbox") {
      return `<label><input type="checkbox" id="${id}" style="width:auto; display:inline-block; margin-right:6px" ${f.value ? "checked" : ""}> ${f.label}</label>`;
    }
    return `<label>${f.label}</label><input type="${f.type || "text"}" id="${id}" value="${f.value ?? ""}" ${f.required ? "required" : ""} ${f.step ? `step="${f.step}"` : ""}>`;
  }).join("");

  overlay.innerHTML = `
    <div class="modal-box">
      <h3>${title}</h3>
      ${options.intro ? `<p class="perm-note">${options.intro}</p>` : ""}
      <form id="editModalForm">
        ${fieldHtml}
        <div class="form-actions">
          <button type="submit" class="btn-primary">Enregistrer</button>
          ${options.hideCancel ? "" : `<button type="button" id="editModalCancel">Annuler</button>`}
        </div>
      </form>
    </div>
  `;
  document.body.appendChild(overlay);

  if (!options.hideCancel) {
    document.getElementById("editModalCancel").onclick = () => overlay.remove();
    overlay.onclick = (e) => { if (e.target === overlay) overlay.remove(); };
  }

  document.getElementById("editModalForm").onsubmit = async (e) => {
    e.preventDefault();
    const values = {};
    fields.forEach(f => {
      const el = document.getElementById("edit_" + f.key);
      if (f.type === "checkbox") values[f.key] = el.checked;
      else if (f.type === "number") values[f.key] = el.value === "" ? null : parseFloat(el.value);
      else values[f.key] = el.value;
    });
    await onSave(values);
    overlay.remove();
  };
}
window.LostMC_editModal = LostMC_editModal;
