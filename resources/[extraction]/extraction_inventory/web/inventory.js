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
const stashCountMeta = document.getElementById("stashCountMeta");
const loadoutValueMeta = document.getElementById("loadoutValueMeta");
const bagSlotMeta = document.getElementById("bagSlotMeta");
const dropZone = document.getElementById("dropZone");

let currentSnapshot = null;
let draggedItemName = null;

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

function isLoadoutItem(entry) {
  return entry.type === "weapon" || entry.type === "ammo";
}

function getItemImage(entry) {
  if (!entry.image) {
    return "";
  }

  return `nui://extraction_items/web/images/items/${entry.image}`;
}

function getItemRarity(entry) {
  if (entry.type === "weapon") {
    return "weapon";
  }

  if (entry.type === "ammo") {
    return "ammo";
  }

  if ((entry.value || 0) >= 300) {
    return "rare";
  }

  return "common";
}

function findPlacement(occupied, width, height, itemWidth, itemHeight) {
  for (let y = 1; y <= height; y += 1) {
    for (let x = 1; x <= width; x += 1) {
      if (x + itemWidth - 1 > width || y + itemHeight - 1 > height) {
        continue;
      }

      let blocked = false;

      for (let yy = y; yy < y + itemHeight; yy += 1) {
        for (let xx = x; xx < x + itemWidth; xx += 1) {
          if (occupied.has(`${xx}:${yy}`)) {
            blocked = true;
            break;
          }
        }

        if (blocked) {
          break;
        }
      }

      if (!blocked) {
        for (let yy = y; yy < y + itemHeight; yy += 1) {
          for (let xx = x; xx < x + itemWidth; xx += 1) {
            occupied.add(`${xx}:${yy}`);
          }
        }

        return { x, y };
      }
    }
  }

  return null;
}

function layoutItems(entries, container) {
  const width = Math.max(1, Number(container?.width || 6));
  const height = Math.max(1, Number(container?.height || 6));
  const occupied = new Set();

  return (entries || []).map((entry) => {
    const itemWidth = Math.max(1, Math.min(width, Number(entry.width || 1)));
    const itemHeight = Math.max(1, Math.min(height, Number(entry.height || 1)));
    const placement = findPlacement(occupied, width, height, itemWidth, itemHeight);

    return {
      ...entry,
      width: itemWidth,
      height: itemHeight,
      placement,
      overflow: !placement,
    };
  });
}

function renderSlots(width, height) {
  const slots = [];

  for (let index = 0; index < width * height; index += 1) {
    slots.push(`<span class="grid-slot"></span>`);
  }

  return slots.join("");
}

function renderGrid(target, entries, { allowDrop = false, container = {} } = {}) {
  if (!target) {
    return;
  }

  const width = Math.max(1, Number(container?.width || 6));
  const height = Math.max(1, Number(container?.height || 6));
  const laidOutItems = layoutItems(entries || [], { width, height });
  const visibleItems = laidOutItems.filter((entry) => !entry.overflow);
  const overflowItems = laidOutItems.filter((entry) => entry.overflow);

  target.style.setProperty("--grid-cols", width);
  target.style.setProperty("--grid-rows", height);

  if (!entries || entries.length === 0) {
    target.innerHTML = `
      <div class="grid-shell">
        <div class="slot-layer">${renderSlots(width, height)}</div>
        <div class="empty">No items available</div>
      </div>
    `;
    return;
  }

  const cards = visibleItems
    .map((entry) => {
      const totalValue =
        entry.type === "weapon" || entry.type === "ammo"
          ? "Loadout"
          : `$${formatNumber(entry.count * entry.value)}`;
      const image = getItemImage(entry);
      const fallback = escapeHtml((entry.label || entry.name || "?").slice(0, 2).toUpperCase());
      const rarity = getItemRarity(entry);
      const compact = entry.width * entry.height <= 1 ? `data-compact="true"` : "";
      const dragAttrs = allowDrop
        ? `draggable="true" data-draggable="true" data-item="${escapeHtml(entry.name)}"`
        : `draggable="false"`;

      return `
        <article
          class="item-card item-${escapeHtml(entry.type || "loot")}"
          data-rarity="${rarity}"
          style="grid-column:${entry.placement.x} / span ${entry.width}; grid-row:${entry.placement.y} / span ${entry.height};"
          ${compact}
          ${dragAttrs}
        >
          <div class="item-art">
            ${image ? `<img src="${escapeHtml(image)}" alt="" onerror="this.classList.add('is-missing')" />` : ""}
            <span>${fallback}</span>
          </div>
          <div class="item-copy">
            <strong>${escapeHtml(entry.label || entry.name)}</strong>
            <span>${formatNumber(entry.weight)} wt / ${entry.width}x${entry.height}</span>
          </div>
          <div class="item-count">x${formatNumber(entry.count)}</div>
          <div class="item-value">${totalValue}</div>
          ${allowDrop ? `<button class="quick-drop" data-action="drop" data-item="${escapeHtml(entry.name)}" type="button">Drop</button>` : ""}
        </article>
      `;
    })
    .join("");

  const overflow = overflowItems.length > 0
    ? `<div class="overflow-warning">${overflowItems.length} item types do not fit this container view.</div>`
    : "";

  target.innerHTML = `
    <div class="grid-shell">
      <div class="slot-layer">${renderSlots(width, height)}</div>
      <div class="item-layer">${cards}</div>
      ${overflow}
    </div>
  `;
}

