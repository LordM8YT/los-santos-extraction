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

const app = document.getElementById("app");
const closeButton = document.getElementById("closeButton");
const profileTitle = document.getElementById("profileTitle");
const operatorLevel = document.getElementById("operatorLevel");
const profileXp = document.getElementById("profileXp");
const profileCash = document.getElementById("profileCash");
const raidStatus = document.getElementById("raidStatus");
const stats = document.getElementById("stats");
const sellButtons = [...document.querySelectorAll('[data-action="sellLoot"]')];
const deployButton = document.getElementById("deployButton");
const deployHint = document.getElementById("deployHint");
const sellHint = document.getElementById("sellHint");
const stashPreview = document.getElementById("stashPreview");
const loadoutPreview = document.getElementById("loadoutPreview");
const oxInventoryBridge = document.getElementById("oxInventoryBridge");
const legacyStashBrowser = document.getElementById("legacyStashBrowser");
const legacyLoadoutBrowser = document.getElementById("legacyLoadoutBrowser");
const stashProviderLabel = document.getElementById("stashProviderLabel");
const loadoutProviderLabel = document.getElementById("loadoutProviderLabel");
const loadoutRuleText = document.getElementById("loadoutRuleText");
const stashMeta = document.getElementById("stashMeta");
const loadoutMeta = document.getElementById("loadoutMeta");
const viewKicker = document.getElementById("viewKicker");
const viewTitle = document.getElementById("viewTitle");
const toast = document.getElementById("toast");
const readyKitState = document.getElementById("readyKitState");
const entryFeeState = document.getElementById("entryFeeState");
const raidAccessState = document.getElementById("raidAccessState");
const bestRunMeta = document.getElementById("bestRunMeta");
const survivalMeta = document.getElementById("survivalMeta");
const targetProgress = document.getElementById("targetProgress");
const extractProgress = document.getElementById("extractProgress");
const recommendedAction = document.getElementById("recommendedAction");
const missionBoard = document.getElementById("missionBoard");
const weaponSlot = document.getElementById("weaponSlot");
const ammoSlot = document.getElementById("ammoSlot");
const gearSlot = document.getElementById("gearSlot");
const kitSummary = document.getElementById("kitSummary");
const carryEstimate = document.getElementById("carryEstimate");
const deploymentRisk = document.getElementById("deploymentRisk");
const traderItems = document.getElementById("traderItems");

let currentSnapshot = null;
let currentView = "deploy";
let inventoryProvider = "legacy";
let toastTimer = null;
let deployLockTimer = null;
let deployLocked = false;
let currentSettings = {
  minimapMode: "always",
  hudDensity: "full",
  firstPersonMode: "raid",
  crosshairMode: "dynamic",
  helmetOverlay: "on",
};

const XP_PER_LEVEL = 700;
const NAV_SHORTCUTS = ["deploy", "party", "loadout", "quests", "trader", "settings"];

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
  return fetch(`https://${resourceName}/${action}`, {
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

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
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
    progression: {
      xpPerLevel: XP_PER_LEVEL,
      maxLevel: 100,
      maxXp: 69300,
    },
    trader: {
      items: [],
    },
    raidActive: false,
    canSell: false,
    loading: true,
  };
}

function showToast(message) {
  if (!toast) {
    return;
  }

  setText(toast, message);
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
  setText(viewKicker, kicker);
  setText(viewTitle, title);
}

