const root = document.documentElement;
const app = document.getElementById("app");
const stashList = document.getElementById("stashList");
const bagList = document.getElementById("bagList");
const sellButton = document.getElementById("sellButton");
const refreshButton = document.getElementById("refreshButton");
const closeButton = document.getElementById("closeButton");
const bagMeta = document.getElementById("bagMeta");
const stashValueMeta = document.getElementById("stashValueMeta");
const carryWeightMeta = document.getElementById("carryWeightMeta");
const modeMeta = document.getElementById("modeMeta");
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
  }).catch(() => {});
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

function setText(element, value) {
  if (element) {
    element.textContent = value;
  }
}

function setHtml(element, value) {
  if (element) {
    element.innerHTML = value;
  }
}

function isLoadoutItem(entry) {
  return entry.type === "weapon" || entry.type === "ammo";
}

function hideUi() {
  app.classList.remove("is-open");
  app.setAttribute("aria-hidden", "true");
  root.classList.add("nui-closed");
}

function showUi(snapshot) {
  root.classList.remove("nui-closed");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
  render(snapshot);
}

function renderList(target, entries, { allowDrop = false } = {}) {
  if (!target) {
    return;
  }

  if (!entries || entries.length === 0) {
    setHtml(target, `<div class="empty">No items available</div>`);
    return;
  }

  setHtml(target, entries
    .map((entry) => {
      const type = entry.type || "loot";
      const value =
        type === "weapon" || type === "ammo"
          ? "Loadout"
          : `$${formatNumber(entry.count * entry.value)}`;
      const button = allowDrop
        ? `<button class="danger" data-action="drop" data-item="${escapeHtml(entry.name)}">Drop 1</button>`
        : "";

      return `
        <div class="item item-${type}">
          <div class="item-main">
            <strong>${escapeHtml(entry.label)}</strong>
            <span>${formatNumber(entry.count)}x | ${formatNumber(entry.weight)} wt each | ${escapeHtml(type)}</span>
          </div>
          <div class="item-value">${value}</div>
          ${button}
        </div>
      `;
    })
    .join(""));
}

function render(snapshot) {
  snapshot = snapshot || {
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

  renderList(stashList, stashEntries);
  renderList(bagList, secondaryEntries, { allowDrop: snapshot.raidActive });

  setText(secondaryKicker, snapshot.raidActive ? "On Character" : "Raid Ready");
  setText(secondaryTitle, snapshot.raidActive ? "Raid Bag" : "Loadout");
  setText(bagMeta, snapshot.raidActive
    ? `${formatNumber(snapshot.carryWeight)} / ${formatNumber(snapshot.maxCarryWeight)}`
    : loadoutEntries.length > 0
      ? "Ready"
      : "Empty");
  setText(stashValueMeta, `$${formatNumber(snapshot.stashValue)}`);
  setText(carryWeightMeta, `${formatNumber(snapshot.carryWeight)} / ${formatNumber(snapshot.maxCarryWeight)}`);
  setText(modeMeta, snapshot.raidActive ? "In Raid" : "Safehouse");
  sellButton.disabled = !snapshot.canSell || stashEntries.length === 0;
}

hideUi();

window.addEventListener("message", (event) => {
  const { action, snapshot } = event.data || {};

  if (action === "open") {
    showUi(snapshot);
    return;
  }

  if (action === "update") {
    render(snapshot || currentSnapshot);
    return;
  }

  if (action === "close") {
    hideUi();
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
