const app = document.getElementById("app");
const closeButton = document.getElementById("closeButton");
const profileTitle = document.getElementById("profileTitle");
const operatorLevel = document.getElementById("operatorLevel");
const raidStatus = document.getElementById("raidStatus");
const stats = document.getElementById("stats");
const sellButtons = [...document.querySelectorAll('[data-action="sellLoot"]')];
const sellHint = document.getElementById("sellHint");
const stashPreview = document.getElementById("stashPreview");
const loadoutPreview = document.getElementById("loadoutPreview");
const stashMeta = document.getElementById("stashMeta");
const loadoutMeta = document.getElementById("loadoutMeta");
const viewKicker = document.getElementById("viewKicker");
const viewTitle = document.getElementById("viewTitle");
const toast = document.getElementById("toast");

let currentSnapshot = null;
let currentView = "deploy";
let toastTimer = null;

const viewMeta = {
  deploy: ["Safehouse Operations", "Deploy"],
  loadout: ["Preparation", "Loadout"],
  trader: ["Market Access", "Traders"],
  quests: ["Task Board", "Quests"],
  party: ["Squad Assembly", "Party"],
  settings: ["Client Preferences", "Settings"],
};

const viewAliases = {
  profile: "loadout",
  stats: "loadout",
};

const resourceName =
  typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "extraction_lobby";

