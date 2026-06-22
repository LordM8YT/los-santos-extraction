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
const medicalQuestText = document.getElementById("medicalQuestText");
const medicalQuestBar = document.getElementById("medicalQuestBar");
const medicalQuestState = document.getElementById("medicalQuestState");
const intelQuestText = document.getElementById("intelQuestText");
const intelQuestBar = document.getElementById("intelQuestBar");
const intelQuestState = document.getElementById("intelQuestState");
const weaponSlot = document.getElementById("weaponSlot");
const ammoSlot = document.getElementById("ammoSlot");
const gearSlot = document.getElementById("gearSlot");
const kitSummary = document.getElementById("kitSummary");
const carryEstimate = document.getElementById("carryEstimate");
const deploymentRisk = document.getElementById("deploymentRisk");

let currentSnapshot = null;
let currentView = "deploy";
let toastTimer = null;
let deployLockTimer = null;
let deployLocked = false;
let currentSettings = {
  minimapMode: "always",
  hudDensity: "full",
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

function renderQuest(snapshot, questId, elements) {
  const quest = getQuest(snapshot, questId);
  if (!quest) {
    return;
  }

  const progress = Number(quest.progress || 0);
  const required = Number(quest.required || 1);
  const percent = required > 0 ? (progress / required) * 100 : 0;
  const state = quest.claimed ? "Claimed" : quest.ready ? "Ready To Claim" : "In Progress";
  const button = document.querySelector(`[data-action="claimQuest"][data-quest-id="${questId}"]`);
  const card = document.querySelector(`[data-quest-card="${questId}"]`);

  setText(elements.state, state);
  setText(elements.text, `${quest.description} Progress: ${formatNumber(progress)} / ${formatNumber(required)}. Reward: ${rewardText(quest.rewards)}.`);
  setProgress(elements.bar, percent);

  if (button) {
    button.disabled = !quest.ready || quest.claimed;
    button.textContent = quest.claimed ? "Claimed" : quest.ready ? "Claim Reward" : "Locked";
  }

  if (card) {
    card.classList.toggle("is-claimable", Boolean(quest.ready));
    card.classList.toggle("is-claimed", Boolean(quest.claimed));
  }
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
  const nextLevelXp = Math.max(0, (Number(snapshot.level || 1) * XP_PER_LEVEL) - Number(snapshot.xp || 0));
  const medicalQuest = getQuest(snapshot, "first_blood_sample");
  const intelQuest = getQuest(snapshot, "find_the_signal");

  setText(readyKitState, hasWeapon && hasAmmo ? "Armed" : hasWeapon ? "Needs ammo" : "Starter kit");
  setText(entryFeeState, "$0");
  setText(raidAccessState, snapshot.raidActive ? "In raid" : "Ready");
  setText(bestRunMeta, `$${formatNumber(snapshot.bestRunValue)}`);
  setText(survivalMeta, `${survivalRate}%`);
  setText(targetProgress, `${Math.min(5, sellableStash.length)} / 5`);
  setText(extractProgress, `${Math.min(3, extracts)} / 3`);
  setText(recommendedAction, hasWeapon && hasAmmo ? `Deploy or sell ${formatNumber(sellableStash.length)} loot stacks` : "Check loadout before deploy");
  setText(deployHint, snapshot.raidActive ? "You already have an active raid." : hasWeapon && hasAmmo ? "Kit verified. Enter the live Los Santos open zone." : "Starter kit available. Consider checking loadout first.");
  if (medicalQuest) {
    renderQuest(snapshot, "first_blood_sample", {
      state: medicalQuestState,
      text: medicalQuestText,
      bar: medicalQuestBar,
    });
  }

  if (intelQuest) {
    renderQuest(snapshot, "find_the_signal", {
      state: intelQuestState,
      text: intelQuestText,
      bar: intelQuestBar,
    });
  }

  if (deployButton) {
    deployButton.disabled = !canDeploy;
  }

  const currentLevelStart = (Number(snapshot.level || 1) - 1) * XP_PER_LEVEL;
  const levelProgress = ((Number(snapshot.xp || 0) - currentLevelStart) / XP_PER_LEVEL) * 100;
  setHtml(stats, `${stats?.innerHTML || ""}<div class="stat progress-stat"><span class="stat-label">Next Level</span><span class="stat-value">${formatNumber(nextLevelXp)} XP</span><i style="width:${clamp(levelProgress, 0, 100)}%"></i></div>`);
}

function render(snapshot) {
  snapshot = snapshot || fallbackSnapshot();
  currentSnapshot = snapshot;

  const stash = snapshot.stash || [];
  const sellableStash = stash.filter((entry) => !isLoadoutItem(entry));
  const loadout = stash.filter(isLoadoutItem);
  const totalStashItems = stash.reduce((total, entry) => total + Number(entry.count || 0), 0);
  const levelText = snapshot.loading ? "Loading contractor" : `Level ${formatNumber(snapshot.level)} Contractor`;

  setText(profileTitle, levelText);
  setText(operatorLevel, formatNumber(snapshot.level));
  setText(profileXp, formatNumber(snapshot.xp));
  setText(profileCash, formatNumber(snapshot.cash));
  setText(raidStatus, snapshot.raidActive ? "Safehouse ready / raid active" : "Safehouse ready");

  renderStats(snapshot);
  renderList(stashPreview, sellableStash, "No secured sellable loot yet", snapshot.containers?.stash);
  renderList(loadoutPreview, loadout, "No loadout items in stash", snapshot.containers?.loadout);
  renderLoadoutSlots(snapshot, loadout);
  renderReadiness(snapshot, sellableStash, loadout);

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
      stash: [
        { label: "Military Circuit", count: 2, value: 900, weight: 90, type: "loot", image: "electronics.svg" },
        { label: "Medical Supplies", count: 4, value: 350, weight: 70, type: "loot", image: "medikit.png" },
        { label: "Pistol", count: 1, value: 0, weight: 650, type: "weapon", image: "weapon_pistol.png", width: 2, height: 1 },
        { label: "9mm Ammo", count: 48, value: 0, weight: 8, type: "ammo", image: "ammo-9.png" },
      ],
    },
  });
}
