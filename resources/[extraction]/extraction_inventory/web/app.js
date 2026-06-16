const app = document.getElementById("app");
const stats = document.getElementById("stats");
const stashList = document.getElementById("stashList");
const bagList = document.getElementById("bagList");
const sellButton = document.getElementById("sellButton");
const refreshButton = document.getElementById("refreshButton");
const closeButton = document.getElementById("closeButton");
const bagMeta = document.getElementById("bagMeta");
const secondaryKicker = document.getElementById("secondaryKicker");
const secondaryTitle = document.getElementById("secondaryTitle");

let currentSnapshot = null;

const resourceName =
  typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "extraction_inventory";

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

function renderStats(snapshot) {
  const items = [
    ["Cash", `$${formatNumber(snapshot.cash)}`],
    ["Level", `${snapshot.level}`],
    ["XP", `${formatNumber(snapshot.xp)}`],
    ["Raids", formatNumber(snapshot.raids)],
    ["Extractions", formatNumber(snapshot.extractions)],
    ["Best Run", `$${formatNumber(snapshot.bestRunValue)}`],
    ["Stash Value", `$${formatNumber(snapshot.stashValue)}`],
  ];

  stats.innerHTML = items
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

function renderList(target, entries, { allowDrop = false } = {}) {
  if (!entries || entries.length === 0) {
    target.innerHTML = `<div class="empty">Empty</div>`;
    return;
  }

  target.innerHTML = entries
    .map((entry) => {
      const button = allowDrop
        ? `<button class="danger" data-action="drop" data-item="${entry.name}">Drop 1</button>`
        : "";
      const type = entry.type || "loot";
      const value = type === "weapon" || type === "ammo"
        ? "Loadout"
        : `$${formatNumber(entry.count * entry.value)}`;

      return `
        <div class="item item-${type}">
          <div class="item-main">
            <strong>${entry.label}</strong>
            <span>${entry.count}x  |  ${entry.weight} wt each  |  ${type}</span>
          </div>
          <div class="item-value">${value}</div>
          ${button}
        </div>
      `;
    })
    .join("");
}

function isLoadoutItem(entry) {
  return entry.type === "weapon" || entry.type === "ammo";
}

function render(snapshot) {
  snapshot = snapshot || {
    cash: 0,
    xp: 0,
    level: 1,
    raids: 0,
    extractions: 0,
    deaths: 0,
    bestRunValue: 0,
    stashValue: 0,
    carryWeight: 0,
    maxCarryWeight: 0,
    stash: [],
    carry: [],
    raidActive: false,
    canSell: false,
  };

  currentSnapshot = snapshot;
  const stashEntries = (snapshot.stash || []).filter((entry) => !isLoadoutItem(entry));
  const loadoutEntries = (snapshot.stash || []).filter(isLoadoutItem);
  const secondaryEntries = snapshot.raidActive ? snapshot.carry : loadoutEntries;

  renderStats(snapshot);
  renderList(stashList, stashEntries);
  renderList(bagList, secondaryEntries, { allowDrop: snapshot.raidActive });

  secondaryKicker.textContent = snapshot.raidActive ? "On Character" : "Raid Ready";
  secondaryTitle.textContent = snapshot.raidActive ? "Raid Bag" : "Loadout";
  bagMeta.textContent = snapshot.raidActive
    ? `${formatNumber(snapshot.carryWeight)} / ${formatNumber(snapshot.maxCarryWeight)}`
    : loadoutEntries.length > 0 ? "Ready" : "Empty";
  sellButton.disabled = !snapshot.canSell || stashEntries.length === 0;
}

window.addEventListener("message", (event) => {
  const { action, snapshot } = event.data || {};

  if (action === "open") {
    document.documentElement.classList.remove("nui-hidden");
    document.documentElement.classList.add("inventory-open");
    app.classList.add("is-open");
    document.body.classList.add("inventory-open");
    render(snapshot);
  }

  if (action === "update") {
    render(snapshot || currentSnapshot);
  }

  if (action === "close") {
    app.classList.remove("is-open");
    document.body.classList.remove("inventory-open");
    document.documentElement.classList.remove("inventory-open");
    document.documentElement.classList.add("nui-hidden");
  }
});

document.addEventListener("click", (event) => {
  const action = event.target?.dataset?.action;
  const itemName = event.target?.dataset?.item;

  if (action === "drop" && itemName) {
    post("dropItem", { itemName });
  }
});

document.addEventListener("keyup", (event) => {
  if (event.key === "Escape") {
    post("close");
  }
});

closeButton.addEventListener("click", () => post("close"));
refreshButton.addEventListener("click", () => post("refresh"));
sellButton.addEventListener("click", () => post("sellAll"));