function renderSettings(settings = {}) {
  currentSettings = {
    ...currentSettings,
    ...settings,
  };

  document.querySelectorAll("[data-setting-key]").forEach((button) => {
    const key = button.dataset.settingKey;
    button.classList.toggle("is-active", currentSettings[key] === button.dataset.settingValue);
  });
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

function getItemImage(entry) {
  if (!entry?.image) {
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

  if (Number(entry.value || 0) >= 300) {
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
  const height = Math.max(1, Number(container?.height || 4));
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

function getQuest(snapshot, questId) {
  return (snapshot.quests || []).find((quest) => quest.id === questId);
}

function countItem(entries, itemName) {
  return (entries || []).reduce((total, entry) => {
    return total + (entry.name === itemName ? Number(entry.count || 0) : 0);
  }, 0);
}

function rewardText(rewards = {}) {
  const parts = [];

  if (rewards.cash) {
    parts.push(`$${formatNumber(rewards.cash)}`);
  }

  if (rewards.xp) {
    parts.push(`${formatNumber(rewards.xp)} XP`);
  }

  Object.entries(rewards.items || {}).forEach(([itemName, count]) => {
    parts.push(`${formatNumber(count)}x ${itemName.replaceAll("_", " ")}`);
  });

  return parts.length > 0 ? parts.join(" / ") : "No reward";
}

function setProgress(element, percent) {
  if (element) {
    element.style.width = `${clamp(percent, 0, 100)}%`;
  }
}

function renderList(target, entries, emptyText, container = {}) {
  if (!target) {
    return;
  }

  const columns = Math.max(1, Number(container.width || 6));
  const rows = Math.max(1, Number(container.height || 4));
  const laidOutItems = layoutItems(entries || [], { width: columns, height: rows });
  const visibleItems = laidOutItems.filter((entry) => !entry.overflow);
  const overflowItems = laidOutItems.filter((entry) => entry.overflow);

  target.style.setProperty("--grid-cols", columns);
  target.style.setProperty("--grid-rows", rows);
  target.classList.add("tetris-grid");

  if (!entries || entries.length === 0) {
    setHtml(target, `
      <div class="grid-shell lobby-grid-shell">
        <div class="slot-layer">${renderSlots(columns, rows)}</div>
        <div class="empty">${escapeHtml(emptyText)}</div>
      </div>
    `);
    return;
  }

  const cards = visibleItems
    .map((entry) => {
      const count = formatNumber(entry.count);
      const weight = formatNumber(entry.weight);
      const type = escapeHtml(entry.type || "loot");
      const rarity = getItemRarity(entry);
      const image = getItemImage(entry);
      const fallback = escapeHtml((entry.label || entry.name || "?").slice(0, 2).toUpperCase());
      const compact = entry.width * entry.height <= 1 ? `data-compact="true"` : "";

      return `
        <article
          class="lobby-item-card item-${type}"
          data-rarity="${rarity}"
          style="grid-column:${entry.placement.x} / span ${entry.width}; grid-row:${entry.placement.y} / span ${entry.height};"
          ${compact}
        >
          <div class="item-art">
            ${image ? `<img src="${escapeHtml(image)}" alt="" onerror="this.classList.add('is-missing')" />` : ""}
            <span>${fallback}</span>
          </div>
          <div class="item-copy">
            <strong>${escapeHtml(entry.label || entry.name)}</strong>
            <span>${count}x / ${weight} wt each / ${Number(entry.width || 1)}x${Number(entry.height || 1)} / ${type}</span>
          </div>
          <div class="item-value">${itemValue(entry)}</div>
        </article>
      `;
    })
    .join("");

  const overflow = overflowItems.length > 0
    ? `<div class="overflow-warning">${overflowItems.length} item types do not fit this container view.</div>`
    : "";

  setHtml(target, `
    <div class="grid-shell lobby-grid-shell">
      <div class="slot-layer">${renderSlots(columns, rows)}</div>
      <div class="item-layer">${cards}</div>
      ${overflow}
    </div>
  `);
}

function renderQuestBoard(snapshot) {
  if (!missionBoard) {
    return;
  }

  const quests = snapshot.quests || [];

  if (quests.length === 0) {
    setHtml(missionBoard, `<article class="mission-card"><span>Offline</span><strong>No Contracts</strong><p>The task board has no active work right now.</p></article>`);
    return;
  }

  setHtml(missionBoard, quests
    .map((quest) => {
      const progress = Number(quest.progress || 0);
      const required = Number(quest.required || 1);
      const percent = required > 0 ? (progress / required) * 100 : 0;
      const state = quest.claimed ? "Claimed" : quest.ready ? "Ready To Claim" : "In Progress";
      const cardClass = [
        "mission-card",
        quest.daily ? "daily" : "active",
        quest.ready ? "is-claimable" : "",
        quest.claimed ? "is-claimed" : "",
      ].filter(Boolean).join(" ");

      return `
        <article class="${cardClass}" data-quest-card="${escapeHtml(quest.id)}">
          <span>${escapeHtml(quest.category || (quest.daily ? "Daily Contract" : "Contract"))}</span>
          <strong>${escapeHtml(quest.title || "Contract")}</strong>
          <p>${escapeHtml(quest.description || "")} Progress: ${formatNumber(progress)} / ${formatNumber(required)}. Reward: ${escapeHtml(rewardText(quest.rewards))}.</p>
          <div class="progress-line"><i style="width:${clamp(percent, 0, 100)}%"></i></div>
          <button class="small-button claim-button" data-action="claimQuest" data-quest-id="${escapeHtml(quest.id)}" ${quest.ready && !quest.claimed ? "" : "disabled"} type="button">${quest.claimed ? "Claimed" : quest.ready ? "Claim Reward" : "Locked"}</button>
        </article>
      `;
    })
    .join(""));
}

function renderGearSlot(slot, state) {
  if (!slot) {
    return;
  }

  slot.classList.toggle("is-equipped", Boolean(state.equipped));
  slot.classList.toggle("is-empty", !state.equipped);
  slot.classList.toggle("has-image", Boolean(state.image));
  setHtml(slot, `
    <div class="gear-art">
      ${state.image ? `<img src="${escapeHtml(state.image)}" alt="" onerror="this.classList.add('is-missing')" />` : ""}
      <span>${escapeHtml(state.fallback || state.kicker.slice(0, 2).toUpperCase())}</span>
    </div>
    <div class="gear-copy">
      <span>${escapeHtml(state.kicker)}</span>
      <strong>${escapeHtml(state.title)}</strong>
      <em>${escapeHtml(state.subtitle)}</em>
    </div>
  `);
}

function renderLoadoutSlots(snapshot, loadout) {
  const weapon = loadout.find((entry) => entry.type === "weapon");
  const ammo = loadout.find((entry) => entry.type === "ammo");
  const loadoutWeight = loadout.reduce((total, entry) => total + (Number(entry.count || 0) * Number(entry.weight || 0)), 0);
  const stashWeight = (snapshot.stash || []).reduce((total, entry) => total + (Number(entry.count || 0) * Number(entry.weight || 0)), 0);
  const risk = weapon && ammo ? "Prepared" : weapon ? "Ammo Low" : "Underequipped";

  renderGearSlot(weaponSlot, {
    equipped: Boolean(weapon),
    kicker: "Primary",
    title: weapon ? weapon.label : "No Weapon",
    subtitle: weapon ? `${formatNumber(weapon.count)} stored` : "Assign weapon",
    image: getItemImage(weapon),
    fallback: weapon ? weapon.label.slice(0, 2).toUpperCase() : "W",
  });

  renderGearSlot(ammoSlot, {
    equipped: Boolean(ammo),
    kicker: "Ammo",
    title: ammo ? ammo.label : "Empty",
    subtitle: ammo ? `${formatNumber(ammo.count)} rounds` : "0 rounds",
    image: getItemImage(ammo),
    fallback: "AM",
  });

  renderGearSlot(gearSlot, {
    equipped: true,
    kicker: "Rig",
    title: "Starter Harness",
    subtitle: "Light carry / default",
    fallback: "RG",
  });

  setText(kitSummary, weapon && ammo ? "Raid Ready" : "Needs Review");
  setText(carryEstimate, `${formatNumber(loadoutWeight)} wt kit / ${formatNumber(stashWeight)} wt stash`);
  setText(deploymentRisk, risk);
}

function renderStats(snapshot) {
  if (!stats) {
    return;
  }

  const values = [
    ["Cash", `$${formatNumber(snapshot.cash)}`],
    ["Level", formatNumber(snapshot.level)],
    ["XP", formatNumber(snapshot.xp)],
    ["Raids", formatNumber(snapshot.raids)],
    ["Extracts", formatNumber(snapshot.extractions)],
    ["Best Run", `$${formatNumber(snapshot.bestRunValue)}`],
  ];

  setHtml(stats, values
    .map(([label, value]) => {
      return `
        <div class="stat">
          <span class="stat-label">${label}</span>
          <span class="stat-value">${value}</span>
        </div>
      `;
    })
    .join(""));
}

function renderReadiness(snapshot, sellableStash, loadout) {
  const raids = Number(snapshot.raids || 0);
  const extracts = Number(snapshot.extractions || 0);
  const survivalRate = raids > 0 ? Math.round((extracts / raids) * 100) : 0;
  const hasWeapon = loadout.some((entry) => entry.type === "weapon");
  const hasAmmo = loadout.some((entry) => entry.type === "ammo" && Number(entry.count || 0) > 0);
  const canDeploy = !snapshot.raidActive && !deployLocked;
  const progression = snapshot.progression || {};
  const xpPerLevel = Number(progression.xpPerLevel || XP_PER_LEVEL);
  const maxLevel = Number(progression.maxLevel || 100);
  const isMaxLevel = Number(snapshot.level || 1) >= maxLevel;
  const nextLevelXp = isMaxLevel ? 0 : Math.max(0, (Number(snapshot.level || 1) * xpPerLevel) - Number(snapshot.xp || 0));

  setText(readyKitState, hasWeapon && hasAmmo ? "Armed" : hasWeapon ? "Needs ammo" : "Starter kit");
  setText(entryFeeState, "$0");
  setText(raidAccessState, snapshot.raidActive ? "In raid" : "Ready");
  setText(bestRunMeta, `$${formatNumber(snapshot.bestRunValue)}`);
  setText(survivalMeta, `${survivalRate}%`);
  setText(targetProgress, `${Math.min(5, sellableStash.length)} / 5`);
  setText(extractProgress, `${Math.min(3, extracts)} / 3`);
  setText(recommendedAction, hasWeapon && hasAmmo ? `Deploy or sell ${formatNumber(sellableStash.length)} loot stacks` : "Check loadout before deploy");
  setText(deployHint, snapshot.raidActive ? "You already have an active raid." : hasWeapon && hasAmmo ? "Kit verified. Enter the live Los Santos open zone." : "Starter kit available. Consider checking loadout first.");
  renderQuestBoard(snapshot);

  if (deployButton) {
    deployButton.disabled = !canDeploy;
  }

  const currentLevelStart = (Number(snapshot.level || 1) - 1) * xpPerLevel;
  const levelProgress = isMaxLevel ? 100 : ((Number(snapshot.xp || 0) - currentLevelStart) / xpPerLevel) * 100;
  setHtml(stats, `${stats?.innerHTML || ""}<div class="stat progress-stat"><span class="stat-label">${isMaxLevel ? "Level Cap" : "Next Level"}</span><span class="stat-value">${isMaxLevel ? `MAX ${formatNumber(maxLevel)}` : `${formatNumber(nextLevelXp)} XP`}</span><i style="width:${clamp(levelProgress, 0, 100)}%"></i></div>`);
}

function renderTrader(snapshot) {
  if (!traderItems) {
    return;
  }

  const offers = snapshot.trader?.items || [];

  if (offers.length === 0) {
    setHtml(traderItems, `<div class="empty">Trader catalog unavailable. Make sure extraction_traders is started.</div>`);
    return;
  }

  setHtml(traderItems, offers
    .map((offer) => {
      const image = getItemImage(offer);
      const fallback = escapeHtml((offer.label || offer.item || "?").slice(0, 2).toUpperCase());
      const price = Number(offer.price || 0);
      const owned = Number(offer.owned || 0);
      const limit = Number(offer.limit || 0);
      const quantity = Number(offer.quantity || 1);
      const canBuy = !snapshot.raidActive && Number(snapshot.cash || 0) >= price && (limit <= 0 || owned + quantity <= limit);

      return `
        <article class="trader-offer" data-rarity="${escapeHtml(offer.type || "loot")}">
          <div class="trader-art">
            ${image ? `<img src="${escapeHtml(image)}" alt="" onerror="this.classList.add('is-missing')" />` : ""}
            <span>${fallback}</span>
          </div>
          <div class="trader-copy">
            <span>${escapeHtml(offer.category || "Gear")}</span>
            <strong>${escapeHtml(offer.label || offer.item)}</strong>
            <em>${escapeHtml(offer.description || "")}</em>
          </div>
          <div class="trader-meta">
            <span>$${formatNumber(price)} / ${formatNumber(quantity)}x</span>
            <strong>Owned ${formatNumber(owned)}${limit > 0 ? ` / ${formatNumber(limit)}` : ""}</strong>
          </div>
          <button data-action="buyTraderItem" data-item="${escapeHtml(offer.item)}" data-qty="1" ${canBuy ? "" : "disabled"} type="button">Buy</button>
        </article>
      `;
    })
    .join(""));
}

function render(snapshot) {
  snapshot = snapshot || fallbackSnapshot();
  currentSnapshot = snapshot;

  const stash = snapshot.stash || [];
  const sellableStash = stash.filter((entry) => !isLoadoutItem(entry));
  const loadout = stash.filter(isLoadoutItem);
  const useOxInventory = inventoryProvider === "ox";
  const totalStashItems = stash.reduce((total, entry) => total + Number(entry.count || 0), 0);
  const levelText = snapshot.loading ? "Loading contractor" : `Level ${formatNumber(snapshot.level)} Contractor`;

  setText(profileTitle, levelText);
  setText(operatorLevel, formatNumber(snapshot.level));
  setText(profileXp, formatNumber(snapshot.xp));
  setText(profileCash, formatNumber(snapshot.cash));
  setText(raidStatus, snapshot.raidActive ? "Safehouse ready / raid active" : "Safehouse ready");

  renderStats(snapshot);
  if (useOxInventory) {
    oxInventoryBridge.hidden = false;
    legacyStashBrowser.hidden = true;
    legacyLoadoutBrowser.hidden = true;
    setText(stashProviderLabel, "Ox Provider");
    setText(loadoutProviderLabel, "Ox Loadout");
    setText(loadoutRuleText, "Managed by ox_inventory");
  } else {
    oxInventoryBridge.hidden = true;
    legacyStashBrowser.hidden = false;
    legacyLoadoutBrowser.hidden = false;
    setText(stashProviderLabel, "Secured Inventory");
    setText(loadoutProviderLabel, "Loadout Pool");
    setText(loadoutRuleText, "Weapons and ammo deploy from stash");
    renderList(stashPreview, sellableStash, "No secured sellable loot yet", snapshot.containers?.stash);
    renderList(loadoutPreview, loadout, "No loadout items in stash", snapshot.containers?.loadout);
  }

  renderLoadoutSlots(snapshot, loadout);
  renderReadiness(snapshot, sellableStash, loadout);
  renderTrader(snapshot);

  setText(stashMeta, `${formatNumber(totalStashItems)} items / $${formatNumber(snapshot.stashValue)}`);
  setText(loadoutMeta, loadout.length > 0 ? `${formatNumber(loadout.length)} item types` : "Empty");

  const canSell = snapshot.canSell && sellableStash.length > 0;
  sellButtons.forEach((button) => {
    button.disabled = !canSell;
  });
  setText(
    sellHint,
    canSell ? "Convert secured loot into cash." : snapshot.canSell ? "No sellable loot secured." : "Use this from the trader terminal."
  );
}

function open(payload = {}) {
  inventoryProvider = payload.inventoryProvider || inventoryProvider || "legacy";
  document.documentElement.classList.remove("nui-hidden");
  document.documentElement.classList.add("lobby-open");
  document.body.classList.add("lobby-open");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
  setView(payload.view || currentView || "deploy");
  renderSettings(payload.settings || currentSettings);
  render(payload.snapshot || currentSnapshot || fallbackSnapshot());
}

function close() {
  deployLocked = false;
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
    inventoryProvider = payload?.inventoryProvider || inventoryProvider || "legacy";
    render(payload?.snapshot || currentSnapshot || fallbackSnapshot());
  }

  if (action === "settings") {
    renderSettings(payload || {});
  }

  if (action === "close") {
    close();
  }
});

document.addEventListener("click", (event) => {
  const settingButton = event.target?.closest("[data-setting-key]");
  if (settingButton) {
    const { settingKey: key, settingValue: value } = settingButton.dataset;
    renderSettings({ [key]: value });
    post("setSetting", { key, value });
    showToast("Settings updated.");
    return;
  }

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

  if (action === "claimQuest") {
    const questId = event.target?.closest("[data-quest-id]")?.dataset?.questId;
    showToast("Claiming quest reward...");
    post("claimQuest", { questId });
    return;
  }

  if (action === "buyTraderItem") {
    const button = event.target?.closest("[data-item]");
    const itemName = button?.dataset?.item;
    const quantity = Number(button?.dataset?.qty || 1);

    if (itemName) {
      showToast("Purchasing gear...");
      post("buyTraderItem", { itemName, quantity });
    }

    return;
  }

  if (action === "logout") {
    showToast("Logging out from safehouse...");
    post("logout");
    return;
  }

  if (action === "openInventory") {
    showToast("Opening ox inventory...");
    post("openInventory");
    return;
  }

  if (action === "startRaid") {
    deployLocked = true;
    if (deployButton) {
      deployButton.disabled = true;
    }
    showToast("Deploying to raid...");
    clearTimeout(deployLockTimer);
    deployLockTimer = setTimeout(() => {
      deployLocked = false;
      render(currentSnapshot || fallbackSnapshot());
    }, 4500);
  } else if (action === "refresh") {
    showToast("Refreshing safehouse intel...");
  } else if (action === "sellLoot") {
    showToast("Requesting trader sale...");
  }

  post(action);
});

document.addEventListener("keyup", (event) => {
  if (event.key === "Escape") {
    post("close");
  }

  const shortcutIndex = Number(event.key) - 1;
  if (shortcutIndex >= 0 && shortcutIndex < NAV_SHORTCUTS.length) {
    setView(NAV_SHORTCUTS[shortcutIndex]);
  }
});

if (closeButton) {
  closeButton.addEventListener("click", () => post("close"));
}

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
      trader: {
        items: [
          { item: "pistol", label: "Pistol", category: "Weapon", description: "Reliable sidearm.", price: 650, quantity: 1, owned: 1, limit: 1, image: "lsx_pistol.png", type: "weapon" },
          { item: "pistol_ammo", label: "9mm Ammo Pack", category: "Ammo", description: "Twenty-four rounds.", price: 120, quantity: 24, owned: 48, limit: 240, image: "lsx_pistol_ammo.png", type: "ammo" },
          { item: "meds", label: "Medical Supplies", category: "Medical", description: "Basic field supplies.", price: 320, quantity: 1, owned: 4, limit: 10, image: "lsx_meds.png", type: "loot" },
        ],
      },
      stash: [
        { label: "Military Circuit", count: 2, value: 900, weight: 90, type: "loot", image: "lsx_electronics.png" },
        { label: "Medical Supplies", count: 4, value: 350, weight: 70, type: "loot", image: "lsx_meds.png" },
        { label: "Pistol", count: 1, value: 0, weight: 650, type: "weapon", image: "lsx_pistol.png", width: 2, height: 1 },
        { label: "9mm Ammo", count: 48, value: 0, weight: 8, type: "ammo", image: "lsx_pistol_ammo.png" },
      ],
    },
  });
}
