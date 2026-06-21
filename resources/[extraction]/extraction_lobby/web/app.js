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
const intelQuestText = document.getElementById("intelQuestText");
const intelQuestBar = document.getElementById("intelQuestBar");
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
  minimapMode: "vehicle",
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

function countItem(entries, itemName) {
  return (entries || []).reduce((total, entry) => {
    return total + (entry.name === itemName ? Number(entry.count || 0) : 0);
  }, 0);
}

function setProgress(element, percent) {
  if (element) {
    element.style.width = `${clamp(percent, 0, 100)}%`;
  }
}

function renderList(target, entries, emptyText) {
  if (!target) {
    return;
  }

  if (!entries || entries.length === 0) {
    setHtml(target, `<div class="empty">${escapeHtml(emptyText)}</div>`);
    return;
  }

  setHtml(target, entries
    .slice(0, 8)
    .map((entry) => {
      const count = formatNumber(entry.count);
      const weight = formatNumber(entry.weight);
      const type = escapeHtml(entry.type || "loot");
      const rarity = entry.type === "weapon" ? "weapon" : entry.type === "ammo" ? "ammo" : "loot";

      return `
        <div class="item crate-item" data-rarity="${rarity}">
          <div>
            <strong>${escapeHtml(entry.label)}</strong>
            <span>${count}x / ${weight} wt each / ${type}</span>
          </div>
          <div class="item-value">${itemValue(entry)}</div>
        </div>
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
  setHtml(slot, `
    <span>${escapeHtml(state.kicker)}</span>
    <strong>${escapeHtml(state.title)}</strong>
    <em>${escapeHtml(state.subtitle)}</em>
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
  });

  renderGearSlot(ammoSlot, {
    equipped: Boolean(ammo),
    kicker: "Ammo",
    title: ammo ? ammo.label : "Empty",
    subtitle: ammo ? `${formatNumber(ammo.count)} rounds` : "0 rounds",
  });

  renderGearSlot(gearSlot, {
    equipped: true,
    kicker: "Rig",
    title: "Starter Harness",
    subtitle: "Light carry / default",
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
  const medicalCount = countItem(snapshot.stash, "meds");
  const intelCount = countItem(snapshot.stash, "intel");

  setText(readyKitState, hasWeapon && hasAmmo ? "Armed" : hasWeapon ? "Needs ammo" : "Starter kit");
  setText(entryFeeState, "$0");
  setText(raidAccessState, snapshot.raidActive ? "In raid" : "Ready");
  setText(bestRunMeta, `$${formatNumber(snapshot.bestRunValue)}`);
  setText(survivalMeta, `${survivalRate}%`);
  setText(targetProgress, `${Math.min(5, sellableStash.length)} / 5`);
  setText(extractProgress, `${Math.min(3, extracts)} / 3`);
  setText(recommendedAction, hasWeapon && hasAmmo ? `Deploy or sell ${formatNumber(sellableStash.length)} loot stacks` : "Check loadout before deploy");
  setText(deployHint, snapshot.raidActive ? "You already have an active raid." : hasWeapon && hasAmmo ? "Kit verified. Enter the live Los Santos open zone." : "Starter kit available. Consider checking loadout first.");
  setText(medicalQuestText, medicalCount > 0 ? `Medical supplies secured: ${formatNumber(medicalCount)} / 1.` : "Extract with any medical supplies. Progress is inferred from stash for now.");
  setText(intelQuestText, intelCount > 0 ? `Intel secured: ${formatNumber(intelCount)} / 1.` : "Secure Intel from guarded crates to unlock future faction contacts.");

  setProgress(medicalQuestBar, medicalCount > 0 ? 100 : 0);
  setProgress(intelQuestBar, intelCount > 0 ? 100 : 0);

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
  renderList(stashPreview, sellableStash, "No secured sellable loot yet");
  renderList(loadoutPreview, loadout, "No loadout items in stash");
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
        { label: "Military Circuit", count: 2, value: 900, weight: 90, type: "loot" },
        { label: "Medical Supplies", count: 4, value: 350, weight: 70, type: "loot" },
        { label: "Pistol", count: 1, value: 0, weight: 650, type: "weapon" },
        { label: "9mm Ammo", count: 48, value: 0, weight: 8, type: "ammo" },
      ],
    },
  });
}