function post(action, payload = {}) {
  fetch(`https://${resourceName}/${action}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
}

function formatNumber(value) {
  return new Intl.NumberFormat("en-US").format(Number(value || 0));
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function fallbackSnapshot() {
  return {
    cash: 0,
    xp: 0,
    level: 1,
    raids: 0,
    extractions: 0,
    deaths: 0,
    bestRunValue: 0,
    stashValue: 0,
    stash: [],
    carry: [],
    raidActive: false,
    canSell: false,
    loading: true,
  };
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("is-visible");

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.classList.remove("is-visible");
  }, 2200);
}

function setView(view) {
  const normalizedView = viewAliases[view] || view;
  currentView = viewMeta[normalizedView] ? normalizedView : "deploy";

  document.querySelectorAll(".nav-item").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.view === currentView);
  });

  document.querySelectorAll(".view-panel").forEach((panel) => {
    panel.classList.toggle("is-active", panel.dataset.panel === currentView);
  });

  const [kicker, title] = viewMeta[currentView];
  viewKicker.textContent = kicker;
  viewTitle.textContent = title;
}

function isLoadoutItem(entry) {
  return entry.type === "weapon" || entry.type === "ammo";
}

function itemValue(entry) {
  if (isLoadoutItem(entry)) {
    return "Kit";
  }

  return `$${formatNumber(Number(entry.count || 0) * Number(entry.value || 0))}`;
}

function renderList(target, entries, emptyText) {
  if (!entries || entries.length === 0) {
    target.innerHTML = `<div class="empty">${escapeHtml(emptyText)}</div>`;
    return;
  }

  target.innerHTML = entries
    .slice(0, 8)
    .map((entry) => {
      const count = formatNumber(entry.count);
      const weight = formatNumber(entry.weight);
      const type = escapeHtml(entry.type || "loot");

      return `
        <div class="item">
          <div>
            <strong>${escapeHtml(entry.label)}</strong>
            <span>${count}x / ${weight} wt each / ${type}</span>
          </div>
          <div class="item-value">${itemValue(entry)}</div>
        </div>
      `;
    })
    .join("");
}

function renderStats(snapshot) {
  const values = [
    ["Cash", `$${formatNumber(snapshot.cash)}`],
    ["Level", formatNumber(snapshot.level)],
    ["XP", formatNumber(snapshot.xp)],
    ["Raids", formatNumber(snapshot.raids)],
    ["Extracts", formatNumber(snapshot.extractions)],
    ["Best Run", `$${formatNumber(snapshot.bestRunValue)}`],
  ];

  stats.innerHTML = values
    .map(([label, value]) => {
      return `
        <div class="stat">
          <span class="stat-label">${label}</span>
          <span class="stat-value">${value}</span>
        </div>
      `;
    })
    .join("");
}

function render(snapshot) {
  snapshot = snapshot || fallbackSnapshot();
  currentSnapshot = snapshot;

  const stash = snapshot.stash || [];
  const sellableStash = stash.filter((entry) => !isLoadoutItem(entry));
  const loadout = stash.filter(isLoadoutItem);
  const totalStashItems = stash.reduce((total, entry) => total + Number(entry.count || 0), 0);
  const levelText = snapshot.loading ? "Loading contractor" : `Level ${formatNumber(snapshot.level)} Contractor`;

  profileTitle.textContent = levelText;
  operatorLevel.textContent = levelText;
  raidStatus.textContent = snapshot.raidActive ? "Raid active" : "Safehouse ready";

  renderStats(snapshot);
  renderList(stashPreview, sellableStash, "No secured sellable loot yet");
  renderList(loadoutPreview, loadout, "No loadout items in stash");

  stashMeta.textContent = `${formatNumber(totalStashItems)} items / $${formatNumber(snapshot.stashValue)}`;
  loadoutMeta.textContent = loadout.length > 0 ? `${formatNumber(loadout.length)} item types` : "Empty";

  const canSell = snapshot.canSell && sellableStash.length > 0;
  sellButtons.forEach((button) => {
    button.disabled = !canSell;
  });
  sellHint.textContent = snapshot.canSell
    ? "Convert secured loot into cash."
    : "Use this from the trader terminal.";
}

function open(payload = {}) {
  document.documentElement.classList.remove("nui-hidden");
  document.documentElement.classList.add("lobby-open");
  document.body.classList.add("lobby-open");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
  setView(payload.view || currentView || "deploy");
  render(payload.snapshot || currentSnapshot || fallbackSnapshot());
}

function close() {
  app.classList.remove("is-open");
  app.setAttribute("aria-hidden", "true");
  document.body.classList.remove("lobby-open");
  document.documentElement.classList.remove("lobby-open");
  document.documentElement.classList.add("nui-hidden");
}

window.addEventListener("message", (event) => {
  const { action, payload } = event.data || {};

  if (action === "open") {
    open(payload);
  }

  if (action === "setView") {
    setView(payload?.view || "deploy");
  }

  if (action === "update") {
    render(payload?.snapshot || currentSnapshot || fallbackSnapshot());
  }

  if (action === "close") {
    close();
  }
});

document.addEventListener("click", (event) => {
  const navButton = event.target?.closest("[data-view]");
  if (navButton) {
    setView(navButton.dataset.view);
    return;
  }

  const soonButton = event.target?.closest("[data-coming-soon]");
  if (soonButton) {
    showToast(`${soonButton.dataset.comingSoon} is coming in a future milestone.`);
    return;
  }

  const action = event.target?.closest("[data-action]")?.dataset?.action;

  if (!action) {
    return;
  }

  post(action);
});

document.addEventListener("keyup", (event) => {
  if (event.key === "Escape") {
    post("close");
  }
});

closeButton.addEventListener("click", () => post("close"));

if (new URLSearchParams(window.location.search).has("demo")) {
  open({
    snapshot: {
      cash: 500,
      xp: 1240,
      level: 2,
      raids: 7,
      extractions: 3,
      deaths: 4,
      bestRunValue: 6800,
      stashValue: 4200,
      canSell: true,
      raidActive: false,
      stash: [
        { label: "Military Circuit", count: 2, value: 900, weight: 90, type: "loot" },
        { label: "Medical Supplies", count: 4, value: 350, weight: 70, type: "loot" },
        { label: "Pistol", count: 1, value: 0, weight: 650, type: "weapon" },
        { label: "9mm Ammo", count: 48, value: 0, weight: 8, type: "ammo" },
      ],
    },
  });
}