function hideUi() {
  app.classList.remove("is-open");
  app.setAttribute("aria-hidden", "true");
  root.classList.add("nui-closed");
  root.classList.remove("inventory-open");
  document.body.classList.remove("inventory-open");
}

function showUi(snapshot) {
  root.classList.remove("nui-closed");
  root.classList.add("inventory-open");
  document.body.classList.add("inventory-open");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
  render(snapshot);
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
  const stashItemCount = stashEntries.reduce((total, entry) => total + Number(entry.count || 0), 0);
  const secondaryItemCount = secondaryEntries.reduce((total, entry) => total + Number(entry.count || 0), 0);
  const loadoutValue = loadoutEntries.reduce((total, entry) => total + (Number(entry.value || 0) * Number(entry.count || 0)), 0);

  renderGrid(stashList, stashEntries, { container: snapshot.containers?.stash });
  renderGrid(bagList, secondaryEntries, {
    allowDrop: snapshot.raidActive,
    container: snapshot.raidActive ? snapshot.containers?.raidBag : snapshot.containers?.loadout,
  });

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
  setText(stashCountMeta, `${formatNumber(stashItemCount)} secured items`);
  setText(loadoutValueMeta, `$${formatNumber(loadoutValue)} kit value`);
  setText(bagSlotMeta, `${formatNumber(secondaryItemCount)} stacks`);

  sellButton.disabled = !snapshot.canSell || stashEntries.length === 0;
  dropZone.classList.toggle("is-enabled", snapshot.raidActive === true);
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

document.addEventListener("dragstart", (event) => {
  const item = event.target?.closest("[data-draggable='true']");
  if (!item) {
    return;
  }

  draggedItemName = item.dataset.item;
  event.dataTransfer.effectAllowed = "move";
  event.dataTransfer.setData("text/plain", draggedItemName);
  dropZone.classList.add("is-armed");
});

document.addEventListener("dragend", () => {
  draggedItemName = null;
  dropZone.classList.remove("is-armed", "is-hovered");
});

dropZone.addEventListener("dragover", (event) => {
  if (!draggedItemName || !dropZone.classList.contains("is-enabled")) {
    return;
  }

  event.preventDefault();
  event.dataTransfer.dropEffect = "move";
  dropZone.classList.add("is-hovered");
});

dropZone.addEventListener("dragleave", () => {
  dropZone.classList.remove("is-hovered");
});

dropZone.addEventListener("drop", (event) => {
  event.preventDefault();
  const itemName = draggedItemName || event.dataTransfer.getData("text/plain");
  dropZone.classList.remove("is-armed", "is-hovered");

  if (itemName && dropZone.classList.contains("is-enabled")) {
    post("dropItem", { itemName });
  }

  draggedItemName = null;
});

document.addEventListener("keyup", (event) => {
  if (event.key === "Escape") {
    post("close");
  }
});

closeButton.addEventListener("click", () => post("close"));
refreshButton.addEventListener("click", () => post("refresh"));
sellButton.addEventListener("click", () => post("sellAll"));
