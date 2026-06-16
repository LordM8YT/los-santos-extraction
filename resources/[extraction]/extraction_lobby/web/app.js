const app = document.getElementById("app");
const closeButton = document.getElementById("closeButton");
const profileTitle = document.getElementById("profileTitle");
const raidStatus = document.getElementById("raidStatus");
const stats = document.getElementById("stats");
const sellButton = document.getElementById("sellButton");
const sellHint = document.getElementById("sellHint");
const stashPreview = document.getElementById("stashPreview");
const loadoutPreview = document.getElementById("loadoutPreview");
const stashMeta = document.getElementById("stashMeta");
const loadoutMeta = document.getElementById("loadoutMeta");

let currentSnapshot = null;

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

  profileTitle.textContent = snapshot.loading
    ? "Loading profile"
    : `Level ${formatNumber(snapshot.level)} Contractor`;
  raidStatus.textContent = snapshot.raidActive ? "Raid active" : "Safehouse ready";

  renderStats(snapshot);
  renderList(stashPreview, sellableStash, "No secured sellable loot yet");
  renderList(loadoutPreview, loadout, "No loadout items in stash");

  stashMeta.textContent = `${formatNumber(totalStashItems)} items / $${formatNumber(snapshot.stashValue)}`;
  loadoutMeta.textContent = loadout.length > 0 ? `${formatNumber(loadout.length)} item types` : "Empty";

  sellButton.disabled = !snapshot.canSell || sellableStash.length === 0;
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

  if (action === "update") {
    render(payload?.snapshot || currentSnapshot || fallbackSnapshot());
  }

  if (action === "close") {
    close();
  }
});

document.addEventListener("click", (event) => {
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
